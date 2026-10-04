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
local function asks(req, writing, n, label)
  assert(type(req) == "table", label .. ": expected a request, got " .. tostring(req))
  eq(req.gmcp, "Page.Read", label .. " package")
  eq(req.data.writing, writing, label .. " writing")
  eq(req.data.page, n, label .. " page")
end
asks(pages.act(s, "read", "3"), "a recipe book", 3, "a row's click reads its page on the side band")
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
asks(pages.act(s, "contents"), SLATE, nil, "contents not in Recent: ask for them")

-- Turning pages: a page's foot turns to page - 1 / + 1, never below 1
s = pages.new()
pages.read(s, page(3, "Forging", "Heat."))
h = pages.html(s)
has(h, 'data-mud-action="turn" data-mud-data="2"', "turn back to p. 2")
has(h, 'data-mud-action="turn" data-mud-data="4"', "turn on to p. 4")
asks(pages.act(s, "turn", "4"), SLATE, 4, "turn asks for the page")
eq(pages.act(s, "turn", "x"), nil, "a bad turn sends nothing")
pages.read(s, page(1, "Smelting", "Melt."))
h = pages.html(s)
lacks(h, 'data-mud-data="0"', "no page before 1")
has(h, 'data-mud-action="turn" data-mud-data="2"', "p. 1 turns on to 2")

-- With the book's contents in Recent, a turn goes to the next listed page,
-- and the last listed page has nothing after it
s = pages.new()
pages.read(s, { kind = "contents", writing = "a recipe book", pages = {
  { page = 1, title = "Iron nails" }, { page = 3, title = "Rope" }, { page = 4, title = "Knots" } } })
pages.read(s, { kind = "page", writing = "a recipe book", page = 3, title = "Rope", lines = {} })
h = pages.html(s)
has(h, 'data-mud-action="turn" data-mud-data="1"', "back skips the unlisted page")
has(h, 'data-mud-action="turn" data-mud-data="4"', "on to the next listed")
pages.read(s, { kind = "page", writing = "a recipe book", page = 4, title = "Knots", lines = {} })
h = pages.html(s)
lacks(h, 'data-mud-data="5"', "nothing after the last listed page")
has(h, 'data-mud-action="turn" data-mud-data="3"', "back from the last")

-- No turning on contents or the Recent list
pages.act(s, "recent")
lacks(pages.html(s), 'data-mud-action="turn"', "no turns on the Recent list")
pages.act(s, "open", "3")
lacks(pages.html(s), 'data-mud-action="turn"', "no turns on contents")
eq(pages.act(s, "turn", "2"), nil, "turn only from a page")

-- Page.Refused: its words shown over what is on show, which stays; gone on
-- the next click or the next page read
pages.read(s, { kind = "page", writing = "a recipe book", page = 4, title = "Knots", lines = {} })
pages.refused(s, { writing = "a recipe book", page = 5, text = "There is no page 5 in <it>." })
h = pages.html(s)
has(h, "There is no page 5 in &lt;it&gt;.", "refusal shown, escaped")
has(h, "a recipe book - p. 4", "the page stays on show")
pages.act(s, "older")
lacks(pages.html(s), "There is no page 5", "a click clears the refusal")
pages.refused(s, { writing = "a recipe book", text = "You don't see that here." })
pages.read(s, { kind = "page", writing = "a recipe book", page = 3, title = "Rope", lines = {} })
lacks(pages.html(s), "You don't see that", "a page read clears the refusal")
pages.refused(s, nil)
pages.refused(s, { writing = "x" })
lacks(pages.html(s), 'class="note', "malformed refusals ignored")

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
