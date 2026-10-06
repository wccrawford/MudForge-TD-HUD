-- Map: the view-model behind the Map window - the Plane of the Area the
-- player stands in (GMCP Area.Map), where they and their Group are on it
-- (Area.Where), and the one level being drawn. Terms are CONTEXT.md's
-- (Plane, Held position, Level shown, Browsing, No-plane reason).
-- Pure Lua 5.1 library, same shape as pages.lua (new / feed / sever, act()
-- for the widget's clicks, html() for its whole content, ADR 0002). The
-- drawing is look A, "Tiles" (wayfinder #23), framed by Fit (#22), with the
-- level bar under the plane (#24). It draws only what the package says.
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

-- One room of the package, copied: only the keys the drawing reads, the
-- objects walked with pairs and the arrays with ipairs (feed arrays reach
-- Lua 0-based under t[i]). A room with no whole cell is left off the Plane.
local function copyRoom(r)
  local x, y, z = tonumber(r.x), tonumber(r.y), tonumber(r.z)
  if x == nil or y == nil or z == nil then return nil end
  local out = { x = x, y = y, z = z, exits = {}, doors = {},
    leaves = list(r.leaves), unexplored = list(r.unexplored) }
  if type(r.terrain) == "string" then out.terrain = r.terrain end
  if r.back ~= nil then out.back = tostring(r.back) end
  for w, id in pairs(r.exits or {}) do out.exits[tostring(w)] = tostring(id) end
  for w, d in pairs(r.doors or {}) do
    if type(d) == "table" then
      out.doors[tostring(w)] = { name = tostring(d.name or w), closed = d.closed == true }
    end
  end
  return out
end

-- Area.Where's members as room id -> sorted names, keeping only those whose
-- room is on the Plane.
local function group(rooms, members)
  local out = {}
  for name, id in pairs(members or {}) do
    id = tostring(id)
    if rooms[id] ~= nil then
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

local function levels(rooms)
  local seen, zs = {}, {}
  for _, r in pairs(rooms or {}) do
    if not seen[r.z] then seen[r.z] = true; zs[#zs + 1] = r.z end
  end
  table.sort(zs)
  return zs, seen
end

local function hasLevel(rooms, z)
  for _, r in pairs(rooms) do
    if r.z == z then return true end
  end
  return false
end

-- The level shown when not Browsing: the player's, else 0, else the lowest.
local function baseLevel(s)
  if s.here ~= nil then return s.rooms[s.here].z end
  local zs, seen = levels(s.rooms)
  if seen[0] then return 0 end
  return zs[1]
end

-- Moves the markers to a position whose room is on the Plane. A new `here`
-- ends Browsing; a member moving does not.
local function place(s, here, members)
  if here ~= s.here then s.browse = nil end
  s.here = here
  s.members = group(s.rooms, members)
  s.off = false
  s.held = nil
end

-- Area.Map: a new Plane, replacing the old whole. A Plane for another Area
-- drops the markers until Area.Where places them and ends Browsing; a
-- re-send of the same Area keeps both where they still fit. A Held position
-- whose room the new Plane holds is applied.
function M.map(s, pkg)
  if pkg == nil then return s end
  local rooms = {}
  for id, r in pairs(pkg.rooms or {}) do
    if type(r) == "table" then rooms[tostring(id)] = copyRoom(r) end
  end
  local area = tostring(pkg.area or "")
  local same = s.rooms ~= nil and s.area == area
  s.area = area
  s.region = pkg.region ~= nil and tostring(pkg.region) or nil
  local holds = pkg.holds or {}
  s.holds = { enemies = list(holds.enemies), gather = list(holds.gather) }
  s.rooms = rooms
  s.state = "live"
  if same then
    if s.here ~= nil and rooms[s.here] == nil then s.here = nil end
    for id in pairs(s.members) do
      if rooms[id] == nil then s.members[id] = nil end
    end
    if s.browse ~= nil and not hasLevel(rooms, s.browse) then s.browse = nil end
  else
    s.here = nil
    s.members = {}
    s.browse = nil
    s.off = false
  end
  if s.held ~= nil and rooms[s.held.here] ~= nil then
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
  if s.rooms ~= nil and s.rooms[here] ~= nil then
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
  if s.rooms == nil or empty(s.rooms) then return nil end
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
  if action ~= "level" or s.rooms == nil then return nil end
  if data == "mine" then
    s.browse = nil
    return nil
  end
  local z = tonumber(type(data) == "string" and data:match("^z(%-?%d+)$") or nil)
  if z == nil or not hasLevel(s.rooms, z) then return nil end
  if z == baseLevel(s) then s.browse = nil else s.browse = z end
  return nil
end

-- ===== Drawing: look A, "Tiles" =====

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

local function sortedIds(rooms)
  local ids = {}
  for id in pairs(rooms) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

-- The first character of a name (UTF-8), for a Group marker.
local function initial(name)
  return name:match("^[%z\1-\127\194-\244][\128-\191]*") or "?"
end

-- Everything the level shown needs, worked out once: its rooms with their
-- marks, the edges between them (each pair once), and the stubs.
local function scene(s)
  local z = M.shown(s)
  local rooms, edges, stubs, seen = {}, {}, {}, {}
  for _, id in ipairs(sortedIds(s.rooms)) do
    local r = s.rooms[id]
    if r.z == z then
      local o = { id = id, r = r, odd = {} }
      for _, w in ipairs(sortedKeys(r.exits)) do
        local tid = r.exits[w]
        local t = s.rooms[tid]
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
      rooms[#rooms + 1] = o
    end
  end
  return { z = z, rooms = rooms, edges = edges, stubs = stubs }
end

local STAIR = { [true] = "stairs", leaves = "leaves this map", unexplored = "unexplored" }

-- A room's tooltip: its terrain, stairs, doors, and the ways that leave.
local function tip(o)
  local r = o.r
  local t = { r.terrain or "no terrain" }
  if o.up then t[#t + 1] = "up: " .. STAIR[o.up] end
  if o.down then t[#t + 1] = "down: " .. STAIR[o.down] end
  for _, w in ipairs(sortedKeys(r.doors)) do
    t[#t + 1] = w .. ": " .. r.doors[w].name .. (r.doors[w].closed and " (closed)" or " (open)")
  end
  for _, w in ipairs(r.leaves) do
    if w ~= "up" and w ~= "down" then t[#t + 1] = w .. " leaves this map" end
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

-- An up or down mark on a tile's right corner: solid for a stair on the
-- Plane, hollow when it leaves the map, hollow and dashed when unexplored.
local function tri(cx, cy, dir, how)
  local d = "M" .. n(cx - 3.6) .. " " .. n(cy + 2.6 * dir) .. "L" .. n(cx) .. " " .. n(cy - 3 * dir)
    .. "L" .. n(cx + 3.6) .. " " .. n(cy + 2.6 * dir) .. "z"
  local title = "<title>" .. (dir == 1 and "up: " or "down: ") .. STAIR[how] .. "</title>"
  if how == true then return '<path class="stair" d="' .. d .. '" fill="#fff" ' .. SD .. ">" .. title .. "</path>" end
  return '<path class="stair" d="' .. d .. '" fill="' .. DARK .. '" stroke="#fff" stroke-width="1.2" stroke-linejoin="round"'
    .. (how == "unexplored" and ' stroke-dasharray="1.6 1"' or "") .. ">" .. title .. "</path>"
end

-- The plane as SVG: the whole Plane's x/y bounds framed by the viewBox, so
-- the frame holds still while Browsing; the cell size capped by max sizes.
local function svg(s, sc)
  local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
  for _, r in pairs(s.rooms) do
    x0, x1 = math.min(x0, r.x), math.max(x1, r.x)
    y0, y1 = math.min(y0, r.y), math.max(y1, r.y)
  end
  local w, h = (x1 - x0) * U + 2 * PAD, (y1 - y0) * U + 2 * PAD
  local g = {}
  local function add(part) g[#g + 1] = part end

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
    add(line(x + ax, y + ay, x + bx, y + by, attrs))
    if st.kind == "unexplored" then
      local qx, qy = off(st.word, U * 0.6 + 3)
      add('<g><title>' .. doc.escape(st.word) .. ': unexplored</title><circle cx="' .. n(x + qx) .. '" cy="' .. n(y + qy)
        .. '" r="3.4" fill="' .. DARK .. '" stroke="#e6edf3" stroke-width="1"/><text x="' .. n(x + qx) .. '" y="' .. n(y + qy + 2)
        .. '" font-size="5.4" font-weight="700" text-anchor="middle" fill="#e6edf3">?</text></g>')
    end
  end

  local marks = {}
  for _, o in ipairs(sc.rooms) do
    local r = o.r
    local x, y = px(r) - HT, py(r) - HT
    add('<g class="room" transform="translate(' .. n(x) .. " " .. n(y) .. ')"><title>' .. doc.escape(tip(o)) .. "</title>"
      .. '<rect width="' .. T .. '" height="' .. T .. '" rx="2" fill="' .. (TERRAIN[r.terrain] or NONE) .. '"'
      .. (TERRAIN[r.terrain] and "" or ' stroke="#6e7681" stroke-width=".8"') .. "/>")
    if r.terrain == "inside" then add(INSIDE)
    elseif PAT[r.terrain] then add('<rect width="' .. T .. '" height="' .. T .. '" rx="2" fill="url(#pA-' .. r.terrain .. ')"/>') end
    add("</g>")
    -- marks sit on the tile's corners, half outside it, over everything else
    if o.up then marks[#marks + 1] = tri(x + T, y + 1.5, 1, o.up) end
    if o.down then marks[#marks + 1] = tri(x + T, y + T - 1.5, -1, o.down) end
    if #o.odd > 0 then
      local words, bk = {}, false
      for i, q in ipairs(o.odd) do
        words[i] = q.word
        if q.kind == "back" then bk = true end
      end
      marks[#marks + 1] = '<g class="odd"><title>' .. doc.escape(table.concat(words, ", ")) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y)
        .. '" r="3.6" fill="' .. (bk and BACK or "#fff") .. '" ' .. SD .. '/><path d="M' .. n(x - 1.5) .. " " .. n(y + 1.5) .. "L" .. n(x + 1.6) .. " " .. n(y - 1.6)
        .. "M" .. n(x - 0.6) .. " " .. n(y - 1.6) .. "H" .. n(x + 1.6) .. "V" .. n(y + 0.6) .. '" fill="none" stroke="' .. DARK .. '" stroke-width="1"/></g>'
    end
  end

  -- doors: across the line at the cell boundary; closed a bar, open two posts
  local function door(a, word, b, d)
    local v = DIRS[word] or { sign(b.x - a.x), sign(b.y - a.y) }
    local mx, my = px(a) + v[1] * U / 2, py(a) - v[2] * U / 2
    local len = math.sqrt(v[1] * v[1] + v[2] * v[2])
    local nx, ny = -v[2] / len, -v[1] / len
    local L = 4.8
    local title = "<title>" .. doc.escape(d.name) .. (d.closed and " (closed)" or " (open)") .. "</title>"
    if d.closed then
      add('<g class="door">' .. title .. line(mx - nx * L, my - ny * L, mx + nx * L, my + ny * L, 'stroke="' .. DOOR .. '" stroke-width="3"') .. "</g>")
    else
      add('<g class="door" stroke="' .. DOOR .. '" stroke-width="2.2">' .. title
        .. line(mx - nx * L, my - ny * L, mx - nx * 2.2, my - ny * 2.2, "")
        .. line(mx + nx * 2.2, my + ny * 2.2, mx + nx * L, my + ny * L, "") .. "</g>")
    end
  end
  for _, e in ipairs(sc.edges) do
    if e.door ~= nil then door(e.a, e.word, e.b, e.door) end
  end
  for _, st in ipairs(sc.stubs) do
    if st.door ~= nil then door(st.r, st.word, nil, st.door) end
  end

  -- the Group: a disc with the initial on the tile's bottom-left corner,
  -- fanning right when several share a room
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.rooms[id]
    if r.z == sc.z then
      for i, name in ipairs(s.members[id]) do
        local x, y = px(r) - HT + (i - 1) * 6, py(r) + HT
        add('<g class="member"><title>' .. doc.escape(name) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y) .. '" r="4" fill="' .. GROUP
          .. '" stroke="' .. DARK .. '" stroke-width="1.2"/><text x="' .. n(x) .. '" y="' .. n(y + 1.9)
          .. '" font-size="5.4" text-anchor="middle" fill="' .. DARK .. '" font-weight="700">' .. doc.escape(initial(name)) .. "</text></g>")
      end
    end
  end

  -- you: a ring around the tile with a dot in its centre
  local you = s.here ~= nil and s.rooms[s.here] or nil
  if you ~= nil and you.z == sc.z then
    local with = s.members[s.here]
    local title = "You" .. (with and (", with " .. table.concat(with, ", ")) or "")
    add('<g class="you"><title>' .. doc.escape(title) .. '</title><rect x="' .. n(px(you) - HT - 2.6) .. '" y="' .. n(py(you) - HT - 2.6)
      .. '" width="' .. n(T + 5.2) .. '" height="' .. n(T + 5.2) .. '" rx="3.5" fill="none" stroke="' .. YOU .. '" stroke-width="2.4"/>'
      .. '<circle cx="' .. n(px(you)) .. '" cy="' .. n(py(you)) .. '" r="2.8" fill="' .. YOU .. '" stroke="' .. DARK .. '" stroke-width="1.2"/></g>')
  end
  for _, m in ipairs(marks) do add(m) end   -- over the you ring, so it never hides a mark

  return '<svg class="plane" viewBox="' .. n(x0 * U - PAD) .. " " .. n(-y1 * U - PAD) .. " " .. n(w) .. " " .. n(h)
    .. '" preserveAspectRatio="xMidYMid meet" style="max-width:' .. n(w / U * CAP) .. "px;max-height:" .. n(h / U * CAP) .. 'px">'
    .. DEFS .. table.concat(g) .. "</svg>"
end

local function head(s)
  return '<div class="mhead"><span class="marea">' .. doc.escape(s.area) .. "</span>"
    .. (s.region ~= nil and ('<span class="mregion">' .. doc.escape(s.region) .. "</span>") or "") .. "</div>"
end

-- The level bar: ▼ Level n of m ▲, with whoever is on another level by the
-- arrow that leads to them (you too, while Browsing). None on a 1-level Plane.
local function levelBar(s, z)
  local zs = levels(s.rooms)
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
  local you = s.here ~= nil and s.rooms[s.here] or nil
  if you ~= nil and you.z ~= z then
    table.insert(who[you.z > z and "up" or "down"], '<span class="lvyou" title="You: level ' .. nth(you.z) .. ' (back to you)"' .. act("mine") .. "></span>")
  end
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.rooms[id]
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
  if s.state == "unfed" or s.rooms == nil then
    body = live and reason("No map from the server yet. If <code>config map</code> is off, <code>config map on</code> brings it back.")
      or '<div class="mnone">Map</div>'
  elseif s.off then
    body = live and reason("You are not on the map of " .. doc.escape(s.area) .. ".") or '<div class="mnone">Map</div>'
  elseif empty(s.rooms) then
    body = head(s) .. (live and reason(doc.escape(s.area) .. " has no map.") or "")
  else
    local sc = scene(s)
    body = head(s) .. '<div class="mbody">' .. svg(s, sc) .. "</div>" .. levelBar(s, sc.z) .. holds(s)
  end
  return '<div class="hud mapwin" data-state="' .. s.state .. '"' .. doc.fontStyle(font) .. ">" .. body .. "</div>"
end

return M
