-- Map: the view-model behind the Map window - the Plane of the Area the
-- player stands in (GMCP Area.Map), where they and their Group are on it
-- (Area.Where), and the one level being drawn. Terms are CONTEXT.md's
-- (Plane, Cell, Room, Diagonal run, Ward, Lead, Held position, Level shown,
-- Browsing, No-plane reason).
-- Pure Lua 5.1 library, same shape as pages.lua (new / feed / sever, act()
-- for the widget's clicks, html() for its whole content, ADR 0002). The
-- drawing is look A, "Tiles" (wayfinder #23), with Rooms and Wards in look
-- D, "Floor and dots" (#31), framed by Fit (#22), with the level bar under
-- the plane (#24). It draws only what the package says.
local doc = require("doc")

local M = {}

function M.new()
  return { state = "unfed", members = {} }
end

-- Any Feed snapshot on this connection: a window with no Area.Map yet can
-- then say why it has no Plane.
function M.live(s)
  if s.state == "unfed" then s.state = "live" end
  return s
end

local function list(t)
  local out = {}
  for _, w in ipairs(t or {}) do out[#out + 1] = tostring(w) end
  return out
end

-- A package object of names (names, wards, leads) as text -> text, or nil
-- when the package leaves it out.
local function dict(t)
  if type(t) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(t) do out[tostring(k)] = tostring(v) end
  return out
end

-- One Cell of the package, copied: only the keys the drawing reads, the
-- objects walked with pairs and the arrays with ipairs (feed arrays reach
-- Lua 0-based under t[i]). A Cell with no whole position is left off the
-- Plane. room, ward and leads are kept only when sent; a room id is opaque.
local function copyCell(r)
  local x, y, z = tonumber(r.x), tonumber(r.y), tonumber(r.z)
  if x == nil or y == nil or z == nil then return nil end
  local out = { x = x, y = y, z = z, exits = {}, doors = {},
    leaves = list(r.leaves), unexplored = list(r.unexplored), leads = dict(r.leads) }
  if type(r.terrain) == "string" then out.terrain = r.terrain end
  if r.back ~= nil then out.back = tostring(r.back) end
  if r.room ~= nil then out.room = tostring(r.room) end
  if r.ward ~= nil then out.ward = tostring(r.ward) end
  for w, id in pairs(r.exits or {}) do out.exits[tostring(w)] = tostring(id) end
  for w, d in pairs(r.doors or {}) do
    if type(d) == "table" then
      out.doors[tostring(w)] = { name = tostring(d.name or w), closed = d.closed == true }
    end
  end
  return out
end

-- Area.Where's members as Cell id -> sorted names, keeping only those whose
-- Cell is on the Plane.
local function group(cells, members)
  local out = {}
  for name, id in pairs(members or {}) do
    id = tostring(id)
    if cells[id] ~= nil then
      out[id] = out[id] or {}
      table.insert(out[id], tostring(name))
    end
  end
  for _, names in pairs(out) do table.sort(names) end
  return out
end

-- MudForge's sandbox has no `next`, so emptiness is asked of pairs.
local function empty(t)
  for _ in pairs(t) do return false end
  return true
end

local function levels(cells)
  local seen, zs = {}, {}
  for _, r in pairs(cells or {}) do
    if not seen[r.z] then seen[r.z] = true; zs[#zs + 1] = r.z end
  end
  table.sort(zs)
  return zs, seen
end

local function hasLevel(cells, z)
  for _, r in pairs(cells) do
    if r.z == z then return true end
  end
  return false
end

-- The level shown when not Browsing: the player's, else 0, else the lowest.
local function baseLevel(s)
  if s.here ~= nil then return s.cells[s.here].z end
  local zs, seen = levels(s.cells)
  if seen[0] then return 0 end
  return zs[1]
end

-- Moves the markers to a position whose Cell is on the Plane. A new `here`
-- ends Browsing; a member moving does not.
local function place(s, here, members)
  if here ~= s.here then s.browse = nil end
  s.here = here
  s.members = group(s.cells, members)
  s.off = false
  s.held = nil
end

-- Area.Map: a new Plane, replacing the old whole. A Plane for another Area
-- drops the markers until Area.Where places them and ends Browsing; a
-- re-send of the same Area keeps both where they still fit. A Held position
-- whose Cell the new Plane holds is applied.
function M.map(s, pkg)
  if pkg == nil then return s end
  local cells = {}
  for id, r in pairs(pkg.rooms or {}) do
    if type(r) == "table" then cells[tostring(id)] = copyCell(r) end
  end
  local area = tostring(pkg.area or "")
  local same = s.cells ~= nil and s.area == area
  s.area = area
  s.region = pkg.region ~= nil and tostring(pkg.region) or nil
  local holds = pkg.holds or {}
  s.holds = { enemies = list(holds.enemies), gather = list(holds.gather) }
  s.names = dict(pkg.names)
  s.wards = dict(pkg.wards)
  s.cells = cells
  s.state = "live"
  if same then
    if s.here ~= nil and cells[s.here] == nil then s.here = nil end
    for id in pairs(s.members) do
      if cells[id] == nil then s.members[id] = nil end
    end
    if s.browse ~= nil and not hasLevel(cells, s.browse) then s.browse = nil end
  else
    s.here = nil
    s.members = {}
    s.browse = nil
    s.off = false
  end
  if s.held ~= nil and cells[s.held.here] ~= nil then
    place(s, s.held.here, s.held.members)
  end
  return s
end

-- Area.Where: the player and their Group. With no `here` the player is off
-- the Plane. A `here` not on the Plane yet is held (only the newest) and
-- moves nothing until a Plane that holds it arrives.
function M.where(s, pkg)
  if pkg == nil then return s end
  s.state = "live"
  if pkg.here == nil then
    s.off = true
    s.held = nil
    return s
  end
  local here = tostring(pkg.here)
  if s.cells ~= nil and s.cells[here] ~= nil then
    place(s, here, pkg.members)
  else
    s.held = { here = here, members = pkg.members }
  end
  return s
end

-- Connection lost: the Plane and the markers stay, frozen.
function M.sever(s)
  if s.state == "live" then s.state = "severed" end
  return s
end

-- The Level shown, or nil with no Plane to show.
function M.shown(s)
  if s.cells == nil or empty(s.cells) then return nil end
  if s.browse ~= nil then return s.browse end
  return baseLevel(s)
end

function M.browsing(s)
  return s.browse ~= nil
end

-- A click in the widget. `level` with `z<n>` shows level z = n, or with
-- `mine` the player's. The z rides with a letter because MudForge drops a
-- click's data when it reads as a falsy number, which "0" would; asking for the level shown by default is not
-- Browsing. Nothing is ever sent to the server.
function M.act(s, action, data)
  if action ~= "level" or s.cells == nil then return nil end
  if data == "mine" then
    s.browse = nil
    return nil
  end
  local z = tonumber(type(data) == "string" and data:match("^z(%-?%d+)$") or nil)
  if z == nil or not hasLevel(s.cells, z) then return nil end
  if z == baseLevel(s) then s.browse = nil else s.browse = z end
  return nil
end

local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

-- The Room a Cell is part of: its `room` key, else the Cell itself.
local function roomOf(s, id)
  return s.cells[id].room or id
end

-- The Rooms of the level shown, in the order of their first Cell's id:
-- { id, parts (sorted Cell ids), kind }. kind is "cell" for a Room of one
-- Cell, "rect" when the parts fill their bounding box, "band" for a Diagonal
-- run (one step east and one north or south from Cell to Cell, with `first`
-- and `last` its end Cells, west to east), and "tiles" for any other shape,
-- which the package never promises. Room ids are never parsed.
function M.rooms(s)
  local z = M.shown(s)
  local by, out = {}, {}
  if z == nil then return out end
  for _, id in ipairs(sortedKeys(s.cells)) do
    local r = s.cells[id]
    if r.z == z then
      local rid = roomOf(s, id)
      if by[rid] == nil then
        by[rid] = { id = rid, parts = {} }
        out[#out + 1] = by[rid]
      end
      table.insert(by[rid].parts, id)
    end
  end
  for _, R in ipairs(out) do
    if #R.parts == 1 then
      R.kind = "cell"
    else
      local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
      local cs = {}
      for _, id in ipairs(R.parts) do
        local r = s.cells[id]
        x0, x1, y0, y1 = math.min(x0, r.x), math.max(x1, r.x), math.min(y0, r.y), math.max(y1, r.y)
        cs[#cs + 1] = r
      end
      R.box = { x0 = x0, x1 = x1, y0 = y0, y1 = y1 }
      if (x1 - x0 + 1) * (y1 - y0 + 1) == #R.parts then
        R.kind = "rect"
      else
        table.sort(cs, function(a, b) return a.x < b.x end)
        local dy = cs[2].y - cs[1].y
        local run = dy == 1 or dy == -1
        for i = 2, #cs do
          if cs[i].x - cs[i - 1].x ~= 1 or cs[i].y - cs[i - 1].y ~= dy then run = false end
        end
        if run then
          R.kind, R.first, R.last = "band", cs[1], cs[#cs]
        else
          R.kind = "tiles"
        end
      end
    end
  end
  return out
end

-- ===== Drawing: look A, "Tiles", with look D's Rooms and Wards =====

local U = 20      -- one cell in SVG units; Fit scales the viewBox, so this is only proportion
local T = 12      -- a tile
local HT = T / 2
local EDGE = 2.6
local PAD = 18    -- room around the Plane's bounds for stubs and marks
local CAP = 34    -- the largest a cell is drawn, in px

local DIRS = {
  north = { 0, 1 }, south = { 0, -1 }, east = { 1, 0 }, west = { -1, 0 },
  northeast = { 1, 1 }, northwest = { -1, 1 }, southeast = { 1, -1 }, southwest = { -1, -1 },
}

local TERRAIN = {
  inside = "#7d8590", city = "#a371f7", road = "#c2a878", field = "#6cae4f", forest = "#2e8b57",
  water = "#3b82c4", swamp = "#808c2e", cave = "#9a6b4f", hills = "#d29b45",
}
local NONE = "#3d444d"
local YOU, GROUP, BACK, LINE, DOOR, DARK = "#ffd33d", "#ff7b72", "#39c5cf", "#8b949e", "#f0883e", "#0d1117"

-- Ward hues, none of them a terrain's, given in the sorted order of the
-- Plane's `wards` ids, so no two Wards on one Plane share one (#31: hashing
-- the id collided at once). A Ward's hue is fixed per Plane, not across them.
local WARD_HUES = { "#f778ba", "#56d4dd", "#e3b341", "#79c0ff", "#b4f07a", "#d2a8ff" }

-- Tile-local textures: every tile is drawn inside its own translate(), so a
-- userSpaceOnUse pattern starts at the tile's corner and lines up from tile
-- to tile. The tile is 12 units and each pattern 6.
local INK = 'stroke="#000" stroke-opacity=".38"'
local INKF = 'fill="#000" fill-opacity=".38"'
local PAT = {
  city = '<path d="M0 .5h6M0 3.5h6M1.5 .5v3M4.5 3.5v3" fill="none" ' .. INK .. ' stroke-width=".8"/>',
  road = '<path d="M.5 3h2.4M3.5 3h2" fill="none" ' .. INK .. ' stroke-width="1.1"/>',
  field = '<circle cx="3" cy="3" r=".95" ' .. INKF .. "/>",
  forest = '<path d="M3 .8l2.2 3.8H.8z" ' .. INKF .. "/>",
  water = '<path d="M0 3q1.5-2 3 0t3 0" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width=".9"/>',
  swamp = '<path d="M0 4.5q1.5-1.5 3 0t3 0M1.5 .8v2M4.5 1.2v1.6" fill="none" ' .. INK .. ' stroke-width=".85"/>',
  cave = '<path d="M1 2.2h1.6M3.6 4.6h1.6M.4 5.4h.8M4.2 1h1" fill="none" ' .. INK .. ' stroke-width="1.3" stroke-linecap="round"/>',
  hills = '<path d="M.3 4.8q2.7-4.2 5.4 0" fill="none" ' .. INK .. ' stroke-width=".9"/>',
}
local PAT_ORDER = { "city", "road", "field", "forest", "water", "swamp", "cave", "hills" }
-- inside has no texture: a room in a room
local INSIDE = '<rect x="2.5" y="2.5" width="7" height="7" rx="1" fill="none" ' .. INK .. ' stroke-width="1.1"/>'

-- A number for markup: at most two decimals, no trailing zeros, no "-0".
local function n(v)
  local s
  if v % 1 == 0 then s = string.format("%d", v)
  else s = (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")) end
  if s == "-0" then s = "0" end
  return s
end

local function px(r) return r.x * U end
local function py(r) return -r.y * U end   -- north is +y; SVG y grows down

local function off(w, d)
  local v = DIRS[w]
  return v[1] * d, -v[2] * d
end

local function sign(v)
  if v > 0 then return 1 elseif v < 0 then return -1 end
  return 0
end

-- The first character of a name (UTF-8), for a Group marker.
local function initial(name)
  return name:match("^[%z\1-\127\194-\244][\128-\191]*") or "?"
end

-- A label's width in SVG units, guessed from its characters (UTF-8 lead
-- bytes counted, not bytes).
local function textW(s, fs)
  local _, chars = s:gsub("[^\128-\191]", "")
  return chars * fs * 0.55
end

local function wardHue(s, id)
  for i, k in ipairs(sortedKeys(s.wards or {})) do
    if k == id then return WARD_HUES[(i - 1) % #WARD_HUES + 1] end
  end
  return LINE
end

local function wardName(s, id)
  return (s.wards and s.wards[id]) or id
end

-- Everything the level shown needs, worked out once: its Cells with their
-- marks, the edges between them (each pair once), the stubs, and its Rooms.
local function scene(s)
  local z = M.shown(s)
  local cells, edges, stubs, seen = {}, {}, {}, {}
  for _, id in ipairs(sortedKeys(s.cells)) do
    local r = s.cells[id]
    if r.z == z then
      local o = { id = id, r = r, odd = {}, room = roomOf(s, id) }
      for _, w in ipairs(sortedKeys(r.exits)) do
        local tid = r.exits[w]
        local t = s.cells[tid]
        if t ~= nil then
          if t.z ~= r.z then
            if t.z > r.z then o.up = true else o.down = true end
          else
            local k = id < tid and (id .. "|" .. tid) or (tid .. "|" .. id)
            local door = r.doors[w]
            if seen[k] then
              if door ~= nil and seen[k].door == nil then seen[k].door = door end
            else
              seen[k] = { a = r, b = t, word = w, door = door,
                far = math.max(math.abs(t.x - r.x), math.abs(t.y - r.y)) > 1 }
              edges[#edges + 1] = seen[k]
            end
          end
        end
      end
      for _, kind in ipairs({ "leaves", "unexplored" }) do
        for _, w in ipairs(r[kind]) do
          if w == "up" then o.up = o.up or kind
          elseif w == "down" then o.down = o.down or kind
          elseif DIRS[w] then stubs[#stubs + 1] = { r = r, word = w, kind = kind, door = r.doors[w] }
          else o.odd[#o.odd + 1] = { word = w, kind = kind } end
        end
      end
      if r.back ~= nil then
        if DIRS[r.back] then stubs[#stubs + 1] = { r = r, word = r.back, kind = "back", door = r.doors[r.back] }
        else o.odd[#o.odd + 1] = { word = r.back, kind = "back" } end
      end
      cells[id] = o
    end
  end
  return { z = z, cells = cells, edges = edges, stubs = stubs, rooms = M.rooms(s) }
end

local STAIR = { [true] = "stairs", leaves = "leaves this map", unexplored = "unexplored" }

-- Where a way goes: its Lead when the package names one, else `how`.
local function lead(r, w, how)
  if r.leads ~= nil and r.leads[w] ~= nil then return "to " .. r.leads[w] end
  return how
end

-- A Cell's tooltip: its Room's name and its Ward, then its terrain, stairs,
-- doors, and the ways that leave, each with its Lead.
local function tip(s, o)
  local r = o.r
  local t = {}
  if s.names ~= nil and s.names[o.room] ~= nil then t[#t + 1] = s.names[o.room] end
  if r.ward ~= nil then t[#t + 1] = wardName(s, r.ward) end
  t[#t + 1] = r.terrain or "no terrain"
  if o.up then t[#t + 1] = "up: " .. lead(r, "up", STAIR[o.up]) end
  if o.down then t[#t + 1] = "down: " .. lead(r, "down", STAIR[o.down]) end
  for _, w in ipairs(sortedKeys(r.doors)) do
    t[#t + 1] = w .. ": " .. r.doors[w].name .. (r.doors[w].closed and " (closed)" or " (open)")
  end
  for _, w in ipairs(r.leaves) do
    if w ~= "up" and w ~= "down" then
      local to = lead(r, w, nil)
      t[#t + 1] = to and (w .. ": " .. to) or (w .. " leaves this map")
    end
  end
  for _, w in ipairs(r.unexplored) do
    if w ~= "up" and w ~= "down" then t[#t + 1] = w .. ": unexplored" end
  end
  if r.back ~= nil then t[#t + 1] = r.back .. " leads back out" end
  return table.concat(t, "\n")
end

local function line(x1, y1, x2, y2, attrs)
  return '<line x1="' .. n(x1) .. '" y1="' .. n(y1) .. '" x2="' .. n(x2) .. '" y2="' .. n(y2) .. '" ' .. attrs .. "/>"
end

local DEFS = (function()
  local out = { "<defs>" }
  for _, t in ipairs(PAT_ORDER) do
    out[#out + 1] = '<pattern id="pA-' .. t .. '" width="6" height="6" patternUnits="userSpaceOnUse">' .. PAT[t] .. "</pattern>"
  end
  for _, m in ipairs({ { "aA", LINE }, { "aB", BACK } }) do
    out[#out + 1] = '<marker id="' .. m[1] .. '" viewBox="0 0 6 6" refX="2" refY="3" markerWidth="6" markerHeight="6" markerUnits="userSpaceOnUse" orient="auto"><path d="M0 0L6 3L0 6z" fill="' .. m[2] .. '"/></marker>'
  end
  out[#out + 1] = "</defs>"
  return table.concat(out)
end)()

local SD = 'stroke="' .. DARK .. '" stroke-width="1.2" stroke-linejoin="round"'
local HALO = 'stroke="' .. DARK .. '" stroke-width="1.8" stroke-linejoin="round" paint-order="stroke"'

-- An up or down mark on a tile's right corner: solid for a stair on the
-- Plane, hollow when it leaves the map, hollow and dashed when unexplored.
local function tri(cx, cy, dir, how, to)
  local d = "M" .. n(cx - 3.6) .. " " .. n(cy + 2.6 * dir) .. "L" .. n(cx) .. " " .. n(cy - 3 * dir)
    .. "L" .. n(cx + 3.6) .. " " .. n(cy + 2.6 * dir) .. "z"
  local title = "<title>" .. (dir == 1 and "up: " or "down: ") .. doc.escape(to or STAIR[how]) .. "</title>"
  if how == true then return '<path class="stair" d="' .. d .. '" fill="#fff" ' .. SD .. ">" .. title .. "</path>" end
  return '<path class="stair" d="' .. d .. '" fill="' .. DARK .. '" stroke="#fff" stroke-width="1.2" stroke-linejoin="round"'
    .. (how == "unexplored" and ' stroke-dasharray="1.6 1"' or "") .. ">" .. title .. "</path>"
end

-- Boxes {x0, y0, x1, y1} in SVG units, for keeping labels clear.
local function hits(a, b)
  return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end

local function clear(bx, boxes, own)
  for _, b in ipairs(boxes) do
    if b ~= own and hits(b, bx) then return false end
  end
  return true
end

-- A 2+ Cell Room's shape: its frame (a transform whose origin is the shape's
-- top-left corner, rotated along a band), its size, and a box around it.
-- A rect spans its tiles' footprint; a band is a tile wide, from end Cell to
-- end Cell plus half a tile at each end. A band only ever runs at 45 degrees.
local function shape(R)
  if R.kind == "rect" then
    local b, m = R.box, (U - T) / 2
    local x, y = b.x0 * U - U / 2 + m, -b.y1 * U - U / 2 + m
    local w, h = (b.x1 - b.x0 + 1) * U - 2 * m, (b.y1 - b.y0 + 1) * U - 2 * m
    return { frame = "translate(" .. n(x) .. " " .. n(y) .. ")", x = x, y = y, w = w, h = h, box = { x, y, x + w, y + h } }
  end
  local a, z = R.first, R.last
  local cx, cy = (px(a) + px(z)) / 2, (py(a) + py(z)) / 2
  local steps = z.x - a.x
  local w = steps * U * math.sqrt(2) + T
  local deg = z.y > a.y and -45 or 45
  local r = (w / 2 + T / 2) * math.sqrt(0.5)
  return { frame = "translate(" .. n(cx) .. " " .. n(cy) .. ") rotate(" .. deg .. ") translate(" .. n(-w / 2) .. " " .. n(-T / 2) .. ")",
    w = w, h = T, band = true, box = { cx - r, cy - r, cx + r, cy + r } }
end

-- One Cell's share of its Room's shape, in the shape's own frame: its
-- square cut to the rect, or its stretch along the band.
local function share(R, sh, r)
  if not sh.band then
    local x0, y0 = math.max(px(r) - U / 2, sh.x), math.max(py(r) - U / 2, sh.y)
    local x1, y1 = math.min(px(r) + U / 2, sh.x + sh.w), math.min(py(r) + U / 2, sh.y + sh.h)
    return x0 - sh.x, y0 - sh.y, x1 - x0, y1 - y0
  end
  local seg = U * math.sqrt(2)
  local at = (r.x - R.first.x) * seg + T / 2
  local x0, x1 = math.max(0, at - seg / 2), math.min(sh.w, at + seg / 2)
  return x0, 0, x1 - x0, sh.h
end

-- A tile's terrain drawn w x h in its own frame: colour, then texture.
local function terrainRect(terrain, w, h)
  local out = '<rect width="' .. n(w) .. '" height="' .. n(h) .. '" rx="2" fill="' .. (TERRAIN[terrain] or NONE) .. '"'
    .. (TERRAIN[terrain] and "" or ' stroke="#6e7681" stroke-width=".8"') .. "/>"
  if terrain == "inside" then
    if w == T and h == T then return out .. INSIDE end
    return out .. '<rect x="2.5" y="2.5" width="' .. n(w - 5) .. '" height="' .. n(h - 5) .. '" rx="1" fill="none" ' .. INK .. ' stroke-width="1.1"/>'
  elseif PAT[terrain] then
    return out .. '<rect width="' .. n(w) .. '" height="' .. n(h) .. '" rx="2" fill="url(#pA-' .. terrain .. ')"/>'
  end
  return out
end

-- Ward shading, under everything: each Ward's region is its Cells' squares
-- joined by a band along each diagonal exit between two of its Cells, tinted
-- and outlined dashed. The outline is each piece's stroke masked to outside
-- the region. Where two Wards' bridges cross in one 2x2 block, neither is drawn.
local function wardShading(s, sc)
  local pieces = {}
  for _, id in ipairs(sortedKeys(sc.cells)) do
    local r = sc.cells[id].r
    if r.ward ~= nil then
      pieces[r.ward] = pieces[r.ward] or {}
      table.insert(pieces[r.ward], '<rect x="' .. n(px(r) - U / 2) .. '" y="' .. n(py(r) - U / 2) .. '" width="' .. U .. '" height="' .. U .. '"/>')
    end
  end
  if empty(pieces) then return "" end
  local BW = 10   -- under 2 x 5.66, so a bridge never reaches the tiles across the corner
  local blocks, keys = {}, {}
  for _, e in ipairs(sc.edges) do
    local a, b = e.a, e.b
    if math.abs(a.x - b.x) == 1 and math.abs(a.y - b.y) == 1 and a.ward ~= nil and a.ward == b.ward then
      local k = math.min(a.x, b.x) .. "," .. math.min(a.y, b.y)
      if blocks[k] == nil then blocks[k] = {}; keys[#keys + 1] = k end
      table.insert(blocks[k], e)
    end
  end
  for _, k in ipairs(keys) do
    local bs = blocks[k]
    if not (#bs == 2 and bs[1].a.ward ~= bs[2].a.ward) then
      for _, e in ipairs(bs) do
        local ax, ay, bx, by = px(e.a), py(e.a), px(e.b), py(e.b)
        local L = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        local nx, ny = -(by - ay) / L * BW / 2, (bx - ax) / L * BW / 2
        table.insert(pieces[e.a.ward], '<polygon points="' .. n(ax + nx) .. "," .. n(ay + ny) .. " " .. n(bx + nx) .. "," .. n(by + ny) .. " "
          .. n(bx - nx) .. "," .. n(by - ny) .. " " .. n(ax - nx) .. "," .. n(ay - ny) .. '"/>')
      end
    end
  end
  local out = {}
  for i, w in ipairs(sortedKeys(pieces)) do
    local hue, body, mask = wardHue(s, w), table.concat(pieces[w]), "wm" .. i
    out[#out + 1] = '<g class="ward" opacity=".1" fill="' .. hue .. '">' .. body .. "</g>"
      .. '<mask id="' .. mask .. '" maskUnits="userSpaceOnUse" x="-99999" y="-99999" width="199998" height="199998">'
      .. '<rect x="-99999" y="-99999" width="199998" height="199998" fill="#fff"/><g fill="#000">' .. body .. "</g></mask>"
      .. '<g class="wardline" mask="url(#' .. mask .. ')" fill="none" stroke="' .. hue .. '" stroke-width="2.4" stroke-dasharray="3 2" stroke-opacity=".85">' .. body .. "</g>"
  end
  return table.concat(out)
end

-- The plane as SVG: the whole Plane's x/y bounds framed by the viewBox, so
-- the frame holds still while Browsing, grown to hold every label; the cell
-- size capped by max sizes.
local function svg(s, sc)
  local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
  for _, r in pairs(s.cells) do
    x0, x1 = math.min(x0, r.x), math.max(x1, r.x)
    y0, y1 = math.min(y0, r.y), math.max(y1, r.y)
  end
  local g = {}
  local function add(part) g[#g + 1] = part end
  local boxes = {}       -- what a label must not cover: tiles, Room shapes, stubs, marks
  local leadAt = {}      -- where a Lead's label could go

  add(wardShading(s, sc))

  -- 2+ Cell Rooms, faded into the background, under the edges so the lines
  -- between their Cells show the ways to move
  local shapes = {}
  for _, R in ipairs(sc.rooms) do
    if R.kind == "rect" or R.kind == "band" then
      local sh = shape(R)
      shapes[R.id] = sh
      local main = s.cells[R.id] or s.cells[R.parts[1]]
      add('<g class="rshape" opacity=".38" transform="' .. sh.frame .. '">' .. terrainRect(main.terrain, sh.w, sh.h) .. "</g>")
      boxes[#boxes + 1] = sh.box
    end
  end

  for _, e in ipairs(sc.edges) do
    add(line(px(e.a), py(e.a), px(e.b), py(e.b), 'stroke="' .. LINE .. '" stroke-width="' .. EDGE .. '"'
      .. (e.far and ' stroke-dasharray="3 2"' or "")))
  end
  for _, st in ipairs(sc.stubs) do
    local x, y = px(st.r), py(st.r)
    local ax, ay = off(st.word, HT)
    local bx, by = off(st.word, U * 0.6)
    local col = st.kind == "back" and BACK or LINE
    local attrs = 'stroke="' .. col .. '" stroke-width="' .. EDGE .. '"'
    if st.kind == "unexplored" then attrs = attrs .. ' stroke-dasharray="2 1.6"'
    else attrs = attrs .. ' marker-end="url(#' .. (st.kind == "back" and "aB" or "aA") .. ')"' end
    local tx, ty = off(st.word, U * 0.6 + 3)
    local box = { math.min(x + ax, x + tx) - 3, math.min(y + ay, y + ty) - 3, math.max(x + ax, x + tx) + 3, math.max(y + ay, y + ty) + 3 }
    boxes[#boxes + 1] = box
    local to = st.kind == "leaves" and st.r.leads ~= nil and st.r.leads[st.word] or nil
    if to ~= nil then
      add('<line x1="' .. n(x + ax) .. '" y1="' .. n(y + ay) .. '" x2="' .. n(x + bx) .. '" y2="' .. n(y + by) .. '" ' .. attrs
        .. "><title>" .. doc.escape(st.word .. ": to " .. to) .. "</title></line>")
      local d = DIRS[st.word]
      local lx, ly = off(st.word, U * 0.6 + 3.2)
      leadAt[#leadAt + 1] = { text = to, x = x + lx, y = y + ly, dx = d[1], dy = -d[2], own = box }
    else
      add(line(x + ax, y + ay, x + bx, y + by, attrs))
    end
    if st.kind == "unexplored" then
      add('<g><title>' .. doc.escape(st.word) .. ': unexplored</title><circle cx="' .. n(x + tx) .. '" cy="' .. n(y + ty)
        .. '" r="3.4" fill="' .. DARK .. '" stroke="#e6edf3" stroke-width="1"/><text x="' .. n(x + tx) .. '" y="' .. n(y + ty + 2)
        .. '" font-size="5.4" font-weight="700" text-anchor="middle" fill="#e6edf3">?</text></g>')
    end
  end

  -- Rooms: a one-Cell Room is v0.6.0's tile; a 2+ Cell Room keeps each Cell's
  -- tooltip on an unpainted share of its shape and a dot on each Cell
  local function tile(o)
    local r = o.r
    local x, y = px(r) - HT, py(r) - HT
    add('<g class="room" transform="translate(' .. n(x) .. " " .. n(y) .. ')"><title>' .. doc.escape(tip(s, o)) .. "</title>"
      .. terrainRect(r.terrain, T, T) .. "</g>")
    boxes[#boxes + 1] = { x, y, x + T, y + T }
  end
  local labels = {}
  for _, R in ipairs(sc.rooms) do
    local sh = shapes[R.id]
    if sh == nil then
      for _, id in ipairs(R.parts) do tile(sc.cells[id]) end
    else
      add('<g class="room multi" transform="' .. sh.frame .. '">')
      for _, id in ipairs(R.parts) do
        local hx, hy, hw, hh = share(R, sh, s.cells[id])
        add('<rect x="' .. n(hx) .. '" y="' .. n(hy) .. '" width="' .. n(hw) .. '" height="' .. n(hh) .. '" fill="#000" fill-opacity="0"><title>'
          .. doc.escape(tip(s, sc.cells[id])) .. "</title></rect>")
      end
      add("</g>")
      for _, id in ipairs(R.parts) do
        local r = s.cells[id]
        add('<circle class="dot" cx="' .. n(px(r)) .. '" cy="' .. n(py(r)) .. '" r="3.6" fill="' .. (TERRAIN[r.terrain] or NONE) .. '" ' .. SD
          .. "><title>" .. doc.escape(tip(s, sc.cells[id])) .. "</title></circle>")
      end
      if s.names ~= nil and s.names[R.id] ~= nil then labels[#labels + 1] = { text = s.names[R.id], box = sh.box } end
    end
  end

  -- marks sit on each Cell's own tile corners, half outside it, over everything else
  local marks = {}
  for _, id in ipairs(sortedKeys(sc.cells)) do
    local o = sc.cells[id]
    local r = o.r
    local x, y = px(r) - HT, py(r) - HT
    local left, right = { x - 4, y - 4, x + 4, y + 4 }, { x + T - 4, y - 3, x + T + 4, y + T + 3 }
    if o.up or o.down then boxes[#boxes + 1] = right end
    if o.up then marks[#marks + 1] = tri(x + T, y + 1.5, 1, o.up, lead(r, "up", nil)) end
    if o.down then marks[#marks + 1] = tri(x + T, y + T - 1.5, -1, o.down, lead(r, "down", nil)) end
    if #o.odd > 0 then
      boxes[#boxes + 1] = left
      local words, bk, first = {}, false, nil
      for i, q in ipairs(o.odd) do
        local to = lead(r, q.word, nil)
        words[i] = to and (q.word .. ": " .. to) or q.word
        first = first or (to and r.leads[q.word])
        if q.kind == "back" then bk = true end
      end
      marks[#marks + 1] = '<g class="odd"><title>' .. doc.escape(table.concat(words, ", ")) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y)
        .. '" r="3.6" fill="' .. (bk and BACK or "#fff") .. '" ' .. SD .. '/><path d="M' .. n(x - 1.5) .. " " .. n(y + 1.5) .. "L" .. n(x + 1.6) .. " " .. n(y - 1.6)
        .. "M" .. n(x - 0.6) .. " " .. n(y - 1.6) .. "H" .. n(x + 1.6) .. "V" .. n(y + 0.6) .. '" fill="none" stroke="' .. DARK .. '" stroke-width="1"/></g>'
      if first then leadAt[#leadAt + 1] = { text = first, x = x - 5, y = y, dx = -1, dy = 0, own = left } end
    end
    for _, w in ipairs({ "up", "down" }) do
      if o[w] and r.leads ~= nil and r.leads[w] ~= nil then
        leadAt[#leadAt + 1] = { text = r.leads[w], x = x + T + 5, y = w == "up" and y + 1.5 or y + T - 1.5, dx = 1, dy = 0, own = right }
      end
    end
  end

  -- Room labels beside the Room: above, else below, right, left, at the first
  -- side that covers no tile, Room, stub, mark or label; else dropped (the
  -- name stays in the tooltip)
  local taken, drawn = {}, {}
  for _, L in ipairs(labels) do
    local b, fs = L.box, 6.2
    local cx, cy, w = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2, textW(L.text, fs)
    for _, t in ipairs({
      { cx, b[2] - 1.6, "middle", cx - w / 2 }, { cx, b[4] + fs, "middle", cx - w / 2 },
      { b[3] + 2, cy + fs * 0.36, "start", b[3] + 2 }, { b[1] - 2, cy + fs * 0.36, "end", b[1] - 2 - w },
    }) do
      local bx = { t[4], t[2] - fs, t[4] + w, t[2] + 1 }
      if clear(bx, taken) and clear(bx, boxes, L.box) then
        taken[#taken + 1] = bx
        drawn[#drawn + 1] = '<text class="rlabel" x="' .. n(t[1]) .. '" y="' .. n(t[2]) .. '" font-size="' .. n(fs)
          .. '" font-weight="600" text-anchor="' .. t[3] .. '" fill="#e6edf3" ' .. HALO .. ">" .. doc.escape(L.text) .. "</text>"
        break
      end
    end
  end

  -- Lead labels at a stub's tip, off a disc to its left or a stair mark to
  -- its right, only where they cover no tile or other label
  for _, L in ipairs(leadAt) do
    local fs = 5.8
    local w = textW(L.text, fs)
    local anchor, lx = "middle", L.x - w / 2
    if L.dx > 0 then anchor, lx = "start", L.x elseif L.dx < 0 then anchor, lx = "end", L.x - w end
    local y = L.y + fs * 0.36
    if L.dx == 0 then y = L.dy < 0 and L.y - 0.5 or L.y + fs end
    local bx = { lx, y - fs, lx + w, y + 1 }
    if clear(bx, taken) and clear(bx, boxes, L.own) then
      taken[#taken + 1] = bx
      drawn[#drawn + 1] = '<text class="lead" x="' .. n(L.x) .. '" y="' .. n(y) .. '" font-size="' .. n(fs) .. '" font-style="italic" text-anchor="' .. anchor
        .. '" fill="#c9d1d9" ' .. HALO .. ">" .. doc.escape(L.text) .. "</text>"
    end
  end
  -- labels over the Rooms, under the markers (a label once hid a Group disc)
  for _, l in ipairs(drawn) do add(l) end

  -- doors: across the line at the cell boundary; closed a bar, open two
  -- posts. Drawn over the you ring, which would otherwise hide half a door
  -- on the player's own tile.
  local doors = {}
  local function door(a, word, b, d)
    local v = DIRS[word] or { sign(b.x - a.x), sign(b.y - a.y) }
    local mx, my = px(a) + v[1] * U / 2, py(a) - v[2] * U / 2
    local len = math.sqrt(v[1] * v[1] + v[2] * v[2])
    local nx, ny = -v[2] / len, -v[1] / len
    local L = 4.8
    local title = "<title>" .. doc.escape(d.name) .. (d.closed and " (closed)" or " (open)") .. "</title>"
    if d.closed then
      doors[#doors + 1] = '<g class="door">' .. title .. line(mx - nx * L, my - ny * L, mx + nx * L, my + ny * L, 'stroke="' .. DOOR .. '" stroke-width="3"') .. "</g>"
    else
      doors[#doors + 1] = '<g class="door" stroke="' .. DOOR .. '" stroke-width="2.2">' .. title
        .. line(mx - nx * L, my - ny * L, mx - nx * 2.2, my - ny * 2.2, "")
        .. line(mx + nx * 2.2, my + ny * 2.2, mx + nx * L, my + ny * L, "") .. "</g>"
    end
  end
  for _, e in ipairs(sc.edges) do
    if e.door ~= nil then door(e.a, e.word, e.b, e.door) end
  end
  for _, st in ipairs(sc.stubs) do
    if st.door ~= nil then door(st.r, st.word, nil, st.door) end
  end

  -- the Group: a disc with the initial on the tile's bottom-left corner,
  -- fanning right when several share a Cell
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.cells[id]
    if r.z == sc.z then
      for i, name in ipairs(s.members[id]) do
        local x, y = px(r) - HT + (i - 1) * 6, py(r) + HT
        add('<g class="member"><title>' .. doc.escape(name) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y) .. '" r="4" fill="' .. GROUP
          .. '" stroke="' .. DARK .. '" stroke-width="1.2"/><text x="' .. n(x) .. '" y="' .. n(y + 1.9)
          .. '" font-size="5.4" text-anchor="middle" fill="' .. DARK .. '" font-weight="700">' .. doc.escape(initial(name)) .. "</text></g>")
      end
    end
  end

  -- you: a ring around your Cell's tile with a dot in its centre
  local you = s.here ~= nil and s.cells[s.here] or nil
  if you ~= nil and you.z == sc.z then
    local with = s.members[s.here]
    local title = "You" .. (with and (", with " .. table.concat(with, ", ")) or "")
    add('<g class="you"><title>' .. doc.escape(title) .. '</title><rect x="' .. n(px(you) - HT - 2.6) .. '" y="' .. n(py(you) - HT - 2.6)
      .. '" width="' .. n(T + 5.2) .. '" height="' .. n(T + 5.2) .. '" rx="3.5" fill="none" stroke="' .. YOU .. '" stroke-width="2.4"/>'
      .. '<circle cx="' .. n(px(you)) .. '" cy="' .. n(py(you)) .. '" r="2.8" fill="' .. YOU .. '" stroke="' .. DARK .. '" stroke-width="1.2"/></g>')
  end
  for _, d in ipairs(doors) do add(d) end
  for _, m in ipairs(marks) do add(m) end   -- over the you ring, so it never hides a mark

  -- the frame holds every label too: a Lead past the Plane's edge was cut off
  local fx0, fy0, fx1, fy1 = x0 * U - PAD, -y1 * U - PAD, x1 * U + PAD, -y0 * U + PAD
  for _, b in ipairs(taken) do
    fx0, fy0, fx1, fy1 = math.min(fx0, b[1] - 3), math.min(fy0, b[2] - 3), math.max(fx1, b[3] + 3), math.max(fy1, b[4] + 3)
  end
  local w, h = fx1 - fx0, fy1 - fy0
  return '<svg class="plane" viewBox="' .. n(fx0) .. " " .. n(fy0) .. " " .. n(w) .. " " .. n(h)
    .. '" preserveAspectRatio="xMidYMid meet" style="max-width:' .. n(w / U * CAP) .. "px;max-height:" .. n(h / U * CAP) .. 'px">'
    .. DEFS .. table.concat(g) .. "</svg>"
end

local SEP = '<span class="msep">&#183;</span>'

-- The header: Area and Region on the left; on the right your Room and Ward,
-- hidden off the Plane and while Browsing. The window's stylesheet wraps it
-- to a second line only when the two sides don't fit.
local function head(s)
  local right = ""
  if s.here ~= nil and s.browse == nil then
    local c, parts = s.cells[s.here], {}
    local name = s.names ~= nil and s.names[roomOf(s, s.here)] or nil
    if name ~= nil then parts[#parts + 1] = '<span class="mroom">' .. doc.escape(name) .. "</span>" end
    if c.ward ~= nil then
      parts[#parts + 1] = '<span class="mward"><i style="background:' .. wardHue(s, c.ward) .. '"></i>' .. doc.escape(wardName(s, c.ward)) .. "</span>"
    end
    if #parts > 0 then right = '<span class="mright">' .. table.concat(parts, SEP) .. "</span>" end
  end
  return '<div class="mhead"><span class="mleft"><span class="marea">' .. doc.escape(s.area) .. "</span>"
    .. (s.region ~= nil and (SEP .. '<span class="mregion">' .. doc.escape(s.region) .. "</span>") or "") .. "</span>" .. right .. "</div>"
end

-- The Ward legend: a swatch and the name of each Ward in `wards`; a Ward
-- with no Cells on the Plane (a dangerous Ward, with its own map) hollow.
local function legend(s)
  if s.wards == nil or empty(s.wards) then return "" end
  local used = {}
  for _, c in pairs(s.cells) do
    if c.ward ~= nil then used[c.ward] = true end
  end
  local out = {}
  for _, w in ipairs(sortedKeys(s.wards)) do
    local hue, name = wardHue(s, w), doc.escape(s.wards[w])
    if used[w] then
      out[#out + 1] = '<span class="lgw" title="' .. name .. '"><i style="background:' .. hue .. '"></i>' .. name .. "</span>"
    else
      out[#out + 1] = '<span class="lgw hollow" title="' .. name .. ': its own map, through the door that names it"><i style="border-color:'
        .. hue .. '"></i>' .. name .. "</span>"
    end
  end
  return '<div class="mlegend">' .. table.concat(out) .. "</div>"
end

-- The level bar: ▼ Level n of m ▲, with whoever is on another level by the
-- arrow that leads to them (you too, while Browsing). None on a 1-level Plane.
local function levelBar(s, z)
  local zs = levels(s.cells)
  if #zs < 2 then return "" end
  local at = 1
  for i, v in ipairs(zs) do if v == z then at = i end end
  local function nth(v)
    for i, w in ipairs(zs) do if w == v then return i end end
  end
  local function act(v) return ' data-mud-action="level" data-mud-data="' .. doc.escape(v) .. '"' end
  local function arrow(glyph, title, to)
    if to == nil then return '<span class="lvarrow off" title="' .. title .. '">' .. glyph .. "</span>" end
    return '<span class="lvarrow" title="' .. title .. '"' .. act(to) .. ">" .. glyph .. "</span>"
  end
  local who = { up = {}, down = {} }
  local you = s.here ~= nil and s.cells[s.here] or nil
  if you ~= nil and you.z ~= z then
    table.insert(who[you.z > z and "up" or "down"], '<span class="lvyou" title="You: level ' .. nth(you.z) .. ' (back to you)"' .. act("mine") .. "></span>")
  end
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.cells[id]
    if r.z ~= z then
      for _, name in ipairs(s.members[id]) do
        table.insert(who[r.z > z and "up" or "down"], '<span class="lvmem" title="' .. doc.escape(name .. ": level " .. nth(r.z)) .. '"'
          .. act("z" .. n(r.z)) .. ">" .. doc.escape(initial(name)) .. "</span>")
      end
    end
  end
  return '<div class="mlevel"><span class="lvend">' .. arrow("&#9660;", "Level below", zs[at - 1] and ("z" .. n(zs[at - 1])))
    .. table.concat(who.down) .. "</span>"
    .. '<span class="lvmid' .. (s.browse ~= nil and " browsing" or "") .. '">Level ' .. at .. " of " .. #zs .. "</span>"
    .. '<span class="lvend lvr">' .. table.concat(who.up) .. arrow("&#9650;", "Level above", zs[at + 1] and ("z" .. n(zs[at + 1]))) .. "</span></div>"
end

local function holds(s)
  local out = {}
  for _, k in ipairs({ { "enemies", "Enemies" }, { "gather", "Gather" } }) do
    local names = s.holds[k[1]]
    if #names > 0 then
      local esc = {}
      for i, v in ipairs(names) do esc[i] = doc.escape(v) end
      out[#out + 1] = "<div><b>" .. k[2] .. "</b> " .. table.concat(esc, ", ") .. "</div>"
    end
  end
  if #out == 0 then return "" end
  return '<div class="mholds">' .. table.concat(out) .. "</div>"
end

local function reason(text)
  return '<div class="mreason">' .. text .. "</div>"
end

-- The widget's whole content, in `font` (the widget's own, see doc.fontStyle).
-- A No-plane reason is shown only while Live.
function M.html(s, font)
  local live = s.state == "live"
  local body
  if s.state == "unfed" or s.cells == nil then
    body = live and reason("No map from the server yet. If <code>config map</code> is off, <code>config map on</code> brings it back.")
      or '<div class="mnone">Map</div>'
  elseif s.off then
    body = live and reason("You are not on the map of " .. doc.escape(s.area) .. ".") or '<div class="mnone">Map</div>'
  elseif empty(s.cells) then
    body = head(s) .. (live and reason(doc.escape(s.area) .. " has no map.") or "")
  else
    local sc = scene(s)
    body = head(s) .. '<div class="mbody">' .. svg(s, sc) .. "</div>" .. legend(s) .. levelBar(s, sc.z) .. holds(s)
  end
  return '<div class="hud mapwin" data-state="' .. s.state .. '"' .. doc.fontStyle(font) .. ">" .. body .. "</div>"
end

return M
