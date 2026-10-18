-- PROTOTYPE (wayfinder #31): renders every variant x plane x window size into
-- prototype/map-rooms/preview.html. Run from the repo root:
--   luajit prototype/map-rooms/gen.lua && python -m http.server 8031
-- then open http://localhost:8031/prototype/map-rooms/preview.html (?variant=A|B|C).
package.path = "prototype/map-rooms/?.lua;lib/?.lua;" .. package.path
local rooms = require("rooms")
local map = require("map")

local function read(p)
  local f = assert(io.open(p, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

-- the planes, each with a position: synthetic ones first, then live ones (names + leads only)
local PLANES = {
  { "plane_synthetic_town_rooms", "Brassmarket (synthetic: Rooms, a Diagonal run, 3 Wards)", { here = "413", members = { Rei = "431", Tam = "442" } } },
  { "plane_synthetic_ward_wilds", "the Rookery (synthetic: a dangerous Ward's own Wilds)", { here = "602", members = {} } },
  { "plane_synthetic_delve_rooms", "the Lees, Depth 3 (synthetic: a Delve Room)", { here = "d2", members = { Rei = "d4" } } },
  { "plane_gildhythe_named", "Gildhythe (live: names + leads, 2 levels)", nil },
  { "plane_gildhythe_named", "Gildhythe with made-up Wards (stress test: four Wards meeting along diagonals)", nil, "wedges" },
  { "plane_gildhythe_named", "Gildhythe, worst case (one crossing made a checkerboard: two Wards' diagonals cross)", nil, "checker" },
  { "plane_greenroad_named", "the Green Road (live: leads on every side)", nil },
  { "plane_ochrefringe_named", "the Ochre Fringe (live: big wilds)", nil },
  { "plane_tallyglass_named", "the Tally Glass (live: tiny, 2 levels)", nil },
}

-- a live plane: the player at its first Cell on level 0, a member at the far end
local function where(p)
  local ids = {}
  for id, r in pairs(p.rooms) do if r.z == 0 then ids[#ids + 1] = id end end
  table.sort(ids)
  local here = ids[1]
  local h = p.rooms[here]
  local far, d = here, -1
  for _, id in ipairs(ids) do
    local r = p.rooms[id]
    local dd = math.abs(r.x - h.x) + math.abs(r.y - h.y)
    if dd > d then far, d = id, dd end
  end
  return { here = here, members = { Rei = far } }
end

local STYLE = read("src/widgets/shared.css") .. read("src/widgets/map.html"):match("<style>(.-)</style>") .. rooms.STYLE
  .. "html,body{background:#0d1117}"

local function page(body)
  return '<!doctype html><html><head><meta charset="utf-8"><style>' .. STYLE .. "</style></head><body>" .. body .. "</body></html>"
end

local function js(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("</", "<\\/") .. '"'
end

-- the plane without what's invisible (tooltips), to compare with lib/map.lua's drawing
local function drawn(svg, dropLeads)
  local inner = svg:match("<svg[^>]*>(.*)</svg>")
  inner = inner:gsub("<title>.-</title>", ""):gsub("></line>", "/>")
  if dropLeads then inner = inner:gsub('<text class="lead".-</text>', "") end
  return inner
end

local out = { "var DOCS={", "};" }
local docs, meta = {}, {}
for _, key in ipairs({ "A", "B", "C", "D" }) do
  local v = rooms.VARIANTS[key]
  local rows = {}
  for i, P in ipairs(PLANES) do
    local pkg = dofile("tests/fixtures/map/" .. P[1] .. ".lua")
    if P[4] == "wedges" or P[4] == "checker" then
      -- four Wards cut from Gildhythe by its diagonals through the middle of level 0
      local sx, sy, c = 0, 0, 0
      for _, r in pairs(pkg.rooms) do if r.z == 0 then sx, sy, c = sx + r.x, sy + r.y, c + 1 end end
      local cx, cy = math.floor(sx / c + 0.5), math.floor(sy / c + 0.5)
      for _, r in pairs(pkg.rooms) do
        local dx, dy = r.x - cx, r.y - cy
        r.ward = math.abs(dx) > math.abs(dy) and (dx > 0 and "east" or "west") or (dy >= 0 and "north" or "south")
      end
      if P[4] == "checker" then
        for _, r in pairs(pkg.rooms) do if r.z == 0 and r.x == cx and r.y == cy + 1 then r.ward = "west" end end
      end
      pkg.wards = { east = "the Dye Reach", west = "Bandside", north = "the Upper Hythe", south = "Strongbox Row" }
    end
    local w = P[3] or where(pkg)
    local s = rooms.feed(pkg, w)
    local html, info = rooms.html(s, v)
    -- a Plane with no room/ward: is the drawing v0.6.0's?
    local hasRooms = false
    for _, r in pairs(pkg.rooms) do if r.room or r.ward then hasRooms = true end end
    local same = ""
    if not hasRooms then
      local base = map.new(); map.live(base); map.map(base, pkg); map.where(base, w)
      local b = drawn(map.html(base):match("(<svg.-</svg>)"))
      local mine = drawn(html:match("(<svg.-</svg>)"), true)
      same = (b == mine) and "drawing identical to v0.6.0 (tooltips aside" .. (v.leads ~= "hover" and ", plus lead labels" or "") .. ")"
        or "DIFFERS from v0.6.0"
    end
    local notes = {}
    if info.labels > 0 then notes[#notes + 1] = info.labels .. " Room label(s)" end
    if info.leadLabels > 0 then notes[#notes + 1] = info.leadLabels .. " lead label(s)" end
    for _, d in ipairs(info.dropped) do notes[#notes + 1] = "dropped: " .. d end
    if same ~= "" then notes[#notes + 1] = same end
    rows[#rows + 1] = "{t:" .. js(P[2]) .. ",d:" .. js(page(html)) .. ",n:" .. js(table.concat(notes, " &middot; ")) .. "}"
  end
  docs[#docs + 1] = key .. ":{name:" .. js(v.name) .. ",rows:[" .. table.concat(rows, ",") .. "]}"
end

local preview = read("prototype/map-rooms/preview.tpl.html"):gsub("/%*DOCS%*/", function()
  return "var DOCS={" .. table.concat(docs, ",") .. "};"
end)
local f = assert(io.open("prototype/map-rooms/preview.html", "wb"))
f:write(preview)
f:close()
print("wrote prototype/map-rooms/preview.html")
