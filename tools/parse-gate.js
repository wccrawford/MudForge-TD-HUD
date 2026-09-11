// node tools/parse-gate.js <file.lua>...   -> exit 1 if any file fails to parse
// luaparse is the parser MudForge itself loads plugins with; luaVersion '5.1'
// rejects at build time exactly what MudForge would reject at import time
// (goto, //, bitwise ops, mid-block break). Globs are expanded here because
// npm scripts run under cmd.exe on Windows, which does not expand them.
const fs = require("fs");
const path = require("path");
const luaparse = require("luaparse");

function expand(arg) {
  const dir = path.dirname(arg);
  const base = path.basename(arg);
  if (!base.includes("*")) return [arg];
  const [prefix, suffix] = base.split("*");   // one `*` per pattern is all we need
  return fs.readdirSync(dir).filter(f => f.startsWith(prefix) && f.endsWith(suffix) && f.length >= prefix.length + suffix.length).sort().map(f => path.join(dir, f));
}

const files = process.argv.slice(2).flatMap(expand);
if (files.length === 0) { console.error("parse-gate: no files"); process.exit(1); }
let bad = 0;
for (const f of files) {
  try {
    luaparse.parse(fs.readFileSync(f, "utf8"), { luaVersion: "5.1" });
    console.log("ok   " + f);
  } catch (e) {
    bad++;
    console.error("FAIL " + f + " - " + e.message);
  }
}
process.exit(bad ? 1 : 0);
