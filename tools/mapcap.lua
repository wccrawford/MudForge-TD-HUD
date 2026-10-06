-- Capture for the Map window fixtures (wayfinder #19). Logs every
-- TextDungeon GMCP package and each prose line, in arrival order, and saves
-- the log with saveTable; `node tools/mapcap-read.js OUT.json` pulls it back
-- out of MudForge (it is not in plugin_tables.db). Import it once in the
-- Plugin Manager; it keeps the last 3000 entries.
--   mapcap mark <label>   tag the log (e.g. "town", "delve grown")
--   mapcap clear          drop everything logged so far
--   mapcap                show how much is logged
plugin = {
  id = "mapcap",
  name = "mapcap",
  version = "0.0.1",
  author = "wccrawford",
  description = "Throwaway GMCP capture for the Map window fixtures.",
}

local PKGS = {
  "Area.Map", "Area.Where", "Room.Info", "Char.Vitals", "Char.RoundTime",
  "Char.Effects", "Char.Items", "Char.Group", "Quest.Show", "Writing.Read",
  "Page.Refused", "Client.Package",
}
local MAX = 3000

local log = {}
local seq = 0
local dirty = false
local saver = nil

local function add(e)
  seq = seq + 1
  e.seq = seq
  e.t = getCurrentTime()
  log[#log + 1] = e
  if #log > MAX then table.remove(log, 1) end
  dirty = true
end

local function save()
  if not dirty then return end
  dirty = false
  saveTable("log", { seq = seq, entries = log })
end

local function ensureSaver()
  if saver ~= nil and saver ~= "" then return end
  saver = addTimer(1000, save, true)
end

function init()
  local old = loadTable("log")
  if type(old) == "table" and type(old.entries) == "table" then
    log = old.entries
    seq = old.seq or #log
  end
  for _, p in ipairs(PKGS) do
    onGMCPUpdate(p, function(data)
      ensureSaver()
      add({ pkg = p, data = data })
    end)
  end
  on("line", function(l)
    local s = l and (l.clean or l.text)
    if type(s) == "string" and s ~= "" then
      add({ line = string.sub(s, 1, 300) })
    end
  end)
  registerCommand("mapcap", function(args)
    args = args or ""
    local label = string.match(args, "^%s*mark%s+(.+)$")
    if label then
      add({ mark = label })
      ensureSaver()
      save()
      return "mapcap: marked '" .. label .. "' at #" .. seq .. "\r\n"
    elseif string.match(args, "^%s*clear") then
      log = {}
      dirty = true
      save()
      return "mapcap: cleared\r\n"
    end
    save()
    return "mapcap: " .. #log .. " entries, last #" .. seq .. "\r\n"
  end, "Map fixture capture: mapcap mark <label> | clear")
end
