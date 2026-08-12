// Checks that the page renders the same solid the openscad CLI does, by driving the real
// render-worker.js from node with self/fetch stubbed. Run `node build.js` first.
//
//   node verify.js          parity on a spread of configs, then a sweep for errors
//   node verify.js sweep    the sweep only
import { execFile } from "node:child_process";
import { readFile, writeFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { serialise, parse } from "./config.js";

const run = promisify(execFile);
const web = dirname(fileURLToPath(import.meta.url));
const site = join(web, "_site");

/* the worker expects a browser: a self to post to, and a fetch for the .scad */

const replies = new Map();
globalThis.self = {
  location: { href: `file://${site}/` },
  postMessage: (msg) => replies.get(msg.id)?.(msg),
};
globalThis.fetch = async (url) => {
  const path = join(site, String(url).replace(/^file:\/\//, "").slice(site.length));
  return { ok: true, status: 200, text: () => readFile(path, "utf8") };
};

await import(join(site, "render-worker.js"));

let nextId = 0;
function render(params, kind = "download") {
  const id = ++nextId;
  return new Promise((resolve) => {
    replies.set(id, (msg) => { replies.delete(id); resolve(msg); });
    self.onmessage({ data: { id, kind, params } });
  });
}

/* measuring the result */

// the page asks for binstl; the CLI writes ascii unless told otherwise, so read either
function triangles(bytes) {
  const head = Buffer.from(bytes.buffer, bytes.byteOffset, Math.min(512, bytes.byteLength));
  return head.toString("latin1").startsWith("solid") && head.includes("facet")
    ? asciiTriangles(Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("latin1"))
    : binaryTriangles(bytes);
}

function binaryTriangles(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const n = view.getUint32(80, true);
  const out = [];
  for (let i = 0; i < n; i++) {
    const o = 84 + i * 50 + 12;
    const v = [];
    for (let k = 0; k < 9; k++) v.push(view.getFloat32(o + k * 4, true));
    out.push([v.slice(0, 3), v.slice(3, 6), v.slice(6, 9)]);
  }
  return out;
}

function asciiTriangles(text) {
  const out = [];
  let tri = [];
  for (const m of text.matchAll(/^\s*vertex\s+(\S+)\s+(\S+)\s+(\S+)/gm)) {
    tri.push([Number(m[1]), Number(m[2]), Number(m[3])]);
    if (tri.length === 3) { out.push(tri); tri = []; }
  }
  return out;
}

function measure(bytes) {
  const tris = triangles(bytes);
  let volume = 0;
  const min = [Infinity, Infinity, Infinity];
  const max = [-Infinity, -Infinity, -Infinity];
  for (const [a, b, c] of tris) {
    volume += (a[0] * (b[1] * c[2] - b[2] * c[1])
             - a[1] * (b[0] * c[2] - b[2] * c[0])
             + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6;
    for (const v of [a, b, c]) for (let i = 0; i < 3; i++) {
      if (v[i] < min[i]) min[i] = v[i];
      if (v[i] > max[i]) max[i] = v[i];
    }
  }
  return { tris: tris.length, volume, size: max.map((m, i) => m - min[i]) };
}

const flags = (p) => Object.entries(p).flatMap(([k, v]) =>
  ["-D", `${k}=${typeof v === "string" ? JSON.stringify(v) : v}`]);

async function cli(params, dir) {
  const out = join(dir, "cli.stl");
  await run("openscad", ["-o", out, ...flags(params), join(web, "..", "gridfinity.scad")]);
  return measure(new Uint8Array(await readFile(out)));
}

/* the two checks */

const base = { units_x: 2, units_y: 2, units_z: 3, cells: 1, split_lid: false,
               closure: "auto", cover: true, scoop: true, part: "bin" };

const parityCases = [
  ["1x1x3 plain",            { units_x: 1, units_y: 1, units_z: 3 }],
  ["2x2x3 cells=4 split",    { cells: 4, split_lid: true }],
  ["2x2x3 cells=3",          { cells: 3 }],
  ["5x5x6 cells=2",          { units_x: 5, units_y: 5, units_z: 6, cells: 2 }],
  ["1x1x3 card",             { units_x: 1, units_y: 1, units_z: 3, part: "card" }],
  ["2x2x3 lid cells=4 split",{ cells: 4, split_lid: true, part: "lid" }],
  ["2x2x2 no cover",         { units_z: 2, cover: false }],
  ["3x1x4 thick walls",      { units_x: 3, units_y: 1, units_z: 4, wall_thickness: 1.6,
                               floor_thickness: 2, solid_foot: true, scoop: false }],
];

async function parity() {
  const dir = await mkdtemp(join(tmpdir(), "gfv-"));
  let bad = 0;
  console.log("geometry parity — wasm (as the page runs it) vs the openscad CLI\n");
  for (const [name, over] of parityCases) {
    const params = { ...base, ...over };
    const msg = await render(params);
    if (!msg.ok) { console.log(`FAIL ${name}: ${msg.error}`); bad++; continue; }
    const w = measure(msg.stl);
    const c = await cli(params, dir);
    // both files store float32, so compare relatively: 1e-5 is far below any real
    // difference in the solid and far above the rounding in the coordinates
    const dv = Math.abs(w.volume - c.volume) / c.volume;
    const ds = Math.max(...w.size.map((s, i) => Math.abs(s - c.size[i])));
    const ok = dv < 1e-5 && ds < 1e-3;
    if (!ok) bad++;
    console.log(
      `${ok ? "ok  " : "FAIL"} ${name.padEnd(26)} ` +
      `vol ${w.volume.toFixed(3).padStart(11)} vs ${c.volume.toFixed(3).padStart(11)} ` +
      `(Δ ${dv.toExponential(1)} rel)  size ${w.size.map((s) => s.toFixed(2)).join(" × ")}`
    );
  }
  await rm(dir, { recursive: true, force: true });
  return bad;
}

async function sweep() {
  console.log("\nsweep — every cells × split_lid × closure × part, expecting a clean render\n");
  let n = 0, bad = 0;
  for (const cells of [1, 2, 3, 4])
    for (const split_lid of [false, true])
      for (const closure of ["auto", "card", "lid"])
        for (const part of ["bin", "card", "lid", "assembled"]) {
          const params = { ...base, cells, split_lid, closure, part };
          const msg = await render(params);
          n++;
          const noise = (msg.log ?? []).filter((l) => /WARNING|ERROR/.test(l));
          if (!msg.ok || noise.length) {
            bad++;
            console.log(`FAIL cells=${cells} split=${split_lid} closure=${closure} part=${part}` +
                        `\n     ${msg.error ?? noise.join("\n     ")}`);
          }
        }
  console.log(`${bad ? `${bad} of ${n} failed` : `all ${n} combinations rendered clean`}`);
  return bad;
}

/* the URL fragment: it must round trip, and it must never throw */

// stands in for what schema() reads off the controls in index.html
const testSchema = {
  units_x:        { kind: "int",    min: 1,   max: 10, fallback: 1 },
  units_y:        { kind: "int",    min: 1,   max: 10, fallback: 1 },
  units_z:        { kind: "int",    min: 1,   max: 10, fallback: 3 },
  wall_thickness: { kind: "float",  min: 0.4, max: 5,  fallback: 1 },
  card_length:    { kind: "float",  min: 5,   max: 40, fallback: 15 },
  cover:          { kind: "bool",   fallback: true },
  split_lid:      { kind: "bool",   fallback: false },
  scoop:          { kind: "bool",   fallback: true },
  closure:        { kind: "choice", values: ["auto", "card", "lid"], fallback: "auto" },
  cells:          { kind: "int",    min: 1,   max: 4,  fallback: 1 },
  view:           { kind: "choice", values: ["bin", "plate", "assembled"], fallback: "bin" },
};

const full = (over) => ({
  units_x: 1, units_y: 1, units_z: 3, wall_thickness: 1, card_length: 15,
  cover: true, split_lid: false, scoop: true, closure: "auto", cells: 1, view: "bin", ...over,
});

function config() {
  console.log("\nURL fragment — round trip, then degradation\n");
  let bad = 0;

  const trips = [
    ["defaults",       full()],
    ["a big split bin",full({ units_x: 7, units_y: 4, units_z: 9, cells: 4, split_lid: true,
                              closure: "lid", view: "assembled" })],
    ["fractions",      full({ wall_thickness: 1.6, card_length: 22.35, scoop: false })],
    ["no cover",       full({ cover: false, closure: "card", view: "plate" })],
  ];
  for (const [name, params] of trips) {
    const back = parse(serialise(params), testSchema);
    const same = Object.keys(params).every((k) => back[k] === params[k])
              && Object.keys(back).length === Object.keys(params).length;
    if (!same) {
      bad++;
      console.log(`FAIL round trip ${name}\n     out ${serialise(params)}\n     back ${serialise(back)}`);
    } else {
      console.log(`ok   round trip ${name.padEnd(18)} ${serialise(params).length} chars`);
    }
  }

  // a fragment written against an older model, or by hand, or by a mangled paste
  const junk = [
    ["renamed key dropped",   "rows=2&units_x=3",        (p) => p.units_x === 3 && !("rows" in p)],
    ["above range clamped",   "units_x=99",              (p) => p.units_x === 10],
    ["below range clamped",   "units_z=-5",              (p) => p.units_z === 1],
    ["float clamped",         "card_length=0.001",       (p) => p.card_length === 5],
    ["bad choice falls back", "closure=banana",          (p) => p.closure === "auto"],
    ["not a number",          "units_y=abc",             (p) => p.units_y === 1],
    ["empty fragment",        "",                        (p) => p.units_x === 1 && p.view === "bin"],
    ["broken escape",         "%%%&units_x=2",           (p) => p.units_x === 2],
    ["no equals sign",        "units_x&cells=3",         (p) => p.cells === 3 && p.units_x === 1],
    ["leading hash",          "#cells=4",                (p) => p.cells === 4],
    ["undefined",             undefined,                 (p) => p.units_z === 3],
  ];
  for (const [name, text, ok] of junk) {
    let result;
    try {
      result = parse(text, testSchema);
    } catch (e) {
      bad++;
      console.log(`FAIL ${name}: threw ${e.message}`);
      continue;
    }
    const passed = ok(result) && Object.keys(result).length === Object.keys(testSchema).length;
    if (!passed) bad++;
    console.log(`${passed ? "ok  " : "FAIL"} degrades: ${name}`);
  }

  console.log(bad ? `${bad} fragment check(s) failed` : "fragment round trips and never throws");
  return bad;
}

const only = process.argv[2];
let bad = config();
if (only !== "sweep") bad += await parity();
bad += await sweep();
process.exit(bad ? 1 : 0);
