local quests = require("quests")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": " .. part .. " not in " .. s)
end

local function lacks(s, part, label)
  assert(not s:find(part, 1, true), label .. ": " .. part .. " in " .. s)
end

local function quest(title, status, step)
  return { title = title, status = status, lines = {
    { { text = title .. " [" .. status .. "]" } },
    { { text = "Kill them all.", role = "Speech" } },
    { { hang = 2 }, { text = step } },
  } }
end

-- Unfed
local s = quests.new()
local h = quests.html(s)
has(h, 'data-state="unfed"', "unfed")
has(h, "No quest pulled up yet.", "unfed text")

-- First quest on show, Live, status classed
quests.show(s, quest("Rat Problem", "in progress", "- Kill two rats. (0/2)"))
h = quests.html(s)
has(h, 'data-state="live"', "live")
has(h, 'class="st st-in-progress"', "status class")
has(h, '<span class="r-Speech">Kill them all.</span>', "speech role")
has(h, "(0/2)", "progress")

-- The same quest re-sent refreshes in place
quests.show(s, quest("Rat Problem", "in progress", "- Kill two rats. (1/2)"))
h = quests.html(s)
has(h, "(1/2)", "refreshed")
has(h, "1/1", "still one entry")

-- A different quest goes on show
quests.show(s, quest("Jars on the Spit", "in progress", "- Find a jar. (0/1)"))
h = quests.html(s)
has(h, "Find a jar", "new quest on show")
has(h, "1/2", "two in Recent")
lacks(h, "As last shown", "the head is current")

-- Browsing back: an older one is a snapshot
quests.act(s, "older")
h = quests.html(s)
has(h, "(1/2)", "older quest")
has(h, "As last shown", "snapshot note")

-- The head moving while browsing does not pull the view
quests.show(s, quest("Jars on the Spit", "completed", "- Find a jar. (1/1)"))
h = quests.html(s)
has(h, "(1/2)", "view stays on the older quest")
quests.act(s, "newer")
h = quests.html(s)
has(h, "st-completed", "head refreshed underneath")

-- Pulling the older one up again moves it to the head and shows it
quests.act(s, "older")
quests.show(s, quest("Rat Problem", "completed", "- Kill two rats. (2/2)"))
h = quests.html(s)
has(h, "(2/2)", "re-pulled on show")
has(h, "1/2", "moved to head, no duplicate")

-- The Recent list
quests.act(s, "recent")
h = quests.html(s)
has(h, "Recent quests", "list")
has(h, "Jars on the Spit", "list title")
eq(quests.act(s, "open", "2"), nil, "open sends nothing")
has(quests.html(s), "Find a jar", "opened")

-- Severed keeps it all
quests.sever(s)
has(quests.html(s), 'data-state="severed"', "severed")

-- Malformed pushes are ignored
quests.show(s, nil)
quests.show(s, { status = "x" })
has(quests.html(s), "/2", "nothing added")

print("quests_test: OK")
