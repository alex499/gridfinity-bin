// Assembles _site/ from the page sources, the npm dependencies and the model itself.
// Nothing here is committed; CI runs this and uploads the result to GitHub Pages.
import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const web = dirname(fileURLToPath(import.meta.url));
const site = join(web, "_site");
const mods = join(web, "node_modules");

const page = ["index.html", "app.js", "config.js", "render-worker.js", "style.css"];

// three's examples import the bare specifier "three"; the import map in index.html
// points that at three.module.min.js, which in turn pulls in three.core.min.js
const vendor = [
  ["three/build/three.module.min.js", "three.module.min.js"],
  ["three/build/three.core.min.js", "three.core.min.js"],
  ["three/examples/jsm/controls/OrbitControls.js", "OrbitControls.js"],
  ["three/examples/jsm/loaders/STLLoader.js", "STLLoader.js"],
  ["openscad-wasm/openscad.js", "openscad.js"],
];

await rm(site, { recursive: true, force: true });
await mkdir(join(site, "vendor"), { recursive: true });

for (const f of page) await cp(join(web, f), join(site, f));
for (const [from, to] of vendor) await cp(join(mods, from), join(site, "vendor", to));

// the one source of truth, served as plain text and fetched by the worker
await cp(join(web, "..", "gridfinity.scad"), join(site, "gridfinity.scad"));

console.log(`built ${site}`);
