// Local preview of the built site. No dependencies; GitHub Pages does this part for real.
import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { dirname, extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const site = join(dirname(fileURLToPath(import.meta.url)), "_site");
const port = Number(process.env.PORT) || 8080;

const types = {
  ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".scad": "text/plain", ".wasm": "application/wasm", ".json": "application/json",
};

createServer(async (req, res) => {
  const path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  const file = join(site, normalize(path).replace(/^(\.\.[/\\])+/, ""));
  const target = file.endsWith("/") ? join(file, "index.html") : file;
  try {
    const info = await stat(target);
    const name = info.isDirectory() ? join(target, "index.html") : target;
    res.writeHead(200, { "content-type": types[extname(name)] ?? "application/octet-stream" });
    createReadStream(name).pipe(res);
  } catch {
    res.writeHead(404, { "content-type": "text/plain" }).end("not found");
  }
}).listen(port, () => console.log(`http://localhost:${port}`));
