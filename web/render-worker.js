// Owns the OpenSCAD wasm build. Renders happen here so a slider drag never blocks the page.
import { createOpenSCAD } from "./vendor/openscad.js";

let source = null;

async function scadSource() {
  if (source === null) {
    const url = new URL("./gridfinity.scad", self.location.href);
    const r = await fetch(url);
    if (!r.ok) throw new Error(`could not load gridfinity.scad (HTTP ${r.status})`);
    source = await r.text();
  }
  return source;
}

// -D takes OpenSCAD syntax, so strings need their quotes and booleans their bare words
function defines(params) {
  return Object.entries(params).flatMap(([k, v]) => [
    "-D",
    `${k}=${typeof v === "string" ? JSON.stringify(v) : v}`,
  ]);
}

async function render(params) {
  const src = await scadSource();
  const log = [];
  // callMain runs once per instance, so every render gets a fresh one — about 20 ms
  const oc = await createOpenSCAD({
    noInitialRun: true,
    print: (t) => log.push(t),
    printErr: (t) => log.push(t),
  });
  const inst = oc.getInstance();
  inst.FS.writeFile("/model.scad", src);

  const started = performance.now();
  const rc = inst.callMain([
    "/model.scad",
    "--backend=manifold",
    "--export-format", "binstl",
    ...defines(params),
    "-o", "/out.stl",
  ]);
  const ms = performance.now() - started;

  if (rc !== 0) throw new Error(log.join("\n") || `OpenSCAD exited with ${rc}`);
  // slice so the bytes outlive the wasm heap and can be transferred
  const stl = inst.FS.readFile("/out.stl").slice();
  return { stl, ms, log };
}

// A preview is worth only its latest request, so a drag collapses to one render. A download
// was asked for explicitly and always runs.
let preview = null;
const downloads = [];
let running = false;

function nextJob() {
  if (downloads.length) return downloads.shift();
  const job = preview;
  preview = null;
  return job;
}

async function pump() {
  if (running) return;
  running = true;
  while (downloads.length || preview) {
    const job = nextJob();
    try {
      const { stl, ms, log } = await render(job.params);
      self.postMessage({ id: job.id, kind: job.kind, ok: true, stl, ms, log }, [stl.buffer]);
    } catch (e) {
      self.postMessage({ id: job.id, kind: job.kind, ok: false, error: String(e?.message ?? e) });
    }
  }
  running = false;
}

self.onmessage = ({ data }) => {
  if (data.kind === "download") downloads.push(data);
  else preview = data;
  pump();
};
