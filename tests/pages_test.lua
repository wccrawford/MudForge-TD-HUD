local pages = require("pages")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": " .. part .. " not in " .. s)
end

local function lacks(s, part, label)
  assert(not s:find(part, 1, true), label .. ": " .. part .. " in " .. s)
end

local SLATE = "a chalked slate"

local function page(n, title, body)
  return { kind = "page", writing = SLATE, page = n, title = title,
    lines = { { { text = title } }, { { text = body } } } }
end

local CONTENTS = { kind = "contents", writing = "a recipe book", pages = {
  { page = 1, title = "Iron nails", section = "Smithing", rung = 2 },
  { page = 2, title = "Iron hinge", section = "Smithing" },
  { page = 3, title = "Rope", section = "Ropework" },
} }

-- Unfed: an empty reader, nothing to click
local s = pages.new()
local h = pages.html(s)
has(h, 'data-state="unfed"', "unfed")
has(h, "Nothing read yet.", "unfed text")
lacks(h, "data-mud-action", "unfed has no controls")

-- A page goes on show, Live
pages.read(s, page(3, "Forging", "Heat the bar & strike."))
h = pages.html(s)
has(h, 'data-state="live"', "live")
has(h, "a chalked slate - p. 3", "label")
has(h, "Heat the bar &amp; strike.", "body escaped")
has(h, "1/1", "position")

-- A second page goes on show; the first is one back
pages.read(s, page(1, "Smelting", "Melt the ore."))
h = pages.html(s)
has(h, "Melt the ore.", "newest on show")
has(h, "1/2", "two in Recent")
pages.act(s, "older")
h = pages.html(s)
has(h, "Heat the bar", "older shows the first")
has(h, "2/2", "position after older")

-- Reading a page again while browsing: it goes on show, not twice
pages.read(s, page(3, "Forging", "Heat the bar & strike."))
h = pages.html(s)
has(h, "1/2", "re-read moves up, no duplicate")
has(h, "Heat the bar", "re-read on show")

-- The Recent list, and opening from it
eq(pages.act(s, "recent"), nil, "recent sends nothing")
h = pages.html(s)
has(h, "Recent pages", "list label")
has(h, 'data-mud-action="open" data-mud-data="2"', "row 2 opens")
has(h, "Smelting", "list shows page titles")
pages.act(s, "open", "2")
h = pages.html(s)
has(h, "Melt the ore.", "opened entry")
lacks(h, "Recent pages", "list closed on open")
pages.act(s, "recent")
pages.act(s, "recent")
lacks(pages.html(s), "Recent pages", "recent toggles off")

-- Contents: sections once each, rows clickable, rung in brackets
pages.read(s, CONTENTS)
h = pages.html(s)
has(h, "a recipe book - contents", "contents label")
local _, n = h:gsub("Smithing", "")
eq(n, 1, "a section heads its rows once")
has(h, "Ropework", "second section")
has(h, 'data-mud-action="read" data-mud-data="1"', "row reads its page")
has(h, "(2)", "rung")
eq(pages.act(s, "read", "3"), "read a recipe book 3", "a row's click reads its page")
eq(pages.act(s, "read", "x"), nil, "a bad page sends nothing")

-- A row's click on a page (not contents) sends nothing
pages.act(s, "older")
eq(pages.act(s, "read", "1"), nil, "read only from contents")

-- Contents on a page: shown from Recent when the book's contents are there
-- (no command), else read from the server; never on the contents themselves
s = pages.new()
pages.read(s, CONTENTS)
h = pages.html(s)
assert(not h:find('data-mud-action="contents"', 1, true), "no Contents button on contents")
eq(pages.act(s, "contents"), nil, "Contents on contents does nothing")
pages.read(s, { kind = "page", writing = "a recipe book", page = 2, title = "Iron hinge", lines = { { { text = "Iron hinge" } } } })
pages.read(s, page(3, "Forging", "Heat."))
pages.act(s, "older")
h = pages.html(s)
has(h, "a recipe book - p. 2", "on the book's page")
has(h, 'data-mud-action="contents"', "Contents button on a page")
eq(pages.act(s, "contents"), nil, "contents in Recent: no command")
h = pages.html(s)
has(h, "a recipe book - contents", "jumped to the contents")
has(h, "3/3", "the contents' place in Recent")
pages.act(s, "newer")
pages.act(s, "newer")
has(pages.html(s), "a chalked slate - p. 3", "on the slate's page")
eq(pages.act(s, "contents"), "read a chalked slate", "contents not in Recent: read them")

-- Severed keeps Recent; a new() is a fresh reader
pages.sever(s)
h = pages.html(s)
has(h, 'data-state="severed"', "severed")
has(h, "/3", "Recent kept while severed")
local u = pages.new()
pages.sever(u)
eq(u.state, "unfed", "sever before first push")

-- Malformed pushes are ignored
pages.read(s, nil)
pages.read(s, { kind = "page" })
pages.read(s, { kind = "other", writing = "x" })
has(pages.html(s), "/3", "nothing added")

print("pages_test: OK")
