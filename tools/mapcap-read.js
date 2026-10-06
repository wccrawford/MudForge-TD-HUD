// Read the mapcap log (tools/mapcap.lua) out of desktop MudForge.
//
// saveTable does not reach plugin_tables.db: MudForge keeps each plugin's
// state as a virtual file, worlds/<World>/plugins/<uuid>.state.json, in the
// WebView2 IndexedDB, and a large value lands in a blob file as a
// snappy-compressed V8 value. This takes the newest blob holding a mapcap log,
// unsnappies it and writes the log as JSON.
//
//   node tools/mapcap-read.js OUT.json [blob-file]
const fs = require("fs");
const path = require("path");

const BLOBS = path.join(process.env.LOCALAPPDATA || "", "com.mudforge.app", "EBWebView",
  "Default", "IndexedDB", "http_tauri.localhost_0.indexeddb.blob");

function varint(b, i) {
  let r = 0, s = 0, c;
  do { c = b[i++]; r += (c & 0x7f) * 2 ** s; s += 7; } while (c >= 0x80);
  return [r, i];
}

// Raw snappy (no framing).
function unsnappy(b, i) {
  let n; [n, i] = varint(b, i);
  const out = Buffer.alloc(n);
  let o = 0;
  while (o < n) {
    const t = b[i++], k = t & 3;
    if (k === 0) {
      let len = t >> 2;
      if (len >= 60) { const nb = len - 59; len = b.readUIntLE(i, nb); i += nb; }
      len += 1;
      b.copy(out, o, i, i + len); i += len; o += len;
      continue;
    }
    let len, off;
    if (k === 1) { len = ((t >> 2) & 7) + 4; off = ((t >> 5) << 8) | b[i++]; }
    else if (k === 2) { len = (t >> 2) + 1; off = b.readUInt16LE(i); i += 2; }
    else { len = (t >> 2) + 1; off = b.readUInt32LE(i); i += 4; }
    for (let j = 0; j < len; j++, o++) out[o] = out[o - off];
  }
  return out;
}

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(d =>
    d.isDirectory() ? walk(path.join(dir, d.name)) : [path.join(dir, d.name)]);
}

function readLog(file) {
  const b = fs.readFileSync(file);
  for (let start = 0; start < 8; start++) {
    let out;
    try { out = unsnappy(b, start); } catch { continue; }
    const s = out.toString("latin1");
    const at = s.indexOf("content");
    const brace = at < 0 ? -1 : s.indexOf("{", at);
    if (brace < 0 || s.indexOf('"log"') < 0) continue;
    // the JSON text ends where its braces balance (strings respected)
    let depth = 0, inStr = false, end = -1;
    for (let j = brace; j < s.length; j++) {
      const c = s[j];
      if (inStr) { if (c === "\\") j++; else if (c === '"') inStr = false; }
      else if (c === '"') inStr = true;
      else if (c === "{") depth++;
      else if (c === "}" && --depth === 0) { end = j + 1; break; }
    }
    if (end < 0) continue;
    const state = JSON.parse(Buffer.from(s.slice(brace, end), "latin1").toString("utf8"));
    const log = state.tables && state.tables.log;
    if (!log) continue;
    const e = log.entries || {};
    const entries = Array.isArray(e) ? e : Object.keys(e).sort((a, b) => a - b).map(k => e[k]);
    return { seq: log.seq, entries };
  }
  return null;
}

const [outFile, blob] = process.argv.slice(2);
if (!outFile) { console.error("usage: node tools/mapcap-read.js OUT.json [blob-file]"); process.exit(2); }
const candidates = blob ? [blob] : walk(BLOBS)
  .map(f => ({ f, m: fs.statSync(f).mtimeMs })).sort((a, b) => b.m - a.m).map(x => x.f);
for (const f of candidates) {
  const log = readLog(f);
  if (log) {
    fs.writeFileSync(outFile, JSON.stringify(log, null, 1));
    console.log(`${f}\n-> ${outFile}: ${log.entries.length} entries, last #${log.seq}`);
    process.exit(0);
  }
}
console.error("no mapcap log found in " + (blob || BLOBS));
process.exit(1);
