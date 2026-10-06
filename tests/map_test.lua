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
eq(s.rooms.d4 ~= nil, true, "the grown plane")

-- A Depth descent is just a new Plane: the old Depth's rooms are gone
s = map.new()
replay(s, "seq_depth_descend")
eq(s.area, "the Lees, Depth 2", "descended")
eq(s.here, "d13", "placed on Depth 2")
eq(s.rooms.d12, nil, "Depth 1 dropped")

-- A door opening re-sends the Plane alone; the player stays where they are
s = map.new()
replay(s, "seq_door_opened")
eq(s.here, "d11", "still at the windlass")
eq(s.rooms.d12.doors.north.closed, false, "the vault door is open")

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

-- Header: the Area and Region only; the font is the widget's own
s = map.new()
map.map(s, fixture("plane_spitcut_door_closed"))
map.where(s, { here = "d12", members = {} })
h = map.html(s, { family = "Fira", size = 14 })
has(h, 'style="font-size:14px;font-family:Fira"', "the widget font")
has(h, '<span class="marea">the Spit Cut</span><span class="mregion">the Saffron Fall</span>', "header")
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
for id, r in pairs(s.rooms) do if r.z == 1 then upId = id end end
map.where(s, { here = "249", members = { Rei = "247", Ana = "247", Bo = "249", ["\195\137a"] = upId } })
h = map.html(s)
eq(count(h, '<g class="member">'), 3, "three members on the level shown")
has(h, "<title>You, with Bo</title>", "a member in your room folds into your marker's name")
local ana = h:match('<g class="member"><title>Ana</title><circle cx="([%-%d%.]+)"')
local rei = h:match('<g class="member"><title>Rei</title><circle cx="([%-%d%.]+)"')
eq(tonumber(rei) - tonumber(ana), 6, "fanned right in one room")
has(h, '<span class="lvmem" title="\195\137a: level 2" data-mud-action="level" data-mud-data="z1">\195\137</span>', "a member above, by the up arrow, initial in UTF-8")
assert(h:find('class="lvmem"', 1, true) > h:find('class="lvmid', 1, true), "members above sit at the up end")
map.act(s, "level", "z1")
h = map.html(s)
has(h, '<g class="member"><title>\195\137a</title>', "on their level, drawn on the plane")
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

print("map_test: OK")
