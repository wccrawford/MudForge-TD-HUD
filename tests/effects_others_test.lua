-- Effects: the Group's members and Allies (Char.OtherEffects) beside the
-- reader's own, and the helps/harms split on every row.
local effects = require("effects")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

-- The reader's own, alone: no Bearer names drawn; helps and what it does ride
local s = effects.new()
effects.effects(s, { effects = {
  { name = "Warded", helps = true, does = "raises your resistance to fire", ends_at_ms = 1030000 },
  { name = "Weakness", helps = false, ends_at_ms = 1060000 },
  { name = "Old", ends_at_ms = 1090000 },
}, now_ms = 1000000 }, 0)
local k = effects.keys(s, 0)
eq(k.e1n, "Warded", "own row 1")
eq(k.e1h, "1", "Warded helps")
eq(k.e1w, "Helps: raises your resistance to fire", "Warded's tooltip")
eq(k.e1bd, "none", "no Bearer name while only the reader's own show")
eq(k.e2h, "0", "Weakness harms")
eq(k.e2w, "Harms", "a harm with no words")
eq(k.e3h, "", "no helps key: unknown")
eq(k.e3w, "", "no tooltip")

-- The Group arrives: members and Allies after the reader's own, in the
-- feed's order; foes are left out
effects.others(s, { bearers = {
  { kind = "member", name = "Bob", id = 9, effects = {
    { name = "Bark hide", helps = true, does = "raises their resistance to crush", ends_at_ms = 1030000 },
    { name = "Haste", helps = true, ends_at_ms = 1010000 },
  } },
  { kind = "foe", name = "a goblin", id = 40, effects = {
    { name = "Snared", helps = false, ends_at_ms = 1050000 },
  } },
  { kind = "ally", name = "a frost wolf", id = 12, owner = "you", effects = {
    { name = "Weakness", helps = false, does = "lowers the damage they deal", ends_at_ms = 1020000 },
  } },
  { kind = "ally", name = "a vanguard", id = 13, owner = "Bob", effects = {
    { name = "feinted", helps = false, this_fight = true, ends_at_ms = 2^64 },
  } },
}, now_ms = 1000000 }, 0)
k = effects.keys(s, 0)
eq(k.e1b, "You", "the reader's first row is named once others show")
eq(k.e1bd, "", "and drawn")
eq(k.e2bd, "none", "only a Bearer's first row is named")
eq(k.e4n, "Haste", "Bob's soonest first")
eq(k.e4b, "Bob", "Bob named over his first row")
eq(k.e5n, "Bark hide", "Bob's second")
eq(k.e5bd, "none", "Bob's second row unnamed")
eq(k.e6n, "Weakness", "the wolf's")
eq(k.e6b, "a frost wolf (yours)", "the reader's own Ally")
eq(k.e6w, "Harms: lowers the damage they deal", "worded to a third party")
eq(k.e7n, "feinted", "the vanguard's")
eq(k.e7b, "a vanguard (Bob's)", "another member's Ally")
eq(k.e7t, "this fight", "this_fight reads this fight")
eq(k.e7p, "100%", "this_fight hairline full")
eq(k.e8d, "none", "the foe's effect is not drawn")

-- Others drain and Clear on the local clock; a Bearer with nothing left is gone
eq(effects.tick(s, 10500), true, "Bob's Haste clears")
k = effects.keys(s, 10500)
eq(k.e4n, "Bark hide", "Bob keeps Bark hide")
eq(k.e4b, "Bob", "now named over it")
effects.tick(s, 30500)
k = effects.keys(s, 30500)
eq(k.e1n, "Weakness", "Warded cleared; the reader's Weakness and Old stay")
eq(k.e2n, "Old", "Old")
-- Bob's Bark hide and the wolf's Weakness cleared; the vanguard's fight
-- debuff never Clears, so it shows and the reader stays named
eq(k.e3n, "feinted", "the vanguard's")
eq(k.e3b, "a vanguard (Bob's)", "named")
eq(k.e4d, "none", "nothing else")
eq(k.e1b, "You", "the reader still named")
eq(effects.counting(s), true, "still counting")

-- A re-push inside the dead-band keeps a Bearer's Countdown; two Allies
-- sharing a name keep their own
local s2 = effects.new()
local function wolves(now_ms, a, b)
  return { bearers = {
    { kind = "ally", name = "a wolf", id = 1, owner = "you", effects = { { name = "Haste", helps = true, ends_at_ms = now_ms + a } } },
    { kind = "ally", name = "a wolf", id = 2, owner = "you", effects = { { name = "Haste", helps = true, ends_at_ms = now_ms + b } } },
  }, now_ms = now_ms }
end
effects.others(s2, wolves(0, 10000, 20000), 0)
local cd1 = s2.others[1].by_name.Haste.cd
effects.others(s2, wolves(1000, 9040, 19000), 1000)
assert(s2.others[1].by_name.Haste.cd == cd1, "dead-band keeps the first wolf's Countdown")
k = effects.keys(s2, 1000)
eq(k.e1t, "00:09", "first wolf")
eq(k.e2t, "00:19", "second wolf, its own clock")
eq(k.e1b, "a wolf (yours)", "first wolf named")
eq(k.e2b, "a wolf (yours)", "second wolf named too")

-- Others alone make the widget Live; leaving the Group clears them
local s3 = effects.new()
effects.others(s3, { bearers = {}, now_ms = 0 }, 0)
eq(effects.keys(s3, 0).hudState, "live", "Live on Char.OtherEffects")
eq(effects.keys(s3, 0).effEmpty, "", "No effects")
effects.others(s, { bearers = {}, now_ms = 2000000 }, 40000)
k = effects.keys(s, 40000)
eq(k.e1n, "Weakness", "only the reader's own left")
eq(k.e1bd, "none", "no names")
eq(k.e2n, "Old", "and Old")
eq(k.e3d, "none", "nothing else")

-- Severed freezes others too
effects.others(s, { bearers = { { kind = "member", name = "Bob", id = 9, effects = {
  { name = "Haste", helps = true, ends_at_ms = 30000 } } } }, now_ms = 0 }, 40000)
effects.sever(s, 50000)
k = effects.keys(s, 90000)
eq(k.e3n, "Haste", "Bob's row kept")
eq(k.e3t, "00:20", "frozen")
eq(effects.tick(s, 99000), false, "tick is a no-op")

print("effects_others_test: OK")
