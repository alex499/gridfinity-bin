// The configuration as it travels in the URL fragment. No DOM here, so both halves can be
// tested in node; app.js owns everything that touches a control.
//
// Every parameter is written out, not only the ones that differ from a default. Omitting
// defaults would make short links, but the meaning of an old link would then shift whenever
// a default changed. A link points at a bin somebody is going to print.

// A schema is { name: entry }, where entry is one of
//   { kind: "int" | "float", min, max, fallback }
//   { kind: "bool", fallback }
//   { kind: "choice", values: [...], fallback }

export function serialise(params) {
  return Object.entries(params)
    .map(([k, v]) => `${k}=${encodeURIComponent(v === true ? 1 : v === false ? 0 : v)}`)
    .join("&");
}

// Never throws. A fragment written against an older version of the model has to degrade,
// not break the page: unknown keys go, numbers are clamped, anything unreadable falls back.
export function parse(text, schema) {
  const given = new Map();
  for (const pair of String(text ?? "").replace(/^#/, "").split("&")) {
    if (!pair) continue;
    const at = pair.indexOf("=");
    if (at < 1) continue;
    try {
      given.set(decodeURIComponent(pair.slice(0, at)), decodeURIComponent(pair.slice(at + 1)));
    } catch {
      // a stray % that is not an escape — skip this pair and keep the rest
    }
  }

  const params = {};
  for (const [name, entry] of Object.entries(schema)) {
    params[name] = given.has(name) ? coerce(given.get(name), entry) : entry.fallback;
  }
  return params;
}

function coerce(raw, entry) {
  if (entry.kind === "bool") {
    return raw === "1" || raw === "true";
  }
  if (entry.kind === "choice") {
    return entry.values.includes(raw) ? raw : entry.fallback;
  }
  const n = entry.kind === "int" ? parseInt(raw, 10) : parseFloat(raw);
  if (!Number.isFinite(n)) return entry.fallback;
  return Math.min(entry.max, Math.max(entry.min, n));
}
