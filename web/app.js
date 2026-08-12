import * as THREE from "three";
import { OrbitControls } from "./vendor/OrbitControls.js";
import { STLLoader } from "./vendor/STLLoader.js";
import { serialise, parse } from "./config.js";

// Gridfinity's own numbers, only ever used to print the size next to the sliders
const GRID_UNIT = 42, UNIT_HEIGHT = 7, CLEARANCE = 0.5, LIP_HEIGHT = 4.4;

/* ---------------------------------------------------------------- parameters */

// Everything the model is asked for. Ranges here must match the // [..] annotations
// in gridfinity.scad; the ids in index.html are the OpenSCAD variable names.
function readParams() {
  const params = {};
  for (const el of document.querySelectorAll("[data-param]")) {
    const kind = el.dataset.param;
    params[el.id] =
      kind === "bool" ? el.checked :
      kind === "int" ? parseInt(el.value, 10) :
      kind === "float" ? parseFloat(el.value) :
      el.value;
  }
  params.cells = Number(document.querySelector('input[name="cells"]:checked').value);
  return params;
}

// The only rule that lives in two places: lidded() in gridfinity.scad decides the same
// thing. Keep them in step, or the plate button will offer the wrong piece.
function resolvedClosure({ closure, cells }) {
  return closure === "auto" ? (cells > 1 ? "lid" : "card") : closure;
}

function currentView() {
  return document.querySelector('input[name="view"]:checked').value;
}

// the two radio groups, which carry their choices the way [data-param] carries its ranges
const RADIOS = ["cells", "view"];

function radios(name) {
  return [...document.querySelectorAll(`input[name="${name}"]`)];
}

// The view toggle speaks of a "plate"; the model wants to know which one.
function partFor(view, params) {
  return view === "plate" ? resolvedClosure(params) : view;
}

/* ------------------------------------------------- the link in the address bar */

// Read off the controls themselves, so index.html stays the only place the parameters,
// their ranges and their choices are written down.
function schema() {
  const s = {};
  for (const el of document.querySelectorAll("[data-param]")) {
    const kind = el.dataset.param;
    if (kind === "bool") {
      s[el.id] = { kind, fallback: el.defaultChecked };
    } else if (kind === "string") {
      const options = [...el.options];
      s[el.id] = {
        kind: "choice",
        values: options.map((o) => o.value),
        fallback: (options.find((o) => o.defaultSelected) ?? options[0]).value,
      };
    } else {
      s[el.id] = { kind, min: Number(el.min), max: Number(el.max), fallback: Number(el.defaultValue) };
    }
  }
  for (const name of RADIOS) {
    const group = radios(name);
    const values = group.map((r) => r.value);
    const fallback = (group.find((r) => r.defaultChecked) ?? group[0]).value;
    s[name] = name === "cells"
      ? { kind: "int", min: Math.min(...values.map(Number)), max: Math.max(...values.map(Number)),
          fallback: Number(fallback) }
      : { kind: "choice", values, fallback };
  }
  return s;
}

// what goes in the fragment: the model's parameters plus which of them you are looking at
function linkParams() {
  return { ...readParams(), view: currentView() };
}

// the inverse of readParams
function applyParams(params) {
  for (const el of document.querySelectorAll("[data-param]")) {
    if (!(el.id in params)) continue;
    if (el.dataset.param === "bool") el.checked = params[el.id];
    else el.value = params[el.id];
  }
  for (const name of RADIOS) {
    const radio = radios(name).find((r) => r.value === String(params[name]));
    if (radio) radio.checked = true;
  }
}

// replaceState, not pushState: a slider drag must not fill the back button
function rememberInUrl() {
  history.replaceState(null, "", "#" + serialise(linkParams()));
}

function fileName(params, part) {
  const { units_x, units_y, units_z, cells, split_lid } = params;
  const bits = [`gridfinity-${units_x}x${units_y}x${units_z}`];
  if (cells > 1) bits.push(`cells${cells}`);
  if (split_lid && resolvedClosure(params) === "lid" && part !== "bin") bits.push("split");
  bits.push(part);
  return bits.join("-") + ".stl";
}

/* ------------------------------------------------------------------- the scene */

const viewer = document.getElementById("viewer");
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(35, 1, 1, 4000);
camera.up.set(0, 0, 1);
camera.position.set(160, -190, 130);

// transparent, so the stage keeps its CSS background and follows the light/dark theme
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setClearAlpha(0);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
viewer.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.12;

scene.add(new THREE.HemisphereLight(0xffffff, 0x707078, 2.1));
const key = new THREE.DirectionalLight(0xffffff, 2.0);
key.position.set(0.6, -1, 1.3);
scene.add(key);
const fill = new THREE.DirectionalLight(0xffffff, 0.7);
fill.position.set(-0.9, 0.5, 0.4);
scene.add(fill);

const material = new THREE.MeshStandardMaterial({
  color: 0xf4a259, roughness: 0.62, metalness: 0.04, flatShading: false,
});

let mesh = null;
let grid = null;
let framedRadius = 0;

function resize() {
  const { clientWidth: w, clientHeight: h } = viewer;
  if (!w || !h) return;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
new ResizeObserver(resize).observe(viewer);
resize();

(function loop() {
  requestAnimationFrame(loop);
  controls.update();
  renderer.render(scene, camera);
})();

function showGeometry(geometry) {
  geometry.computeBoundingBox();
  const box = geometry.boundingBox;
  const centre = box.getCenter(new THREE.Vector3());
  // centre it in X and Y, and stand it on z = 0 so the grid reads as the table
  geometry.translate(-centre.x, -centre.y, -box.min.z);
  geometry.computeVertexNormals();
  geometry.computeBoundingSphere();

  if (mesh) {
    scene.remove(mesh);
    mesh.geometry.dispose();
  }
  mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  const size = box.getSize(new THREE.Vector3());
  layGrid(Math.max(size.x, size.y));

  // keep the angle the user orbited to; only re-fit when the model changed size
  const radius = geometry.boundingSphere.radius;
  if (Math.abs(radius - framedRadius) > 0.15 * framedRadius) {
    const target = new THREE.Vector3(0, 0, size.z / 2);
    const direction = camera.position.clone().sub(controls.target).normalize();
    const distance = radius / Math.sin(THREE.MathUtils.degToRad(camera.fov / 2)) * 1.2;
    controls.target.copy(target);
    camera.position.copy(target).addScaledVector(direction, distance);
    framedRadius = radius;
  }
}

// one square per grid unit, so the footprint is readable at a glance
const dark = matchMedia("(prefers-color-scheme: dark)");
let gridSpan = 0;

function layGrid(span) {
  gridSpan = span;
  const units = Math.max(2, Math.ceil(span / GRID_UNIT) + 2);
  if (grid) {
    if (grid.userData.units === units && grid.userData.dark === dark.matches) return;
    scene.remove(grid);
    grid.dispose();
  }
  const [line, minor] = dark.matches ? [0x44444e, 0x303038] : [0xc8c8cc, 0xe2e2e6];
  grid = new THREE.GridHelper(units * GRID_UNIT, units, line, minor);
  grid.rotation.x = Math.PI / 2;
  grid.position.z = -0.05;
  grid.userData.units = units;
  grid.userData.dark = dark.matches;
  scene.add(grid);
}

dark.addEventListener("change", () => { if (grid) layGrid(gridSpan); });

/* ------------------------------------------------------------------ the worker */

const worker = new Worker(new URL("./render-worker.js", import.meta.url), { type: "module" });
const loader = new STLLoader();

const statusText = document.getElementById("status-text");
const status = document.getElementById("status");
let sequence = 0;
let latestPreview = 0;
const pendingDownloads = new Map();

function setStatus(text, state = "busy") {
  statusText.textContent = text;
  status.dataset.state = state;
}

worker.onmessage = ({ data }) => {
  if (data.kind === "download") {
    const job = pendingDownloads.get(data.id);
    pendingDownloads.delete(data.id);
    for (const b of document.querySelectorAll("#downloads button")) b.disabled = false;
    if (!data.ok) return setStatus(data.error, "error");
    saveFile(data.stl, job.name);
    setStatus(`Saved ${job.name}`, "idle");
    return;
  }

  if (data.id !== latestPreview) return;   // a newer preview has already been asked for
  if (!data.ok) return setStatus(data.error, "error");

  showGeometry(loader.parse(data.stl.buffer));
  setStatus(`Rendered in ${(data.ms / 1000).toFixed(2)} s`, "idle");
  for (const b of document.querySelectorAll("#downloads button")) b.disabled = false;
};

worker.onerror = (e) => setStatus(`Worker failed: ${e.message}`, "error");

function saveFile(bytes, name) {
  const url = URL.createObjectURL(new Blob([bytes], { type: "model/stl" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}

function requestPreview() {
  const params = readParams();
  const id = ++sequence;
  latestPreview = id;
  setStatus("Rendering…");
  worker.postMessage({ id, kind: "preview", params: { ...params, part: partFor(currentView(), params) } });
}

function requestDownload(part) {
  const params = readParams();
  const id = ++sequence;
  const name = fileName(params, part);
  pendingDownloads.set(id, { name });
  for (const b of document.querySelectorAll("#downloads button")) b.disabled = true;
  setStatus(`Rendering ${name}…`);
  worker.postMessage({ id, kind: "download", params: { ...params, part } });
}

/* --------------------------------------------------------------------- the UI */

const dlPlate = document.getElementById("dl-plate");
const splitLid = document.getElementById("split_lid");
const closureResolved = document.getElementById("closure-resolved");
const sizeNote = document.getElementById("size-note");

function syncUI() {
  const params = readParams();
  const plate = resolvedClosure(params);
  const covered = params.cover;

  for (const el of document.querySelectorAll("output[for]")) {
    const input = document.getElementById(el.htmlFor);
    el.textContent = input.step === "1" ? input.value : Number(input.value).toFixed(input.step === "0.05" ? 2 : 1);
  }

  const w = params.units_x * GRID_UNIT - CLEARANCE;
  const d = params.units_y * GRID_UNIT - CLEARANCE;
  const h = params.units_z * UNIT_HEIGHT + LIP_HEIGHT;
  sizeNote.textContent = `${w} × ${d} × ${h} mm`;

  closureResolved.textContent = covered && params.closure === "auto" ? `→ ${plate}` : "";
  document.getElementById("closure").disabled = !covered;
  splitLid.disabled = !covered || plate !== "lid" || params.cells < 2;
  if (splitLid.disabled) splitLid.checked = false;

  for (const el of document.querySelectorAll("[data-needs-cover]")) el.hidden = !covered;
  if (!covered && currentView() !== "bin") {
    document.querySelector('input[name="view"][value="bin"]').checked = true;
  }

  dlPlate.textContent = plate === "lid" ? "Lid .stl" : "Card .stl";
  dlPlate.disabled = !covered;
}

let debounce = 0;
function onChange() {
  syncUI();
  clearTimeout(debounce);
  // the address is rewritten once the change settles, not once per slider tick
  debounce = setTimeout(() => { rememberInUrl(); requestPreview(); }, 150);
}

document.getElementById("panel").addEventListener("input", onChange);
document.getElementById("view-toggle").addEventListener("change", onChange);
document.getElementById("dl-bin").addEventListener("click", () => requestDownload("bin"));
dlPlate.addEventListener("click", () => requestDownload(resolvedClosure(readParams())));

// someone pasting a different link into the address bar; replaceState does not fire this
addEventListener("hashchange", () => {
  const incoming = location.hash.replace(/^#/, "");
  if (incoming === serialise(linkParams())) return;
  applyParams(parse(incoming, schema()));
  onChange();
});

if (location.hash.length > 1) applyParams(parse(location.hash, schema()));
syncUI();
rememberInUrl();   // normalise the address, filling in whatever the link left out
setStatus("Loading OpenSCAD…");
requestPreview();
