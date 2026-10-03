local recent = require("recent")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

-- Empty: nothing shown, navigation is a no-op
local r = recent.new(3)
eq(recent.shown(r), nil, "empty shows nothing")
eq(recent.count(r), 0, "empty count")
recent.older(r)
eq(r.at, 0, "older on empty stays put")

-- put shows the newest
recent.put(r, "a", "A")
recent.put(r, "b", "B")
eq(recent.shown(r), "B", "newest on show")
eq(recent.count(r), 2, "two kept")

-- older / newer walk and stop at the ends
recent.older(r)
eq(recent.shown(r), "A", "older")
recent.older(r)
eq(recent.shown(r), "A", "older stops at the oldest")
recent.newer(r)
eq(recent.shown(r), "B", "newer")
recent.newer(r)
eq(recent.shown(r), "B", "newer stops at the newest")

-- Re-putting a key moves it to the head, never twice, and shows it
recent.older(r)
recent.put(r, "a", "A2")
eq(recent.count(r), 2, "no duplicate")
eq(recent.shown(r), "A2", "re-put on show")
eq(recent.entries(r)[2], "B", "the other moved down")

-- The limit drops the oldest
recent.put(r, "c", "C")
recent.put(r, "d", "D")
eq(recent.count(r), 3, "limit")
local all = recent.entries(r)
eq(all[1], "D", "newest first")
eq(all[3], "A2", "oldest kept is third")

-- refresh replaces the head in place and leaves the view alone
recent.show(r, 3)
eq(recent.refresh(r, "d", "D2"), true, "refresh the head")
eq(recent.shown(r), "A2", "view unmoved")
eq(recent.entries(r)[1], "D2", "head replaced")
eq(recent.refresh(r, "c", "C2"), false, "refresh only touches the head")
eq(recent.entries(r)[2], "C", "non-head untouched")

-- find answers where a key stands
eq(recent.find(r, "c"), 2, "find")
eq(recent.find(r, "zz"), nil, "find missing")

-- show ignores out of range
recent.show(r, 9)
eq(r.at, 3, "out of range ignored")
recent.show(r, nil)
eq(r.at, 3, "nil ignored")

print("recent_test: OK")
