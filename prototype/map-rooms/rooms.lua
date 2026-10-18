-- PROTOTYPE, throwaway (wayfinder #31 "What Rooms, Ward shading and labels look like").
-- Look A "Tiles" (lib/map.lua) with Rooms, names, Wards and Leads, at the fixed zoom
-- Following uses (#30/#36), in three variants. The state is lib/map.lua's own (new/map/
-- where); this file only keeps the new keys beside it and draws. Not the lib: no tests.
package.path = "lib/?.lua;" .. package.path
local map = require("map")
local doc = require("doc")

local M = {}

M.VARIANTS = {
  A = { name = "Merged tiles", shape = "merged", ring = "part", ward = "underlay", label = "inside",
    leads = "hover", legend = false, controls = "footer" },
  B = { name = "Plaza blocks", shape = "block", ring = "room", ward = "outline", label = "plaque",
    leads = "tip", legend = true, controls = "footer" },
  C = { name = "District lines", shape = "merged", ring = "part", ward = "border", label = "above",
    leads = "fit", legend = true, controls = "overlay" },
}

-- lib/map.lua's state, plus the keys v0.6.0's copyRoom drops
function M.feed(pkg, where)
  local s = map.new()
  map.live(s)
  map.map(s, pkg)
  if where then map.where(s, where) end
  s.names = pkg.names or {}
  s.wards = pkg.wards or {}
  s.extra = {}
  for id, r in pairs(pkg.rooms or {}) do
    s.extra[tostring(id)] = { room = r.room and tostring(r.room) or nil, ward = r.ward and tostring(r.ward) or nil,
      leads = r.leads or {} }
  end
  return s
end

local U, T = 20, 12
local HT = T / 2
local EDGE = 2.6
local PAD = 18

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
local INSIDE = '<rect x="2.5" y="2.5" width="7" height="7" rx="1" fill="none" ' .. INK .. ' stroke-width="1.1"/>'

-- Ward hues, none of the terrain's: given in the order of the Plane's `wards` ids, so
-- Wards on one Plane never share one (a hash collided at once: drove_end and sumps)
local WARD_HUES = { "#f778ba", "#56d4dd", "#e3b341", "#79c0ff", "#b4f07a", "#d2a8ff" }
function M.wardColour(s, id)
  local ids = {}
  for k in pairs(s.wards) do ids[#ids + 1] = k end
  table.sort(ids)
  for i, k in ipairs(ids) do if k == id then return WARD_HUES[((i - 1) % #WARD_HUES) + 1] end end
  return "#8b949e"
end

local function n(v)
  local s
  if v % 1 == 0 then s = string.format("%d", v)
  else s = (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")) end
  if s == "-0" then s = "0" end
  return s
end
local function px(r) return r.x * U end
local function py(r) return -r.y * U end
local function off(w, d)
  local v = DIRS[w]
  return v[1] * d, -v[2] * d
end
local function sign(v)
  if v > 0 then return 1 elseif v < 0 then return -1 end
  return 0
end
local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end
local function initial(name)
  return name:match("^[%z\1-\127\194-\244][\128-\191]*") or "?"
end
local function line(x1, y1, x2, y2, attrs)
  return '<line x1="' .. n(x1) .. '" y1="' .. n(y1) .. '" x2="' .. n(x2) .. '" y2="' .. n(y2) .. '" ' .. attrs .. "/>"
end

local function roomOf(s, id)
  local e = s.extra[id]
  return (e and e.room) or id
end

-- The Rooms of the level shown: id -> its parts. A Room of 2+ parts that fills its
-- bounding box is a rect; one stepping one diagonal at a time is a band; anything
-- else (never promised) falls back to its parts' tiles.
local function rooms(s, z)
  local by, order = {}, {}
  for _, id in ipairs(sortedKeys(s.rooms)) do
    local r = s.rooms[id]
    if r.z == z then
      local rid = roomOf(s, id)
      if not by[rid] then by[rid] = { id = rid, parts = {} }; order[#order + 1] = rid end
      table.insert(by[rid].parts, id)
    end
  end
  for _, rid in ipairs(order) do
    local R = by[rid]
    if #R.parts > 1 then
      local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
      local cells = {}
      for _, id in ipairs(R.parts) do
        local r = s.rooms[id]
        x0, x1, y0, y1 = math.min(x0, r.x), math.max(x1, r.x), math.min(y0, r.y), math.max(y1, r.y)
        cells[#cells + 1] = r
      end
      R.box = { x0 = x0, x1 = x1, y0 = y0, y1 = y1 }
      if (x1 - x0 + 1) * (y1 - y0 + 1) == #R.parts then
        R.kind = "rect"
      else
        table.sort(cells, function(a, b) return a.x < b.x end)
        local dy = cells[2].y - cells[1].y
        local ok = math.abs(dy) == 1
        for i = 2, #cells do
          if cells[i].x - cells[i - 1].x ~= 1 or cells[i].y - cells[i - 1].y ~= dy then ok = false end
        end
        if ok then R.kind = "band"; R.first = cells[1]; R.last = cells[#cells] else R.kind = "tiles" end
      end
    end
  end
  return by, order
end

-- A Room's outline in SVG units, inflated by `grow`: {rect = {x,y,w,h,rx}} or
-- {band = {cx,cy,len,th,deg}} (the band's own frame: rotate(deg) about its centre).
local function outline(R, v, grow)
  grow = grow or 0
  local m = (v.shape == "block") and 1.5 or (U - T) / 2
  if R.kind == "rect" then
    local b = R.box
    local x, y = b.x0 * U - U / 2 + m, -b.y1 * U - U / 2 + m
    local w, h = (b.x1 - b.x0 + 1) * U - 2 * m, (b.y1 - b.y0 + 1) * U - 2 * m
    return { rect = { x = x - grow, y = y - grow, w = w + 2 * grow, h = h + 2 * grow, rx = 2 + grow } }
  end
  local a, z = R.first, R.last
  local th = (v.shape == "block") and 16 or T
  local dx, dy = (z.x - a.x) * U, -(z.y - a.y) * U
  local len = math.sqrt(dx * dx + dy * dy) + th
  return { band = { cx = (px(a) + px(z)) / 2, cy = (py(a) + py(z)) / 2, len = len + 2 * grow, th = th + 2 * grow,
    deg = math.deg(math.atan2(dy, dx)), rx = 2 + grow } }
end

local function shapeMarkup(o, attrs)
  if o.rect then
    local r = o.rect
    return '<rect x="' .. n(r.x) .. '" y="' .. n(r.y) .. '" width="' .. n(r.w) .. '" height="' .. n(r.h) .. '" rx="' .. n(r.rx) .. '" ' .. attrs .. "/>"
  end
  local b = o.band
  return '<rect transform="translate(' .. n(b.cx) .. " " .. n(b.cy) .. ") rotate(" .. n(b.deg) .. ')" x="' .. n(-b.len / 2) .. '" y="' .. n(-b.th / 2)
    .. '" width="' .. n(b.len) .. '" height="' .. n(b.th) .. '" rx="' .. n(b.rx) .. '" ' .. attrs .. "/>"
end

-- An axis-aligned box around a shape, for label collisions
local function bbox(o)
  if o.rect then return { o.rect.x, o.rect.y, o.rect.x + o.rect.w, o.rect.y + o.rect.h } end
  local b = o.band
  local r = (b.len / 2) * 0.7071 + (b.th / 2) * 0.7071
  return { b.cx - r, b.cy - r, b.cx + r, b.cy + r }
end
local function hits(a, b)
  return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end
local function textW(s, fs) return #s * fs * 0.55 end

local STAIR = { [true] = "stairs", leaves = "leaves this map", unexplored = "unexplored" }

-- A Cell's tooltip: its Room's name, its Ward, then what v0.6.0 says, with each Lead
local function tip(s, id, o)
  local r = s.rooms[id]
  local e = s.extra[id] or { leads = {} }
  local t = {}
  local nm = s.names[roomOf(s, id)]
  if nm then t[#t + 1] = nm end
  if e.ward then t[#t + 1] = (s.wards[e.ward] or e.ward) end
  t[#t + 1] = r.terrain or "no terrain"
  if o.up then t[#t + 1] = "up: " .. ((e.leads.up and ("to " .. e.leads.up)) or STAIR[o.up]) end
  if o.down then t[#t + 1] = "down: " .. ((e.leads.down and ("to " .. e.leads.down)) or STAIR[o.down]) end
  for _, w in ipairs(sortedKeys(r.doors)) do
    t[#t + 1] = w .. ": " .. r.doors[w].name .. (r.doors[w].closed and " (closed)" or " (open)")
  end
  for _, w in ipairs(r.leaves) do
    if w ~= "up" and w ~= "down" then
      t[#t + 1] = e.leads[w] and (w .. ": to " .. e.leads[w]) or (w .. " leaves this map")
    end
  end
  for _, w in ipairs(r.unexplored) do
    if w ~= "up" and w ~= "down" then t[#t + 1] = w .. ": unexplored" end
  end
  if r.back ~= nil then t[#t + 1] = r.back .. " leads back out" end
  return table.concat(t, "\n")
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
local function tri(cx, cy, dir, how)
  local d = "M" .. n(cx - 3.6) .. " " .. n(cy + 2.6 * dir) .. "L" .. n(cx) .. " " .. n(cy - 3 * dir)
    .. "L" .. n(cx + 3.6) .. " " .. n(cy + 2.6 * dir) .. "z"
  local title = "<title>" .. (dir == 1 and "up: " or "down: ") .. STAIR[how] .. "</title>"
  if how == true then return '<path class="stair" d="' .. d .. '" fill="#fff" ' .. SD .. ">" .. title .. "</path>" end
  return '<path class="stair" d="' .. d .. '" fill="' .. DARK .. '" stroke="#fff" stroke-width="1.2" stroke-linejoin="round"'
    .. (how == "unexplored" and ' stroke-dasharray="1.6 1"' or "") .. ">" .. title .. "</path>"
end

local HALO = 'stroke="' .. DARK .. '" stroke-width="1.8" stroke-linejoin="round" paint-order="stroke"'

-- The level shown as SVG, plus what the page script needs to lay it out.
function M.svg(s, v)
  local z = map.shown(s)
  local R, order = rooms(s, z)
  local info = { dropped = {}, labels = 0, leadLabels = 0 }
  -- the same scene lib/map.lua works out, with each Room's parts kept together
  local cellsO, edges, stubs, seen = {}, {}, {}, {}
  for _, id in ipairs(sortedKeys(s.rooms)) do
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
            local inside = roomOf(s, id) == roomOf(s, tid) and #R[roomOf(s, id)].parts > 1
            if seen[k] then
              if door ~= nil and seen[k].door == nil then seen[k].door = door end
            else
              seen[k] = { a = r, b = t, word = w, door = door, inside = inside,
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
          elseif DIRS[w] then stubs[#stubs + 1] = { id = id, r = r, word = w, kind = kind, door = r.doors[w] }
          else o.odd[#o.odd + 1] = { word = w, kind = kind } end
        end
      end
      if r.back ~= nil then
        if DIRS[r.back] then stubs[#stubs + 1] = { id = id, r = r, word = r.back, kind = "back", door = r.doors[r.back] }
        else o.odd[#o.odd + 1] = { word = r.back, kind = "back" } end
      end
      cellsO[id] = o
    end
  end

  local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
  for _, r in pairs(s.rooms) do
    x0, x1 = math.min(x0, r.x), math.max(x1, r.x)
    y0, y1 = math.min(y0, r.y), math.max(y1, r.y)
  end
  local g = {}
  local function add(p) g[#g + 1] = p end
  local boxes = {}      -- what labels must not cover (C)
  local labelBoxes = {}

  -- Ward shading under everything: A an underlay of whole cells, C the same faint plus
  -- a dashed line round each Ward; B outlines each shape (drawn with the shape)
  if v.ward == "underlay" or v.ward == "border" then
    local paths, lines = {}, {}
    for _, id in ipairs(sortedKeys(cellsO)) do
      local e = s.extra[id]
      if e and e.ward then
        local r = s.rooms[id]
        local x, y = px(r) - U / 2, py(r) - U / 2
        paths[e.ward] = (paths[e.ward] or "") .. "M" .. n(x) .. " " .. n(y) .. "h" .. U .. "v" .. U .. "h-" .. U .. "z"
        if v.ward == "border" then
          local function wardAt(dx, dy)
            for oid, o in pairs(cellsO) do
              if o.r.x == r.x + dx and o.r.y == r.y + dy then return (s.extra[oid] or {}).ward end
            end
          end
          local I = 1.4
          local sides = {
            { 0, 1, x + I, y + I, x + U - I, y + I }, { 0, -1, x + I, y + U - I, x + U - I, y + U - I },
            { -1, 0, x + I, y + I, x + I, y + U - I }, { 1, 0, x + U - I, y + I, x + U - I, y + U - I },
          }
          for _, sd in ipairs(sides) do
            if wardAt(sd[1], sd[2]) ~= e.ward then
              lines[e.ward] = (lines[e.ward] or "") .. "M" .. n(sd[3]) .. " " .. n(sd[4]) .. "L" .. n(sd[5]) .. " " .. n(sd[6])
            end
          end
        end
      end
    end
    for _, w in ipairs(sortedKeys(paths)) do
      add('<path class="ward" d="' .. paths[w] .. '" fill="' .. M.wardColour(s, w) .. '" fill-opacity="' .. (v.ward == "underlay" and ".26" or ".1") .. '"/>')
    end
    for _, w in ipairs(sortedKeys(lines)) do
      add('<path class="wardline" d="' .. lines[w] .. '" fill="none" stroke="' .. M.wardColour(s, w) .. '" stroke-width="1.1" stroke-dasharray="3 2" stroke-opacity=".85"/>')
    end
  end

  for _, e in ipairs(edges) do
    if not e.inside then
      add(line(px(e.a), py(e.a), px(e.b), py(e.b), 'stroke="' .. LINE .. '" stroke-width="' .. EDGE .. '"'
        .. (e.far and ' stroke-dasharray="3 2"' or "")))
    end
  end

  local leadLabels = {}
  for _, st in ipairs(stubs) do
    local x, y = px(st.r), py(st.r)
    local ax, ay = off(st.word, HT)
    local bx, by = off(st.word, U * 0.6)
    local col = st.kind == "back" and BACK or LINE
    local attrs = 'stroke="' .. col .. '" stroke-width="' .. EDGE .. '"'
    if st.kind == "unexplored" then attrs = attrs .. ' stroke-dasharray="2 1.6"'
    else attrs = attrs .. ' marker-end="url(#' .. (st.kind == "back" and "aB" or "aA") .. ')"' end
    local stubBox
    do
      local tx, ty = off(st.word, U * 0.6 + 3)
      stubBox = { math.min(x + ax, x + tx) - 3, math.min(y + ay, y + ty) - 3, math.max(x + ax, x + tx) + 3, math.max(y + ay, y + ty) + 3 }
      boxes[#boxes + 1] = stubBox
    end
    local lead = st.kind == "leaves" and (s.extra[st.id] or { leads = {} }).leads[st.word] or nil
    if lead then
      add('<line x1="' .. n(x + ax) .. '" y1="' .. n(y + ay) .. '" x2="' .. n(x + bx) .. '" y2="' .. n(y + by) .. '" ' .. attrs
        .. "><title>" .. doc.escape(st.word .. ": to " .. lead) .. "</title></line>")
      local d = DIRS[st.word]
      local tx, ty = off(st.word, U * 0.6 + 3.2)
      leadLabels[#leadLabels + 1] = { text = lead, x = x + tx, y = y + ty, dx = d[1], dy = -d[2], own = { stubBox } }
    else
      add(line(x + ax, y + ay, x + bx, y + by, attrs))
    end
    if st.kind == "unexplored" then
      local qx, qy = off(st.word, U * 0.6 + 3)
      add('<g><title>' .. doc.escape(st.word) .. ': unexplored</title><circle cx="' .. n(x + qx) .. '" cy="' .. n(y + qy)
        .. '" r="3.4" fill="' .. DARK .. '" stroke="#e6edf3" stroke-width="1"/><text x="' .. n(x + qx) .. '" y="' .. n(y + qy + 2)
        .. '" font-size="5.4" font-weight="700" text-anchor="middle" fill="#e6edf3">?</text></g>')
    end
  end

  -- Rooms: one shape each; a Room of one Cell is exactly v0.6.0's tile
  local marks, roomLabels = {}, {}
  local function terrainOf(Rm) return s.rooms[s.rooms[Rm.id] and Rm.id or Rm.parts[1]].terrain end
  for _, rid in ipairs(order) do
    local Rm = R[rid]
    if #Rm.parts == 1 or Rm.kind == "tiles" then
      for _, id in ipairs(Rm.parts) do
        local o = cellsO[id]
        local r = o.r
        local x, y = px(r) - HT, py(r) - HT
        local e = s.extra[id]
        if v.ward == "outline" and e and e.ward then
          add('<rect x="' .. n(x - 1.6) .. '" y="' .. n(y - 1.6) .. '" width="' .. n(T + 3.2) .. '" height="' .. n(T + 3.2) .. '" rx="3.6" fill="' .. M.wardColour(s, e.ward) .. '"/>')
        end
        add('<g class="room" transform="translate(' .. n(x) .. " " .. n(y) .. ')"><title>' .. doc.escape(tip(s, id, o)) .. "</title>"
          .. '<rect width="' .. T .. '" height="' .. T .. '" rx="2" fill="' .. (TERRAIN[r.terrain] or NONE) .. '"'
          .. (TERRAIN[r.terrain] and "" or ' stroke="#6e7681" stroke-width=".8"') .. "/>")
        if r.terrain == "inside" then add(INSIDE)
        elseif PAT[r.terrain] then add('<rect width="' .. T .. '" height="' .. T .. '" rx="2" fill="url(#pA-' .. r.terrain .. ')"/>') end
        add("</g>")
        boxes[#boxes + 1] = { x, y, x + T, y + T }
      end
    else
      local terr = terrainOf(Rm)
      local o = outline(Rm, v)
      local ward = (s.extra[Rm.parts[1]] or {}).ward
      if v.ward == "outline" and ward then add(shapeMarkup(outline(Rm, v, 1.6), 'fill="' .. M.wardColour(s, ward) .. '"')) end
      -- the shape, its texture in its own frame so it runs along it
      local fr, w, h
      if o.rect then
        fr = 'translate(' .. n(o.rect.x) .. " " .. n(o.rect.y) .. ')'; w, h = o.rect.w, o.rect.h
      else
        local b = o.band
        fr = 'translate(' .. n(b.cx) .. " " .. n(b.cy) .. ") rotate(" .. n(b.deg) .. ") translate(" .. n(-b.len / 2) .. " " .. n(-b.th / 2) .. ")"
        w, h = b.len, b.th
      end
      add('<g class="room multi" transform="' .. fr .. '"><rect width="' .. n(w) .. '" height="' .. n(h) .. '" rx="2" fill="' .. (TERRAIN[terr] or NONE) .. '"'
        .. (TERRAIN[terr] and "" or ' stroke="#6e7681" stroke-width=".8"') .. "/>")
      if terr == "inside" then
        add('<rect x="2.5" y="2.5" width="' .. n(w - 5) .. '" height="' .. n(h - 5) .. '" rx="1" fill="none" ' .. INK .. ' stroke-width="1.1"/>')
      elseif PAT[terr] then
        add('<rect width="' .. n(w) .. '" height="' .. n(h) .. '" rx="2" fill="url(#pA-' .. terr .. ')"/>')
      end
      -- each part keeps its own tooltip: an unpainted hit area over its share of the shape
      for i, id in ipairs(Rm.parts) do
        local r = s.rooms[id]
        local hx, hy, hw, hh
        if o.rect then
          hx, hy = math.max(px(r) - U / 2, o.rect.x) - o.rect.x, math.max(py(r) - U / 2, o.rect.y) - o.rect.y
          hw = math.min(px(r) + U / 2, o.rect.x + o.rect.w) - o.rect.x - hx
          hh = math.min(py(r) + U / 2, o.rect.y + o.rect.h) - o.rect.y - hy
        else
          local dx, dy = px(r) - px(Rm.first), py(r) - py(Rm.first)
          local along = math.sqrt(dx * dx + dy * dy)
          local seg = U * 1.4142
          hx = along + h / 2 - seg / 2; hw = seg; hy = 0; hh = h
          if i == 1 then hw = hw + hx; hx = 0 end
          if hx + hw > w then hw = w - hx end
          if i == #Rm.parts then hw = w - hx end
        end
        add('<rect x="' .. n(hx) .. '" y="' .. n(hy) .. '" width="' .. n(hw) .. '" height="' .. n(hh) .. '" fill="#000" fill-opacity="0"><title>'
          .. doc.escape(tip(s, id, cellsO[id])) .. "</title></rect>")
      end
      add("</g>")
      local own = bbox(o)
      boxes[#boxes + 1] = own
      local nm = s.names[rid]
      if nm then roomLabels[#roomLabels + 1] = { R = Rm, o = o, text = nm, box = own } end
    end
  end

  -- marks on each Cell's own tile corners, as v0.6.0
  for _, id in ipairs(sortedKeys(cellsO)) do
    local o = cellsO[id]
    local r = o.r
    local x, y = px(r) - HT, py(r) - HT
    local e = s.extra[id] or { leads = {} }
    local markL, markR = { x - 4, y - 4, x + 4, y + 4 }, { x + T - 4, y - 3, x + T + 4, y + T + 3 }
    if #o.odd > 0 then boxes[#boxes + 1] = markL end
    if o.up or o.down then boxes[#boxes + 1] = markR end
    if o.up then marks[#marks + 1] = tri(x + T, y + 1.5, 1, o.up) end
    if o.down then marks[#marks + 1] = tri(x + T, y + T - 1.5, -1, o.down) end
    if #o.odd > 0 then
      local words, bk, lead = {}, false, nil
      for i, q in ipairs(o.odd) do
        words[i] = e.leads[q.word] and (q.word .. ": to " .. e.leads[q.word]) or q.word
        lead = lead or e.leads[q.word]
        if q.kind == "back" then bk = true end
      end
      marks[#marks + 1] = '<g class="odd"><title>' .. doc.escape(table.concat(words, ", ")) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y)
        .. '" r="3.6" fill="' .. (bk and BACK or "#fff") .. '" ' .. SD .. '/><path d="M' .. n(x - 1.5) .. " " .. n(y + 1.5) .. "L" .. n(x + 1.6) .. " " .. n(y - 1.6)
        .. "M" .. n(x - 0.6) .. " " .. n(y - 1.6) .. "H" .. n(x + 1.6) .. "V" .. n(y + 0.6) .. '" fill="none" stroke="' .. DARK .. '" stroke-width="1"/></g>'
      if lead then leadLabels[#leadLabels + 1] = { text = lead, x = x - 5, y = y, dx = -1, dy = 0, own = { markL } } end
    end
    for _, w in ipairs({ "up", "down" }) do
      if e.leads[w] and o[w] then
        leadLabels[#leadLabels + 1] = { text = e.leads[w], x = x + T + 5, y = w == "up" and y + 1.5 or y + T - 1.5, dx = 1, dy = 0, own = { markR } }
      end
    end
  end

  -- Room labels, Rooms of 2+ Cells only
  local labels = {}
  for _, L in ipairs(roomLabels) do
    local o = L.o
    if v.label == "inside" then
      local cx, cy, long, short, deg
      if o.rect then
        cx, cy = o.rect.x + o.rect.w / 2, o.rect.y + o.rect.h / 2
        if o.rect.w >= o.rect.h then long, short, deg = o.rect.w, o.rect.h, 0 else long, short, deg = o.rect.h, o.rect.w, -90 end
      else
        cx, cy, long, short, deg = o.band.cx, o.band.cy, o.band.len, o.band.th, o.band.deg
        if deg > 90 or deg < -90 then deg = deg + 180 end
      end
      local placed = false
      for _, fs in ipairs({ 6.4, 5.8, 5.2 }) do
        if textW(L.text, fs) <= long - 4 and fs * 1.1 <= short then
          labels[#labels + 1] = '<text class="rlabel" transform="translate(' .. n(cx) .. " " .. n(cy) .. ") rotate(" .. n(deg) .. ')" y="' .. n(fs * 0.36)
            .. '" font-size="' .. n(fs) .. '" font-weight="600" text-anchor="middle" fill="#fff" ' .. HALO .. ">" .. doc.escape(L.text) .. "</text>"
          placed = true
          break
        end
        -- two lines, when the short side holds them
        local a, b = L.text:match("^(.-[^ ]) (.+)$")
        local sp = {}
        for word in L.text:gmatch("%S+") do sp[#sp + 1] = word end
        if #sp > 1 then
          local half = math.ceil(#sp / 2)
          a = table.concat(sp, " ", 1, half - (#sp > 2 and 0 or 0))
          b = table.concat(sp, " ", half + 1)
          if b == "" then a = table.concat(sp, " ", 1, #sp - 1); b = sp[#sp] end
          if math.max(textW(a, fs), textW(b, fs)) <= long - 4 and fs * 2.3 <= short then
            labels[#labels + 1] = '<text class="rlabel" transform="translate(' .. n(cx) .. " " .. n(cy) .. ") rotate(" .. n(deg) .. ')" font-size="' .. n(fs)
              .. '" font-weight="600" text-anchor="middle" fill="#fff" ' .. HALO .. '><tspan x="0" y="' .. n(-fs * 0.2) .. '">' .. doc.escape(a)
              .. '</tspan><tspan x="0" y="' .. n(fs * 0.95) .. '">' .. doc.escape(b) .. "</tspan></text>"
            placed = true
            break
          end
        end
      end
      if placed then info.labels = info.labels + 1 else info.dropped[#info.dropped + 1] = L.text .. " (does not fit inside)" end
    elseif v.label == "plaque" then
      local cx, cy = o.rect and (o.rect.x + o.rect.w / 2) or o.band.cx, o.rect and (o.rect.y + o.rect.h / 2) or o.band.cy
      local fs = 6.2
      local w, h = textW(L.text, fs) + 4, fs + 3
      local bx = { cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2 }
      local clash = false
      for _, b in ipairs(labelBoxes) do if hits(b, bx) then clash = true end end
      if clash then
        info.dropped[#info.dropped + 1] = L.text .. " (covers another label)"
      else
        labelBoxes[#labelBoxes + 1] = bx
        labels[#labels + 1] = '<g class="rlabel"><rect x="' .. n(bx[1]) .. '" y="' .. n(bx[2]) .. '" width="' .. n(w) .. '" height="' .. n(h)
          .. '" rx="2" fill="' .. DARK .. '" fill-opacity=".82" stroke="#6e7681" stroke-width=".5"/><text x="' .. n(cx) .. '" y="' .. n(cy + fs * 0.36)
          .. '" font-size="' .. n(fs) .. '" font-weight="600" text-anchor="middle" fill="#e6edf3">' .. doc.escape(L.text) .. "</text></g>"
        info.labels = info.labels + 1
      end
    else -- beside: above the shape, else below, right, left; never over a tile, stub, mark or label
      local bb = bbox(o)
      local cx, cy = (bb[1] + bb[3]) / 2, (bb[2] + bb[4]) / 2
      local fs = 6.2
      local w = textW(L.text, fs)
      local tries = {
        { cx, bb[2] - 1.6, "middle", cx - w / 2 }, { cx, bb[4] + fs, "middle", cx - w / 2 },
        { bb[3] + 2, cy + fs * 0.36, "start", bb[3] + 2 }, { bb[1] - 2, cy + fs * 0.36, "end", bb[1] - 2 - w },
      }
      local done = false
      for _, t in ipairs(tries) do
        local bx = { t[4], t[2] - fs, t[4] + w, t[2] + 1 }
        local clash = false
        for _, b in ipairs(labelBoxes) do if hits(b, bx) then clash = true end end
        for _, b in ipairs(boxes) do if b ~= L.box and hits(b, bx) then clash = true end end
        if not clash then
          labelBoxes[#labelBoxes + 1] = bx
          labels[#labels + 1] = '<text class="rlabel" x="' .. n(t[1]) .. '" y="' .. n(t[2]) .. '" font-size="' .. n(fs)
            .. '" font-weight="600" text-anchor="' .. t[3] .. '" fill="#e6edf3" ' .. HALO .. ">" .. doc.escape(L.text) .. "</text>"
          info.labels = info.labels + 1
          done = true
          break
        end
      end
      if not done then info.dropped[#info.dropped + 1] = L.text .. " (no clear side)" end
    end
  end

  -- Lead labels at the stub's tip (B always; C only where they cover no tile or label)
  if v.leads ~= "hover" then
    for _, L in ipairs(leadLabels) do
      local fs = 5.8
      local w = textW(L.text, fs)
      local anchor, bx0 = "middle", L.x - w / 2
      if L.dx > 0 then anchor, bx0 = "start", L.x elseif L.dx < 0 then anchor, bx0 = "end", L.x - w end
      local y = L.y + fs * 0.36
      if L.dx == 0 then y = L.dy < 0 and L.y - 0.5 or L.y + fs end
      local bx = { bx0, y - fs, bx0 + w, y + 1 }
      local clash = false
      if v.leads == "fit" then
        for _, b in ipairs(boxes) do if b ~= L.own[1] and hits(b, bx) then clash = true end end
        for _, b in ipairs(labelBoxes) do if hits(b, bx) then clash = true end end
      end
      if clash then
        info.dropped[#info.dropped + 1] = L.text .. " (lead: covers a tile)"
      else
        labelBoxes[#labelBoxes + 1] = bx
        labels[#labels + 1] = '<text class="lead" x="' .. n(L.x) .. '" y="' .. n(y) .. '" font-size="' .. n(fs) .. '" font-style="italic" text-anchor="' .. anchor
          .. '" fill="#c9d1d9" ' .. HALO .. ">" .. doc.escape(L.text) .. "</text>"
        info.leadLabels = info.leadLabels + 1
      end
    end
  end

  -- labels over the tiles, under the markers (a label hid a member's disc)
  for _, l in ipairs(labels) do add(l) end

  -- doors, as v0.6.0
  local doors = {}
  local function door(a, word, b, d)
    local dv = DIRS[word] or { sign(b.x - a.x), sign(b.y - a.y) }
    local mx, my = px(a) + dv[1] * U / 2, py(a) - dv[2] * U / 2
    local len = math.sqrt(dv[1] * dv[1] + dv[2] * dv[2])
    local nx, ny = -dv[2] / len, -dv[1] / len
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
  for _, e in ipairs(edges) do if e.door ~= nil then door(e.a, e.word, e.b, e.door) end end
  for _, st in ipairs(stubs) do if st.door ~= nil then door(st.r, st.word, nil, st.door) end end

  -- the Group, as v0.6.0
  local members = {}
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.rooms[id]
    if r.z == z then
      for i, name in ipairs(s.members[id]) do
        local x, y = px(r) - HT + (i - 1) * 6, py(r) + HT
        members[#members + 1] = { n = initial(name), name = name, x = px(r), y = py(r) }
        add('<g class="member"><title>' .. doc.escape(name) .. '</title><circle cx="' .. n(x) .. '" cy="' .. n(y) .. '" r="4" fill="' .. GROUP
          .. '" stroke="' .. DARK .. '" stroke-width="1.2"/><text x="' .. n(x) .. '" y="' .. n(y + 1.9)
          .. '" font-size="5.4" text-anchor="middle" fill="' .. DARK .. '" font-weight="700">' .. doc.escape(initial(name)) .. "</text></g>")
      end
    end
  end

  -- you: v0.6.0's ring round the Cell's tile (A, C) or round the whole Room (B)
  local you = s.here ~= nil and s.rooms[s.here] or nil
  local youAt
  if you ~= nil and you.z == z then
    youAt = { px(you), py(you) }
    local with = s.members[s.here]
    local title = "You" .. (with and (", with " .. table.concat(with, ", ")) or "")
    local Rm = R[roomOf(s, s.here)]
    local ring
    if v.ring == "room" and #Rm.parts > 1 and Rm.kind ~= "tiles" then
      ring = shapeMarkup(outline(Rm, v, 2.6), 'fill="none" stroke="' .. YOU .. '" stroke-width="2.4"')
    else
      ring = '<rect x="' .. n(px(you) - HT - 2.6) .. '" y="' .. n(py(you) - HT - 2.6) .. '" width="' .. n(T + 5.2) .. '" height="' .. n(T + 5.2)
        .. '" rx="3.5" fill="none" stroke="' .. YOU .. '" stroke-width="2.4"/>'
    end
    add('<g class="you"><title>' .. doc.escape(title) .. "</title>" .. ring
      .. '<circle cx="' .. n(px(you)) .. '" cy="' .. n(py(you)) .. '" r="2.8" fill="' .. YOU .. '" stroke="' .. DARK .. '" stroke-width="1.2"/></g>')
  end
  for _, d in ipairs(doors) do add(d) end
  for _, m in ipairs(marks) do add(m) end

  -- the frame holds every label too (a lead past the Plane's edge was cut off)
  local fx0, fy0, fx1, fy1 = x0 * U - PAD, -y1 * U - PAD, x1 * U + PAD, -y0 * U + PAD
  for _, b in ipairs(labelBoxes) do
    fx0, fy0, fx1, fy1 = math.min(fx0, b[1] - 3), math.min(fy0, b[2] - 3), math.max(fx1, b[3] + 3), math.max(fy1, b[4] + 3)
  end
  local vb = { fx0, fy0, fx1 - fx0, fy1 - fy0 }
  info.vb, info.you, info.members, info.z = vb, youAt, members, z
  return '<svg id="pl" class="plane" viewBox="' .. n(vb[1]) .. " " .. n(vb[2]) .. " " .. n(vb[3]) .. " " .. n(vb[4]) .. '">'
    .. DEFS .. table.concat(g) .. "</svg>", info
end

-- the header: Area · Region left, Room · Ward right, wrapping only on overrun
local function head(s)
  local right = ""
  local you = s.here ~= nil and not map.browsing(s) and s.rooms[s.here] or nil
  if you then
    local nm = s.names[roomOf(s, s.here)]
    local w = (s.extra[s.here] or {}).ward
    local parts = {}
    if nm then parts[#parts + 1] = '<span class="mroom">' .. doc.escape(nm) .. "</span>" end
    if w then parts[#parts + 1] = '<span class="mward"><i style="background:' .. M.wardColour(s, w) .. '"></i>' .. doc.escape(s.wards[w] or w) .. "</span>" end
    if #parts > 0 then right = '<span class="mright">' .. table.concat(parts, '<span class="msep">&#183;</span>') .. "</span>" end
  end
  return '<div class="mhead"><span class="mleft"><span class="marea">' .. doc.escape(s.area) .. "</span>"
    .. (s.region ~= nil and ('<span class="msep">&#183;</span><span class="mregion">' .. doc.escape(s.region) .. "</span>") or "") .. "</span>" .. right .. "</div>"
end

local function legend(s)
  local ids = sortedKeys(s.wards)
  if #ids == 0 then return "" end
  local used = {}
  for _, id in pairs(s.extra) do if id.ward then used[id.ward] = true end end
  local out = {}
  for _, w in ipairs(ids) do
    local c = M.wardColour(s, w)
    out[#out + 1] = '<span class="lgw' .. (used[w] and "" or " hollow") .. '" title="' .. doc.escape(s.wards[w]) .. (used[w] and "" or ": its own map, through the door that names it")
      .. '"><i style="' .. (used[w] and ("background:" .. c) or ("border-color:" .. c)) .. '"></i>' .. doc.escape(s.wards[w]) .. "</span>"
  end
  return '<div class="mlegend">' .. table.concat(out) .. "</div>"
end

-- the level control, as v0.6.0 (#24), without its bar
local function levels(s, z)
  local zs, seen = {}, {}
  for _, r in pairs(s.rooms) do if not seen[r.z] then seen[r.z] = true; zs[#zs + 1] = r.z end end
  table.sort(zs)
  if #zs < 2 then return "" end
  local at = 1
  for i, v in ipairs(zs) do if v == z then at = i end end
  local function arrow(glyph, title, to)
    return '<span class="lvarrow' .. (to and "" or " off") .. '" title="' .. title .. '">' .. glyph .. "</span>"
  end
  local who = { up = {}, down = {} }
  for _, id in ipairs(sortedKeys(s.members)) do
    local r = s.rooms[id]
    if r.z ~= z then
      for _, name in ipairs(s.members[id]) do
        table.insert(who[r.z > z and "up" or "down"], '<span class="lvmem" title="' .. doc.escape(name) .. '">' .. doc.escape(initial(name)) .. "</span>")
      end
    end
  end
  return '<span class="lvctl">' .. arrow("&#9660;", "Level below", zs[at - 1]) .. table.concat(who.down)
    .. '<span class="lvmid">Level ' .. at .. " of " .. #zs .. "</span>" .. table.concat(who.up) .. arrow("&#9650;", "Level above", zs[at + 1]) .. "</span>"
end

local ZCTL = '<span class="zctl"><span class="zb" id="zm" title="Zoom out">&#8722;</span><span class="zb" id="zp" title="Zoom in">+</span>'
  .. '<span class="zb" id="me" title="Centre on me">&#9678;</span></span>'

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

local function json(v)
  if type(v) == "table" then
    if #v > 0 or next(v) == nil then
      local o = {}
      for i, x in ipairs(v) do o[i] = json(x) end
      return "[" .. table.concat(o, ",") .. "]"
    end
    local o = {}
    for _, k in ipairs(sortedKeys(v)) do o[#o + 1] = string.format("%q", k) .. ":" .. json(v[k]) end
    return "{" .. table.concat(o, ",") .. "}"
  elseif type(v) == "string" then return string.format("%q", v)
  elseif v == nil then return "null" end
  return tostring(v)
end

M.STYLE = [[
.mhead{display:flex;flex-wrap:wrap;align-items:baseline;column-gap:1em;row-gap:0;border-bottom:1px solid #30363d;padding:0 2px 3px;flex-shrink:0;min-width:0}
.mleft,.mright{display:flex;align-items:baseline;gap:.4em;min-width:0;max-width:100%;white-space:nowrap}
.mright{margin-left:auto;color:#c9d1d9}
.mleft>*,.mright>*{overflow:hidden;text-overflow:ellipsis;min-width:0}
.msep{color:#6e7681;flex:none}
.mroom{color:#e6edf3}
.mward{color:#8b949e;font-size:.92em}
.mward i{display:inline-block;width:.6em;height:.6em;border-radius:2px;margin-right:.3em;vertical-align:baseline}
.mvp{flex:1;min-height:0;position:relative;overflow:hidden;cursor:grab;touch-action:none}
.mvp.drag{cursor:grabbing}
.mvp .plane{position:absolute;left:0;top:0;display:block;user-select:none;-webkit-user-drag:none;margin:0;max-width:none;max-height:none}
.pip{position:absolute;width:1.3em;height:1.3em;margin:-.65em 0 0 -.65em;border-radius:50%;background:#ff7b72;color:#0d1117;font-weight:700;font-size:.8em;display:flex;align-items:center;justify-content:center;box-shadow:0 0 0 1.5px #0d1117;pointer-events:auto;cursor:default}
.pip::after{content:"";position:absolute;width:0;height:0;border:4px solid transparent;left:50%;top:50%;margin:-4px;transform:rotate(var(--a)) translateX(10px);border-left:5px solid #ff7b72}
.mlegend{display:flex;flex-wrap:wrap;column-gap:.9em;row-gap:1px;font-size:.86em;color:#8b949e;padding:0 2px;flex-shrink:0}
.lgw{white-space:nowrap}
.lgw i{display:inline-block;width:.75em;height:.75em;border-radius:2px;margin-right:.3em;vertical-align:-.05em;border:1.5px solid transparent}
.lgw.hollow{font-style:italic}
.lgw.hollow i{background:transparent}
.mfoot{display:flex;align-items:center;gap:.5em;border-top:1px solid #30363d;padding:3px 34px 0 0;font-size:.92em;color:#8b949e;flex-shrink:0}
.zctl{display:flex;gap:3px;flex:none}
.zb,.lvarrow{flex:none;cursor:pointer;user-select:none;background:#161b22;color:#c9d1d9;border:1px solid #30363d;border-radius:3px;line-height:1.2;padding:0 6px;text-align:center;min-width:1.6em}
.zb:hover,.lvarrow:hover{border-color:#8b949e;color:#fff}
.lvarrow.off{opacity:.3;cursor:default}
.lvctl{display:flex;align-items:center;gap:3px;margin-left:auto}
.lvmid{flex:none;padding:0 .4em;white-space:nowrap}
.lvmem{display:inline-flex;align-items:center;justify-content:center;width:1.25em;height:1.25em;border-radius:50%;background:#ff7b72;color:#0d1117;font-weight:700;font-size:.82em;flex:none}
.zover{position:absolute;right:4px;top:4px;display:flex;flex-direction:column;gap:3px;z-index:2}
.zover .zctl{flex-direction:column}
.zover .zb{background:#161b22e6;padding:0;width:1.7em;line-height:1.5}
]]

-- The page script: Following at a fixed zoom (#35's (A)), drag, wheel, ± and centre-on-me,
-- and an edge pip for each member out of view. In MudForge it reports the view to Lua;
-- here it keeps it in the page.
M.SCRIPT = [==[
(function(){var vp=document.getElementById('vp'),pl=document.getElementById('pl'),pips=document.getElementById('pips');
var Z=[20,24,28,34,40,48,56];
function k(){return S.zoom/20}
function axis(view,size,origin,a){if(size<=view)return (view-size)/2;var t=view/2-(a-origin)*k();return Math.min(0,Math.max(view-size,t))}
function clampPan(){var W=vp.clientWidth,H=vp.clientHeight,pw=S.vb[2]*k(),ph=S.vb[3]*k();
 [[0,W,pw],[1,H,ph]].forEach(function(a){var i=a[0],view=a[1],size=a[2];if(size<=view){S.pan[i]=0;return}
  var lo=S.vb[i]+view/2/k(),hi=S.vb[i]+S.vb[i+2]-view/2/k(),p=S.here[i]+S.pan[i];S.pan[i]=Math.min(hi,Math.max(lo,p))-S.here[i]})}
function layout(){var W=vp.clientWidth,H=vp.clientHeight,pw=S.vb[2]*k(),ph=S.vb[3]*k();
 pl.style.width=pw+'px';pl.style.height=ph+'px';
 var tx=Math.round(axis(W,pw,S.vb[0],S.here[0]+S.pan[0])),ty=Math.round(axis(H,ph,S.vb[1],S.here[1]+S.pan[1]));
 pl.style.transform='translate('+tx+'px,'+ty+'px)';
 var h='';S.members.forEach(function(m){var x=tx+(m.x-S.vb[0])*k(),y=ty+(m.y-S.vb[1])*k(),M=12;
  if(x>=M&&x<=W-M&&y>=M&&y<=H-M)return;var cx=W/2,cy=H/2,dx=x-cx,dy=y-cy,
  s=Math.min((W/2-M)/Math.abs(dx||1e-9),(H/2-M)/Math.abs(dy||1e-9));
  h+='<span class="pip" title="'+m.name+' (off the view)" style="left:'+(cx+dx*s)+'px;top:'+(cy+dy*s)+'px;--a:'+Math.atan2(dy,dx)+'rad">'+m.n+'</span>'});
 pips.innerHTML=h}
function zoomBy(d){var i=Z.indexOf(S.zoom)+d;if(i<0||i>=Z.length)return;S.zoom=Z[i];clampPan();layout()}
var drag=null;
vp.addEventListener('dragstart',function(e){e.preventDefault()});
vp.addEventListener('pointerdown',function(e){if(e.button!==0||e.target.closest('.zb'))return;e.preventDefault();drag={x:e.clientX,y:e.clientY,p:S.pan.slice()};try{vp.setPointerCapture(e.pointerId)}catch(_){}vp.classList.add('drag')});
vp.addEventListener('pointermove',function(e){if(!drag)return;S.pan=[drag.p[0]-(e.clientX-drag.x)/k(),drag.p[1]-(e.clientY-drag.y)/k()];clampPan();layout()});
function end(){drag=null;vp.classList.remove('drag')}
vp.addEventListener('pointerup',end);vp.addEventListener('pointercancel',end);
vp.addEventListener('wheel',function(e){e.preventDefault();zoomBy(e.deltaY<0?1:-1)},{passive:false});
document.getElementById('zm').onclick=function(){zoomBy(-1)};document.getElementById('zp').onclick=function(){zoomBy(1)};
document.getElementById('me').onclick=function(){S.pan=[0,0];layout()};
addEventListener('resize',function(){clampPan();layout()});
if(!S.here)S.here=[S.vb[0]+S.vb[2]/2,S.vb[1]+S.vb[3]/2];
layout()})();
]==]

-- The widget's whole content in variant v
function M.html(s, v)
  local plane, info = M.svg(s, v)
  local z = info.z
  local lv = levels(s, z)
  local foot, over = "", ""
  if v.controls == "footer" then
    foot = '<div class="mfoot">' .. ZCTL .. lv .. "</div>"
  else
    over = '<div class="zover">' .. ZCTL .. "</div>"
    if lv ~= "" then foot = '<div class="mfoot">' .. lv .. "</div>" end
  end
  local S = { zoom = 34, pan = { 0, 0 }, vb = info.vb, here = info.you, members = {} }
  for _, m in ipairs(info.members) do
    if not (info.you and m.x == info.you[1] and m.y == info.you[2]) then S.members[#S.members + 1] = m end
  end
  local body = head(s) .. '<div class="mvp" id="vp">' .. plane .. '<div id="pips"></div>' .. over .. "</div>"
    .. (v.legend and legend(s) or "") .. foot .. holds(s)
  return '<div class="hud mapwin" data-state="live">' .. body .. "</div><script>var S=" .. json(S) .. ";" .. M.SCRIPT .. "</script>", info
end

return M
