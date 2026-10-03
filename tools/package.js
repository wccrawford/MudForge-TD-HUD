// node tools/package.js [--url <https url>]
//
// Wraps the built single-file plugin (textdungeon-hud.lua, ADR 0001) in a
// MudForge server package (ADR 0003) and writes, under dist/:
//
//   textdungeon-hud-<version>.mfp   the bundle: package.json,
//                                   plugins/manifest.json, plugins/<id>.lua
//   client-package.json             the GMCP Client.Package advertisement
//                                   for the server to send, sha256 included
//
// The version is the plugin block's, so the advertised version, the
// manifest's and the plugin's can never disagree (a mismatch re-prompts the
// player on every login). The bundle is byte-for-byte reproducible: fixed
// entry order and timestamps, so the same source gives the same sha256.
//
//   --url   where the .mfp will be served (HTTPS). Default: this repo's
//           GitHub Release asset for the version, tag v<version>.
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const crypto = require("crypto");

const ROOT = path.join(__dirname, "..");
const DIST = path.join(ROOT, "dist");
const REPO = "https://github.com/wccrawford/MudForge-TD-HUD";

// Stable forever: changing it orphans every existing install (MudForge
// recognises an update by it).
const PACKAGE_ID = "com.wccrawford.textdungeon-hud";
const PACKAGE_NAME = "TextDungeon HUD";
// The client the package was verified in; older ones refuse it up front.
const MIN_CLIENT = "1.2.2490";

const read = rel => fs.readFileSync(path.join(ROOT, rel), "utf8").replace(/\r\n/g, "\n");

// The plugin's own metadata, from the built file's `plugin = { ... }` block.
function pluginMeta(lua) {
  const block = /^plugin\s*=\s*\{([\s\S]*?)^\}/m.exec(lua);
  if (!block) throw new Error("textdungeon-hud.lua: no `plugin = { ... }` block - run `npm run build`");
  const field = name => {
    const m = new RegExp("^\\s*" + name + '\\s*=\\s*"([^"]*)"', "m").exec(block[1]);
    if (!m) throw new Error("plugin block has no " + name);
    return m[1];
  };
  return { id: field("id"), name: field("name"), version: field("version"), author: field("author"), description: field("description") };
}

// A minimal ZIP writer (deflate, no extras), enough for MudForge's reader.
// Every entry carries the same DOS timestamp, 1980-01-01 00:00, so the
// bytes depend only on the contents.
function zip(entries) {
  const DOS_TIME = 0, DOS_DATE = (0 << 9) | (1 << 5) | 1;
  const locals = [], centrals = [];
  let offset = 0;
  for (const [name, text] of entries) {
    const nameBuf = Buffer.from(name, "utf8");
    const data = Buffer.from(text, "utf8");
    const packed = zlib.deflateRawSync(data, { level: 9 });
    const crc = zlib.crc32(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);           // version needed
    local.writeUInt16LE(0x0800, 6);       // flags: names are UTF-8
    local.writeUInt16LE(8, 8);            // deflate
    local.writeUInt16LE(DOS_TIME, 10);
    local.writeUInt16LE(DOS_DATE, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(packed.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBuf.length, 26);
    local.writeUInt16LE(0, 28);
    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);         // version made by
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x0800, 8);
    central.writeUInt16LE(8, 10);
    central.writeUInt16LE(DOS_TIME, 12);
    central.writeUInt16LE(DOS_DATE, 14);
    central.writeUInt32LE(crc, 16);
    central.writeUInt32LE(packed.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(nameBuf.length, 28);
    central.writeUInt32LE(offset, 42);    // 30..41: extra, comment, disk, attrs all 0
    locals.push(local, nameBuf, packed);
    centrals.push(central, nameBuf);
    offset += local.length + nameBuf.length + packed.length;
  }
  const dir = Buffer.concat(centrals);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8);
  end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(dir.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...locals, dir, end]);
}

const args = process.argv.slice(2);
const lua = read("textdungeon-hud.lua");
const meta = pluginMeta(lua);
const npmVersion = JSON.parse(read("package.json")).version;
if (npmVersion !== meta.version) {
  throw new Error("version mismatch: plugin block says " + meta.version + ", package.json says " + npmVersion);
}
const file = meta.id + "-" + meta.version + ".mfp";
const i = args.indexOf("--url");
const url = i !== -1 ? args[i + 1] : REPO + "/releases/download/v" + meta.version + "/" + file;
if (!/^https:\/\//.test(url || "")) throw new Error("--url must be an https URL (MudForge downloads packages over HTTPS only)");

const manifest = {
  formatVersion: 1,
  packageId: PACKAGE_ID,
  name: PACKAGE_NAME,
  version: meta.version,
  author: meta.author,
  description: meta.description,
  minClientVersion: MIN_CLIENT,
  contents: ["plugins"],
  plugins: [meta.id],
};
const plugins = [{
  id: meta.id,
  name: meta.name,
  version: meta.version,
  author: meta.author,
  description: meta.description,
}];

const bytes = zip([
  ["package.json", JSON.stringify(manifest, null, 2) + "\n"],
  ["plugins/manifest.json", JSON.stringify(plugins, null, 2) + "\n"],
  ["plugins/" + meta.id + ".lua", lua],
]);
const sha256 = crypto.createHash("sha256").update(bytes).digest("hex");

const advert = {
  client: "MudForge",
  name: PACKAGE_NAME,
  version: meta.version,
  url,
  sha256,
  description: meta.description,
  minClientVersion: MIN_CLIENT,
};

fs.mkdirSync(DIST, { recursive: true });
fs.writeFileSync(path.join(DIST, file), bytes);
fs.writeFileSync(path.join(DIST, "client-package.json"), JSON.stringify(advert, null, 2) + "\n");
console.log("wrote dist/" + file + " (" + bytes.length + " bytes)");
console.log("sha256 " + sha256);
console.log("advertise: Client.Package " + JSON.stringify(advert));
