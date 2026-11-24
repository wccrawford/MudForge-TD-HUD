local group = require("group")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": expected to find " .. part .. " in " .. s)
end

-- Unfed: the reader's own row alone, empty, dimmed by state
local s = group.new()
local rows = group.rows(s)
eq(#rows, 1, "unfed: one row")
eq(rows[1].name, "You", "the reader's row")
eq(rows[1].cond, nil, "no Condition yet")
has(group.html(s), 'data-state="unfed"', "unfed state")

-- Solo: Char.Vitals and the reader's own effects
group.vitals(s, { condition = { name = "unhurt", tier = 1, of = 5, cur = 30, max = 30 } })
group.effects(s, { effects = {
  { name = "Warded", helps = true, ends_at_ms = 10 },
  { name = "Haste", helps = true, ends_at_ms = 10 },
  { name = "Weakness", helps = false, ends_at_ms = 10 },
  { name = "Old", ends_at_ms = 10 },
}, now_ms = 0 })
rows = group.rows(s)
eq(rows[1].cond.cur, 30, "own Condition")
eq(rows[1].fx.good, 2, "two help")
eq(rows[1].fx.bad, 1, "one harms; one with no helps counts as neither")
eq(rows[1].fx.goodTip, "Warded, Haste", "names in the tooltip")
local html = group.html(s)
has(html, 'data-state="live"', "live")
has(html, 'data-tier="1" style="width:100%"', "full bar, tier 1")
has(html, '<span class="num">30/30</span>', "figures")
has(html, '<span class="good" title="Warded, Haste">2</span>', "good pill")
has(html, '<span class="bad" title="Weakness">1</span>', "bad pill")

-- The Group, its Allies and their effects (the server's fixtures)
group.group(s, {
  { name = "Alice", leader = true, you = true, id = 7, where = "here" },
  { name = "Bob", leader = false, you = false, id = 9,
    condition = { name = "Wounded", tier = 2, of = 5, cur = 60, max = 100 },
    where = "away", exit = "north", moves = 1 },
  { name = "Cara", leader = false, you = false, where = "offline" },
})
group.allies(s, {
  { id = 13, name = "a vanguard", tier = "Hurt", owner = "Bob",
    condition = { name = "Hurt", tier = 3, of = 5, cur = 20, max = 50 } },
  { id = 12, name = "a frost wolf", tier = "Unhurt", owner = "you",
    condition = { name = "Unhurt", tier = 1, of = 5, cur = 40, max = 40 }, ends_at_ms = 1045000 },
  { id = 14, name = "a stray", owner = "Dee" },
})
group.others(s, { bearers = {
  { kind = "member", name = "Bob", id = 9, effects = {
    { name = "Bark hide", helps = true, does = "raises their resistance to crush", ends_at_ms = 1030000 } } },
  { kind = "ally", name = "a frost wolf", id = 12, owner = "you", effects = {
    { name = "Weakness", helps = false, ends_at_ms = 1020000 } } },
  { kind = "foe", name = "a goblin", id = 9, effects = {
    { name = "Snared", helps = false, ends_at_ms = 1050000 } } },
}, now_ms = 1000000 })
rows = group.rows(s)
eq(#rows, 6, "you, wolf, Bob, vanguard, Cara, stray")
eq(rows[1].name, "You", "the reader first")
eq(rows[1].leader, true, "the reader leads")
eq(rows[1].tip, "Alice", "the reader's name in the tooltip")
eq(rows[2].name, "a frost wolf", "the reader's Ally under them")
eq(rows[2].ally, true, "an Ally row")
eq(rows[2].tip, "a frost wolf, yours", "whose")
eq(rows[2].fx.bad, 1, "the wolf's Weakness")
eq(rows[3].name, "Bob", "Bob next")
eq(rows[3].tip, "Bob: north, one room away", "where Bob is")
eq(rows[3].cond.cur, 60, "Bob's figures")
eq(rows[3].fx.good, 1, "Bob's Bark hide, not the foe's Snared under the same id")
eq(rows[3].fx.bad, 0, "Bob has nothing harming")
eq(rows[4].name, "a vanguard", "Bob's hand under Bob")
eq(rows[4].tip, "a vanguard, Bob's", "whose")
eq(rows[5].name, "Cara", "Cara")
eq(rows[5].offline, true, "offline")
eq(rows[5].cond, nil, "no Condition offline")
eq(rows[6].name, "a stray", "an Ally with no owner row last")
html = group.html(s)
has(html, '<div class="gr away"><span class="gn" title="Bob: north, one room away">Bob</span>', "Bob away")
has(html, 'data-tier="2" style="width:60%"', "Bob's bar")
has(html, '<span class="word">Wounded</span>', "the band word (lowercased by CSS)")
has(html, '<div class="gr off"><span class="gn" title="Cara: offline">Cara</span><div class="bar empty"><span class="word">offline</span>', "Cara offline")
has(html, '<span class="ld" title="Leader"></span>You', "leader mark")
has(html, '<span class="good z"></span>', "a zero count is kept but hidden")

-- Where words
local function tip(m)
  local t = group.new()
  m.name = "M"
  group.group(t, { m })
  return group.rows(t)[2].tip
end
eq(tip({ where = "away", exit = "east", moves = 6 }), "M: east, 6 rooms away", "rooms away")
eq(tip({ where = "elsewhere" }), "M: elsewhere", "elsewhere")
eq(tip({ where = "out_of_reach" }), "M: out of reach", "out of reach")
eq(tip({ where = "inside", delve = "the Barrow" }), "M: inside the Barrow", "inside a Delve")
eq(tip({ where = "here" }), "M", "here says nothing more")

-- Fed text is escaped
local e = group.new()
group.group(e, { { name = "<b>", where = "here", condition = { name = "a&b", tier = 9, cur = 5, max = 0 } } })
html = group.html(e)
has(html, "&lt;b&gt;", "name escaped")
has(html, "a&amp;b", "band escaped")
has(html, 'data-tier="5" style="width:0%"', "tier clamped, no max is an empty bar")

-- Leaving the Group: an empty roster and Allies clear the rows
group.group(s, {})
group.allies(s, {})
group.others(s, { bearers = {}, now_ms = 0 })
eq(#group.rows(s), 1, "the reader alone")

-- Severed keeps the rows
group.sever(s)
has(group.html(s), 'data-state="severed"', "severed")
eq(group.rows(s)[1].cond.cur, 30, "kept")
local u = group.new()
group.sever(u)
eq(u.state, "unfed", "severing Unfed stays Unfed")

-- nil packages are ignored
group.vitals(s, nil)
group.group(s, nil)
group.allies(s, nil)
group.effects(s, nil)
group.others(s, nil)
eq(group.rows(s)[1].cond.cur, 30, "nil ignored")

print("group_test: OK")
