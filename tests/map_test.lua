local map = require("map")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": " .. part .. " not in " .. s)
end

local function lacks(s, part, label)
  assert(not s:find(part, 1, true), label .. ": " .. part .. " in " .. s)
end

local function count(s, part)
  local n, at = 0, 1
  while true do
    local i = s:find(part, at, true)
    if i == nil then return n end
    n, at = n + 1, i + #part
  end
end

local function fixture(name)
  return dofile("tests/fixtures/map/" .. name .. ".lua")
end

local function sortedKeysOf(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

-- Replays a captured sequence's Area.Map and Area.Where into s, in order.
local function replay(s, name)
  for _, e in ipairs(fixture(name)) do
    if e.pkg == "Area.Map" then map.map(s, e.data)
    elseif e.pkg == "Area.Where" then map.where(s, e.data) end
  end
  return s
end

-- ===== The state model (wayfinder #20) =====

-- Unfed: the skeleton, no reason line, nothing to click
local s = map.new()
eq(s.state, "unfed", "new is unfed")
local h = map.html(s)
has(h, 'data-state="unfed"', "unfed state")
lacks(h, "<svg", "unfed draws no plane")
lacks(h, "config map", "unfed shows no reason")
lacks(h, "data-mud-action", "unfed has no controls")

-- Live with no Area.Map yet: the first No-plane reason
map.live(s)
h = map.html(s)
has(h, 'data-state="live"', "live")
has(h, "No map from the server yet.", "no Area.Map this connection")
has(h, "<code>config map on</code>", "how to turn it on")

-- A Plane arrives (login): Live, drawn, the player on it once Area.Where places them
s = map.new()
replay(s, "seq_login")
eq(s.state, "live", "a plane makes it live")
eq(s.area, "Stubbing", "the plane's Area")
eq(s.here, "1285", "placed")
eq(map.shown(s), 0, "the player's level")

-- A step inside one Area moves only the marker
replay(s, "seq_step")
eq(s.here, "1286", "stepped")

-- Entering a new Area: Room.Info, Area.Map, Area.Where in one burst
s = map.new()
replay(s, "seq_enter_area")
eq(s.area, "Stubbing", "entered")
eq(s.here, "1285", "placed in the new Area")

-- A new Plane before its position: no player marker, level 0, no reason
s = map.new()
map.map(s, fixture("plane_gildhythe"))
map.where(s, { here = "247", members = {} })
map.map(s, fixture("plane_stubbing"))
eq(s.here, nil, "a new Area hides the player until Area.Where places them")
eq(map.shown(s), 0, "level 0 with no position")
h = map.html(s)
has(h, "<svg", "drawn")
lacks(h, 'class="you"', "no you marker")
lacks(h, "not on the map", "no reason")

-- With no position and no level 0, the lowest level is shown
s = map.new()
map.map(s, { area = "Up High", rooms = { a = { x = 0, y = 0, z = 2 }, b = { x = 0, y = 0, z = 1 }, c = { x = 1, y = 0, z = 3 } } })
eq(map.shown(s), 1, "the lowest level when there is no level 0")

-- Held position: an Area.Where whose here is not on the Plane yet waits for it
s = map.new()
map.map(s, fixture("plane_spitcut_door_closed"))
map.where(s, { here = "d12", members = {} })
map.where(s, { here = "d13", members = {} })
eq(s.here, "d12", "a held position never moves the marker")
map.where(s, { here = "d14", members = {} })
map.map(s, fixture("plane_stoppervaults"))
eq(s.here, nil, "only the newest is held: d13 was replaced by d14")
map.where(s, { here = "d13", members = {} })
eq(s.here, "d13", "placed once its room is on the Plane")
s = map.new()
map.map(s, fixture("plane_spitcut_door_closed"))
map.where(s, { here = "d13", members = {} })
map.map(s, fixture("plane_stoppervaults"))
eq(s.here, "d13", "a held position is applied when its Plane arrives")
eq(s.held, nil, "and is no longer held")

-- The Expedition crossing and back, in arrival order
s = map.new()
map.map(s, fixture("plane_spitcut_door_closed"))
replay(s, "seq_expedition_cross")
eq(s.area, "the Spit Cut", "back in the Spit Cut")
eq(s.here, "d12", "at the vault door")

-- A Delve growing is just a new Plane each time
s = map.new()
replay(s, "seq_delve_grow")
eq(s.here, "d4", "walked in")
eq(s.cells.d4 ~= nil, true, "the grown plane")

-- A Depth descent is just a new Plane: the old Depth's rooms are gone
s = map.new()
replay(s, "seq_depth_descend")
eq(s.area, "the Lees, Depth 2", "descended")
eq(s.here, "d13", "placed on Depth 2")
eq(s.cells.d12, nil, "Depth 1 dropped")

-- A door opening re-sends the Plane alone; the player stays where they are
s = map.new()
replay(s, "seq_door_opened")
eq(s.here, "d11", "still at the windlass")
eq(s.cells.d12.doors.north.closed, false, "the vault door is open")

-- config map off/on: the re-send changes nothing that matters
s = map.new()
replay(s, "seq_map_off_on")
eq(s.here, "405", "walked on after config map on")

-- Group: a room maps to sorted names; a member off the Plane is dropped
s = map.new()
map.map(s, fixture("plane_gildhythe"))
map.where(s, { here = "249", members = { Rei = "247", Ana = "247", Zed = "999" } })
eq(#s.members["247"], 2, "two members in one room")
eq(s.members["247"][1], "Ana", "sorted")
eq(s.members["999"], nil, "a member off the Plane is dropped")
replay(s, "seq_group")
eq(s.here, "249", "group sequence ends in 249")
eq(s.members["247"][1], "Rei", "Rei in 247")

-- No-plane reason: an Area with no cells; the header still names it
s = map.new()
map.map(s, { area = "the Hand-Laid Hall", region = "Nowhere", rooms = {} })
h = map.html(s)
has(h, "the Hand-Laid Hall has no map.", "no cells")
has(h, "Nowhere", "the header keeps the Region")
lacks(h, "<svg", "nothing drawn")

-- No-plane reason: the player off the Plane hides the old Plane
s = map.new()
map.map(s, fixture("plane_stubbing"))
map.where(s, { here = "1285", members = {} })
map.where(s, { members = {} })
h = map.html(s)
has(h, "You are not on the map of Stubbing.", "off the plane")
lacks(h, "<svg", "the old plane is hidden")
map.where(s, { here = "1285", members = {} })
has(map.html(s), "<svg", "back on it")
map.where(s, { members = {} })
map.map(s, fixture("plane_gildhythe"))
lacks(map.html(s), "not on the map", "a new Area's Plane clears it")

-- Severed: the last Plane and markers frozen, no reason line
s = map.new()
replay(s, "seq_login")
map.sever(s)
eq(s.state, "severed", "severed")
h = map.html(s)
has(h, 'data-state="severed"', "severed state")
has(h, 'class="you"', "the marker stays")
s = map.new()
map.live(s)
map.sever(s)
lacks(map.html(s), "config map", "a Severed window shows no reason")
s = map.new()
map.sever(s)
eq(s.state, "unfed", "an Unfed window does not sever")

-- ===== Browsing (wayfinder #20, #24) =====

s = map.new()
map.map(s, fixture("plane_stubbing"))
map.where(s, { here = "1285", members = {} })
eq(map.shown(s), 0, "your level")
eq(map.act(s, "level", "z1"), nil, "a level click sends nothing")
eq(map.shown(s), 1, "browsing level 1")
eq(map.browsing(s), true, "browsing")
map.where(s, { here = "1285", members = { Rei = "1286" } })
eq(map.shown(s), 1, "a member moving leaves it alone")
map.map(s, fixture("plane_stubbing"))
eq(map.shown(s), 1, "a re-send for the same Area leaves it alone")
map.where(s, { here = "1286", members = {} })
eq(map.shown(s), 0, "moving ends it")
map.act(s, "level", "z1")
map.act(s, "level", "mine")
eq(map.browsing(s), false, "mine ends it")
map.act(s, "level", "z1")
map.act(s, "level", "z0")
eq(map.browsing(s), false, "asking for your own level is not Browsing")
map.act(s, "level", "z7")
eq(map.browsing(s), false, "no such level")
map.act(s, "level", "z1")
map.act(s, "level", 0)
eq(map.shown(s), 1, "a bare level number is not a level click: clicks carry z<n>")
map.act(s, "level", "mine")
map.act(s, "level", "z1")
map.map(s, fixture("plane_gildhythe"))
eq(map.browsing(s), false, "a new Area ends it")
map.where(s, { here = "247", members = {} })
map.act(s, "level", "z1")
local flat = fixture("plane_gildhythe")
for id, r in pairs(flat.rooms) do if r.z == 1 then flat.rooms[id] = nil end end
map.map(s, flat)
eq(map.browsing(s), false, "the browsed level gone ends it")

-- Browsing with no position yet: the default level is the base
s = map.new()
map.map(s, fixture("plane_stubbing"))
map.act(s, "level", "z1")
eq(map.shown(s), 1, "browse before placed")
map.act(s, "level", "z0")
eq(map.browsing(s), false, "back to the default level")

-- ===== The drawing: look A, "Tiles" (wayfinder #23), Fit (#22), level bar (#24) =====

-- Header: the Area and Region on the left; the font is the widget's own
s = map.new()
map.map(s, fixture("plane_spitcut_door_closed"))
map.where(s, { here = "d12", members = {} })
h = map.html(s, { family = "Fira", size = 14 })
has(h, 'style="font-size:14px;font-family:Fira"', "the widget font")
has(h, '<div class="mhead"><span class="mleft"><span class="marea">the Spit Cut</span><span class="msep">&#183;</span><span class="mregion">the Saffron Fall</span></span></div>', "header: no names, nothing on the right")
lacks(h, "Level 1", "no level text on a 1-level plane")
lacks(h, 'class="mlevel"', "no level bar on a 1-level plane")
lacks(h, 'class="mholds"', "no holds footer when nothing is listed")

-- Fit: the viewBox frames the whole Plane's x/y bounds (x -1..3, y 0..9),
-- padded 18; the cell size is capped at 34px through max sizes
has(h, 'viewBox="-38 -198 116 216"', "fit viewBox")
has(h, 'style="max-width:197.2px;max-height:367.2px"', "cell size cap")

-- Terrain: a field tile with its own texture, in its own translate()
has(h, '<g class="room" transform="translate(54 -186)">', "d12 at (3, 9)")
has(h, 'fill="#6cae4f"', "field colour")
has(h, 'fill="url(#pA-field)"', "field texture")
eq(count(h, '<g class="room"'), 12, "one tile per room")

-- Edges: one line per pair, 2.6 wide; d12's closed door north on its leave stub
eq(count(h, 'stroke="#8b949e" stroke-width="2.6"/>'), 11, "11 edges between 12 rooms")
has(h, "<title>vault door (closed)</title>", "closed door")
has(h, 'stroke="#f0883e" stroke-width="3"', "a closed door is a solid bar")
has(h, 'marker-end="url(#aA)"', "a leave stub has an arrowhead")

-- You: the yellow ring and dot
has(h, '<g class="you"><title>You</title><rect x="51.4" y="-188.6"', "you ring around d12")
assert(h:find('<g class="door">', 1, true) > h:find('<g class="you">', 1, true), "a door is drawn over the you ring")

-- The door opened: two posts
s = map.new()
replay(s, "seq_door_opened")
h = map.html(s)
has(h, "<title>vault door (open)</title>", "open door")
has(h, 'class="door" stroke="#f0883e" stroke-width="2.2"', "an open door is two posts")

-- Unexplored stubs end in a ringed "?"; an inside room has its inner frame
s = map.new()
map.map(s, fixture("plane_stoppervaults"))
h = map.html(s)
eq(count(h, 'stroke-dasharray="2 1.6"'), 3, "three unexplored stubs")
eq(count(h, ">?</text>"), 3, "each with a ringed ?")
has(h, '<rect x="2.5" y="2.5" width="7" height="7"', "inside: a room in a room")
lacks(h, "url(#pA-inside)", "inside has no texture")

-- A Depth: no terrain, stairs that leave the map are hollow
s = map.new()
map.map(s, fixture("plane_lees_depth1"))
h = map.html(s)
has(h, 'fill="#3d444d" stroke="#6e7681"', "no terrain: grey with an outline")
has(h, "<title>up: leaves this map</title>", "up leaves")
has(h, "<title>down: leaves this map</title>", "down leaves")
has(h, 'fill="#0d1117" stroke="#fff"', "hollow")
lacks(h, 'class="mregion"', "a Depth has no Region")
lacks(h, 'class="mlevel"', "a Depth shows no level bar")

-- An unexplored stair is hollow and dashed; back is cyan, by stub or by disc
s = map.new()
map.map(s, { area = "Faked", rooms = {
  a = { x = 0, y = 0, z = 0, terrain = "cave", unexplored = { "down" }, back = "west" },
  b = { x = 1, y = 0, z = 0, terrain = "water", leaves = { "vault" }, back = "out" },
  c = { x = 2, y = 0, z = 0, terrain = "<mud>" },
} })
h = map.html(s)
has(h, 'stroke-dasharray="1.6 1"', "unexplored stair dashed")
has(h, 'marker-end="url(#aB)"', "a back stub has the cyan arrowhead")
has(h, 'stroke="#39c5cf"', "back is cyan")
has(h, "<title>vault, out</title>", "a leave with no compass word is a disc holding its words")
has(h, 'r="3.6" fill="#39c5cf"', "cyan when it is back")
has(h, "west leads back out", "back in the room tooltip")
lacks(h, "<mud>", "an unknown terrain is never trusted into markup")
has(h, "<title>&lt;mud&gt;</title>", "its name in the tooltip, escaped")

-- Stairs on the Plane: solid white marks
s = map.new()
map.map(s, fixture("plane_stubbing"))
map.where(s, { here = "1285", members = {} })
h = map.html(s)
has(h, 'fill="#fff" stroke="#0d1117"', "a stair on the Plane is solid")
has(h, "<title>up: stairs</title>", "up stair")

-- Level bar: ▼ Level n of m ▲, ▼ dimmed at the bottom
has(h, '<div class="mlevel">', "level bar on a 2-level plane")
has(h, '<span class="lvarrow off" title="Level below">&#9660;</span>', "nothing below")
has(h, '<span class="lvarrow" title="Level above" data-mud-action="level" data-mud-data="z1">&#9650;</span>', "up to z 1")
has(h, '<span class="lvmid">Level 1 of 2</span>', "level text")

-- Browsing: cyan middle text, you by the arrow back toward your level
map.act(s, "level", "z1")
h = map.html(s)
has(h, '<span class="lvmid browsing">Level 2 of 2</span>', "browsing text")
has(h, '<span class="lvyou" title="You: level 1 (back to you)" data-mud-action="level" data-mud-data="mine"></span>', "you by the down arrow")
assert(h:find('class="lvyou"', 1, true) < h:find('class="lvmid', 1, true), "you sit at the down end")
lacks(h, '<g class="you">', "no you ring on a level you are not on")

-- The frame holds still while Browsing
local a = map.html(s):match('viewBox="[^"]*"')
map.act(s, "level", "mine")
eq(map.html(s):match('viewBox="[^"]*"'), a, "same frame on both levels")

-- Group: discs on the plane, fanned per room; members elsewhere by the arrow
s = map.new()
map.map(s, fixture("plane_gildhythe"))
local upId
for id, r in pairs(s.cells) do if r.z == 1 then upId = id end end
map.where(s, { here = "249", members = { Rei = "247", Ana = "247", Bo = "249", ["\195\137a"] = upId } })
h = map.html(s)
eq(count(h, '<g class="member">'), 3, "three members on the level shown")
has(h, "<title>You, with Bo</title>", "a member in your room folds into your marker's name")
local ana = h:match('<g class="member"><title>Ana</title><circle cx="([%-%d%.]+)"')
local rei = h:match('<g class="member"><title>Rei</title><circle cx="([%-%d%.]+)"')
eq(tonumber(rei) - tonumber(ana), 6, "fanned right in one room")
has(h, '<span class="lvmem" title="&#201;a: level 2" data-mud-action="level" data-mud-data="z1">&#201;</span>', "a member above, by the up arrow, the initial whole, as an entity")
assert(h:find('class="lvmem"', 1, true) > h:find('class="lvmid', 1, true), "members above sit at the up end")
map.act(s, "level", "z1")
h = map.html(s)
has(h, '<g class="member"><title>&#201;a</title>', "on their level, drawn on the plane")
eq(count(h, 'class="lvmem"'), 3, "the three below sit by the down arrow")

-- holds: a footer with Enemies and Gather
s = map.new()
map.map(s, fixture("plane_bottleshallows"))
h = map.html(s)
has(h, '<div class="mholds"><div><b>Enemies</b> ', "enemies")
has(h, "<b>Gather</b> ", "gather")

-- Fed names are escaped
s = map.new()
map.map(s, { area = "<b>A&B</b>", region = '"R"', rooms = { ["1"] = { x = 0, y = 0, z = 0,
  doors = { north = { name = "<x>", closed = true } }, leaves = { "north" } } },
  holds = { enemies = { "<e>" } } })
map.where(s, { here = "1", members = { ["<M>"] = "1" } })
h = map.html(s)
lacks(h, "<b>A&B</b>", "area escaped")
has(h, "&lt;b&gt;A&amp;B&lt;/b&gt;", "area")
has(h, "&quot;R&quot;", "region")
has(h, "&lt;x&gt; (closed)", "door name")
has(h, "&lt;e&gt;", "holds")
has(h, "You, with &lt;M&gt;", "member name")

-- Output is stable: the same state draws the same markup
s = map.new()
map.map(s, fixture("plane_mereroad"))
eq(map.html(s), map.html(s), "stable")

-- ===== Rooms, names and Wards fixtures (wayfinder #29) =====

-- Every plane with the new keys, captured or synthetic, is taken and drawn
for _, name in ipairs({ "plane_gildhythe_named", "plane_greenroad_named", "plane_tallyglass_named",
  "plane_glassfall_named", "plane_ochrefringe_named", "plane_ringingrows_named",
  "plane_synthetic_town_rooms", "plane_synthetic_ward_wilds", "plane_synthetic_delve_rooms" }) do
  s = map.new()
  map.map(s, fixture(name))
  has(map.html(s), "<svg", name .. " draws")
end

-- The named Depth grows room by room and descends
s = map.new()
replay(s, "seq_delve_names")
eq(s.area, "the Lees, Depth 2", "descended")
eq(s.here, "d10", "placed on Depth 2")

-- ===== Rooms, names and Wards (wayfinder #32): look D, "Floor and dots" (#31) =====

-- The Plane keeps names and wards, each Cell its room, ward and leads; each
-- absent when the package leaves it out
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
eq(s.names["422"], "the market square", "names kept")
eq(s.wards.rookery, "the Rookery", "wards kept")
eq(s.cells["413"].room, "412", "room kept")
eq(s.cells["412"].ward, "drove_end", "ward kept")
eq(s.cells["414"].leads.north, "the Green Road", "leads kept")
eq(s.cells["440"].room, nil, "no room key, none kept")
eq(s.cells["412"].leads, nil, "no leads, none kept")
s = map.new()
map.map(s, fixture("plane_gildhythe"))
eq(s.names, nil, "a Plane with no names has none")
eq(s.wards, nil, "a Plane with no wards has none")
eq(s.cells["247"].ward, nil, "a Cell with no ward has none")
map.map(s, { area = "Opaque", rooms = { a = { x = 0, y = 0, z = 0, room = 7 }, b = { x = 1, y = 0, z = 0, room = 7 } } })
eq(s.cells.a.room, "7", "a room id is kept as text, never read as a number")

-- The Rooms of the level shown: their parts, and whether they fill their box
local function roomsById(st)
  local out = {}
  for _, R in ipairs(map.rooms(st)) do out[R.id] = R end
  return out
end
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
local rs = roomsById(s)
eq(rs["412"].kind, "rect", "the avenue fills its box")
eq(#rs["412"].parts, 3, "three parts")
eq(rs["422"].kind, "rect", "the market square: an id that is not its lowest part")
eq(table.concat(rs["422"].parts, ","), "420,421,422,423", "its parts, sorted")
eq(rs["430"].kind, "band", "the slant is a Diagonal run")
eq(rs["440"].kind, "cell", "a Cell with no room key is a Room by itself")
eq(rs["442"], nil, "only the level shown")
map.map(s, { area = "Ell", rooms = { a = { x = 0, y = 0, z = 0, room = "a" }, b = { x = 1, y = 0, z = 0, room = "a" },
  c = { x = 1, y = 1, z = 0, room = "a" } } })
eq(roomsById(s).a.kind, "tiles", "neither box nor diagonal: drawn as its Cells' tiles")
lacks(map.html(s), 'class="rshape"', "with no shape")
eq(count(map.html(s), '<g class="room"'), 3, "one tile each")

-- A live Plane (names and leads, no room or ward) draws as v0.6.0 apart from
-- tooltips and lead labels: the same Plane with names and leads taken out
-- draws the same once those are stripped
local function strip(h)
  h = h:gsub("<title>.-</title>", "")
  h = h:gsub('<text class="lead".-</text>', "")
  h = h:gsub("></line>", "/>")
  h = h:gsub(' viewBox="[^"]*"', "")
  h = h:gsub(' style="max%-width:[^"]*"', "")
  h = h:gsub('<div class="mhead">.-</div>', "")
  return h
end
local function bare(pkg)
  pkg.names = nil
  for _, c in pairs(pkg.rooms) do c.leads = nil end
  return pkg
end
for _, name in ipairs({ "plane_gildhythe_named", "plane_greenroad_named", "plane_tallyglass_named",
  "plane_glassfall_named", "plane_ochrefringe_named", "plane_ringingrows_named" }) do
  local first = sortedKeysOf(fixture(name).rooms)[1]
  local a, b = map.new(), map.new()
  map.map(a, fixture(name))
  map.where(a, { here = first, members = { Rei = first } })
  map.map(b, bare(fixture(name)))
  map.where(b, { here = first, members = { Rei = first } })
  local ha = map.html(a)
  eq(strip(ha), strip(map.html(b)), name .. " draws as v0.6.0 apart from tooltips and lead labels")
  for _, part in ipairs({ 'class="rshape"', 'class="dot"', 'class="ward"', 'class="rlabel"', 'class="mlegend"' }) do
    lacks(ha, part, name .. " has no Rooms or Wards to draw")
  end
end

-- Leads: in the stub's and the Cell's tooltip, and a label where it fits
s = map.new()
map.map(s, fixture("plane_gildhythe_named"))
h = map.html(s)
has(h, "<title>north: to the Green Road</title></line>", "a stub names its Lead")
has(h, "\nnorth: to the Green Road", "and so does its Cell")
has(h, "<title>vault: to Your Strongbox</title>", "a leave with no compass word names its Lead on the disc")
has(h, '<text class="lead"', "lead labels drawn where they fit")
has(h, ">the Green Road</text>", "the gate north")

-- Names lead every tooltip, the Ward next; the header's right names your Room and Ward
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
map.where(s, { here = "420", members = {} })
h = map.html(s)
has(h, "<title>the avenue\nDrove End\ncity\neast: gate (open)</title>", "a Cell's tooltip: Room, Ward, then as before")
has(h, "<title>the avenue\nDrove End\ncity\nexchange: to the Brass Exchange\nnorth: to the Green Road</title>", "with its Leads")
has(h, '<span class="mright"><span class="mroom">the market square</span><span class="msep">&#183;</span>'
  .. '<span class="mward"><i style="background:#f778ba"></i>Drove End</span></span>', "header right: Room and Ward")
map.act(s, "level", "z-1")
lacks(map.html(s), 'class="mright"', "not while Browsing")
s = map.new()
map.map(s, fixture("plane_gildhythe_named"))
map.where(s, { here = "217", members = {} })
has(map.html(s), '<span class="mright"><span class="mroom">Causeway Street, by the dyehouse</span></span>', "a Room with no Ward")

-- A Room of 2+ Cells: one faded shape, edges over it, a dot per Cell
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
h = map.html(s)
eq(count(h, '<g class="rshape"'), 3, "the avenue, the market square, the slant")
has(h, '<g class="rshape" opacity=".38" transform="translate(54 -86)"><rect width="12" height="52" rx="2" fill="#a371f7"/>'
  .. '<rect width="12" height="52" rx="2" fill="url(#pA-city)"/></g>', "a rect spans its tiles' footprint, textured in its own frame")
has(h, 'transform="translate(20 0) rotate(-45) translate(-34.28 -6)"', "a Diagonal run is a band from end Cell to end Cell")
eq(count(h, 'class="dot"'), 10, "a dot on every Cell of a 2+ Cell Room")
has(h, '<line x1="60" y1="-40" x2="60" y2="-60"', "the edge between two Cells of one Room is drawn")
assert(h:find('class="rshape"', 1, true) < h:find('<line x1="60" y1="-40"', 1, true), "under the edges")
eq(count(h, '<g class="room"'), 2, "the one-Cell Rooms keep their tiles")

-- Room labels beside 2+ Cell Rooms only
has(h, '>the market square</text>', "a 2+ Cell Room is labelled")
lacks(h, '>the Hose Post</text>', "a one-Cell Room is not")
local lbl = h:find('class="rlabel"', 1, true)
assert(lbl > h:find('class="dot"', 1, true) and lbl < (h:find('<g class="you"', 1, true) or h:find('class="door"', 1, true)),
  "labels over the Rooms, under the markers")

-- A label with no clear side is dropped, its name kept in the tooltip
local crowd = { area = "Crowd", names = { r = "the boxed-in hall" }, rooms = {
  r = { x = 0, y = 0, z = 0, room = "r" }, r2 = { x = 1, y = 0, z = 0, room = "r" } } }
for _, p in ipairs({ { -1, 1 }, { 0, 1 }, { 1, 1 }, { 2, 1 }, { -1, -1 }, { 0, -1 }, { 1, -1 }, { 2, -1 }, { -1, 0 }, { 2, 0 } }) do
  crowd.rooms["c" .. p[1] .. "_" .. p[2]] = { x = p[1], y = p[2], z = 0, leaves = { "up" } }
end
s = map.new()
map.map(s, crowd)
h = map.html(s)
lacks(h, 'class="rlabel"', "no clear side")
has(h, "<title>the boxed-in hall\nno terrain", "the name stays in the tooltip")

-- A lead label that would cover a tile is left to the tooltip; one past the
-- Plane's edge grows the frame
s = map.new()
map.map(s, { area = "Tight", rooms = { a = { x = 0, y = 0, z = 0, leaves = { "north" }, leads = { north = "Far Away" } },
  b = { x = 0, y = 1, z = 0 } } })
h = map.html(s)
lacks(h, 'class="lead"', "it would cover b's tile")
has(h, "<title>north: to Far Away</title>", "hover only")
s = map.new()
map.map(s, { area = "Wide", rooms = { a = { x = 0, y = 0, z = 0, leaves = { "east" }, leads = { east = "the Very Long Road" } } } })
h = map.html(s)
has(h, ">the Very Long Road</text>", "drawn")
local vw = tonumber(h:match('viewBox="[%-%d%.]+ [%-%d%.]+ ([%d%.]+)'))
assert(vw > 36, "the frame grows to hold it: " .. vw)

-- Wards: a tint and a dashed outline per Ward, hues in the sorted order of wards
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
h = map.html(s)
has(h, '<g class="ward" opacity=".1" fill="#f778ba">', "drove_end, first")
has(h, '<g class="ward" opacity=".1" fill="#e3b341">', "sumps, third after the Rookery")
eq(count(h, 'class="wardline"'), 2, "a dashed outline for each Ward with Cells")
has(h, 'stroke-dasharray="3 2" stroke-opacity=".85"', "dashed")
eq(count(h, "<polygon"), 6, "the slant's two diagonal exits bridge the Sumps (each in the tint, the mask and the outline)")
assert(h:find('class="ward"', 1, true) < h:find('class="rshape"', 1, true), "under everything")

-- Two Wards' bridges crossing in one block draw neither
s = map.new()
map.map(s, { area = "Cross", wards = { x = "X", y = "Y" }, rooms = {
  a = { x = 0, y = 0, z = 0, ward = "x", exits = { northeast = "b" } }, b = { x = 1, y = 1, z = 0, ward = "x", exits = { southwest = "a" } },
  c = { x = 1, y = 0, z = 0, ward = "y", exits = { northwest = "d" } }, d = { x = 0, y = 1, z = 0, ward = "y", exits = { southeast = "c" } } } })
eq(count(map.html(s), "<polygon"), 0, "an X crossing of two Wards: no bridges")
map.map(s, { area = "Cross", wards = { x = "X" }, rooms = {
  a = { x = 0, y = 0, z = 0, ward = "x", exits = { northeast = "b" } }, b = { x = 1, y = 1, z = 0, ward = "x", exits = { southwest = "a" } } } })
eq(count(map.html(s), "<polygon"), 3, "one Ward's diagonal: a bridge")

-- The Ward legend: a row for each Ward, hollow for a Ward with no Cells
s = map.new()
map.map(s, fixture("plane_synthetic_town_rooms"))
h = map.html(s)
has(h, '<div class="mlegend"><span class="lgw" title="Drove End"><i style="background:#f778ba"></i>Drove End</span>'
  .. '<span class="lgw hollow" title="the Rookery: its own map, through the door that names it"><i style="border-color:#56d4dd"></i>the Rookery</span>'
  .. '<span class="lgw" title="the Sumps"><i style="background:#e3b341"></i>the Sumps</span></div>', "legend")
assert(h:find('class="mlegend"', 1, true) < h:find('class="mlevel"', 1, true), "under the map, over the level bar")

-- Every plane with the new keys, captured or synthetic, is taken and drawn
for _, name in ipairs({ "plane_synthetic_town_rooms", "plane_synthetic_ward_wilds", "plane_synthetic_delve_rooms" }) do
  s = map.new()
  map.map(s, fixture(name))
  has(map.html(s), "<svg", name .. " draws")
  eq(map.html(s), map.html(s), name .. " draws the same each time")
end
s = map.new()
replay(s, "seq_delve_names")
has(map.html(s), "<svg", "the named Depth draws")

print("map_test: OK")
