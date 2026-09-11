local slots = require("slots")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

-- A Char.Items snapshot from { {label, item|nil}, ... } pairs; instance is
-- the same fake id for everything occupied, nil when empty.
local function pkg(rows)
  local list = {}
  for i, r in ipairs(rows) do
    list[i] = { slot = r[1], instance = r[2] ~= nil and 4294967297 or nil, item = r[2] }
  end
  return { slots = list }
end

local VILLAGER = {
  { "Head" }, { "Body", "a linen tunic" }, { "Legs", "linen trousers" }, { "Feet" },
  { "Hands" }, { "Hand 1", "a rusty dagger" }, { "Hand 2" }, { "Waist", "a rope belt" },
  { "Back" }, { "Neck" }, { "Finger 1" }, { "Finger 2", "a copper ring" },
}

-- Unfed: every row hidden, no "No slots" either
local s = slots.new()
local k = slots.keys(s)
eq(k.hudState, "unfed", "unfed state")
eq(k.slotsEmpty, "none", "unfed hides the empty line")
eq(k.slotsMore, "", "unfed no more line")
eq(k.s1d, "none", "unfed row 1 hidden")
eq(k.s1l, "", "unfed row 1 blank label")
eq(k.s1i, "", "unfed row 1 blank item")
eq(k.s1e, 1, "unfed row 1 flagged empty")
eq(k.s16d, "none", "unfed row 16 hidden")

-- Live on the first Char.Items, even for a Race with no Slots
slots.items(s, { slots = {} })
k = slots.keys(s)
eq(k.hudState, "live", "live after first push")
eq(k.slotsEmpty, "", "no slots shows No slots")
eq(k.s1d, "none", "no slots row hidden")

-- The villager's twelve slots in feed order, empties as an em dash
slots.items(s, pkg(VILLAGER))
k = slots.keys(s)
eq(k.slotsEmpty, "none", "rows hide the empty line")
eq(k.s1l, "Head", "row 1 label")
eq(k.s1i, "", "empty slot has no item text; the markup draws the dash")
eq(k.s1e, 1, "empty slot flagged")
eq(k.s1d, "", "row 1 shown")
eq(k.s2l, "Body", "row 2 label")
eq(k.s2i, "a linen tunic", "row 2 item")
eq(k.s2e, 0, "occupied slot not flagged")
eq(k.s6l, "Hand 1", "held slots are ordinary rows")
eq(k.s6i, "a rusty dagger", "held item")
eq(k.s12l, "Finger 2", "row 12 label")
eq(k.s12i, "a copper ring", "row 12 item")
eq(k.s13d, "none", "row 13 hidden")
eq(k.s13l, "", "row 13 blank")
eq(k.s16d, "none", "row 16 hidden")
eq(k.slotsMore, "", "twelve slots fit the pool")

-- A snapshot replaces the ledger wholesale: fewer slots hide the rest
slots.items(s, pkg({ { "Head", "a straw hat" }, { "Tail" } }))
k = slots.keys(s)
eq(k.s1i, "a straw hat", "replaced row 1")
eq(k.s2l, "Tail", "unknown slot kinds are just labels")
eq(k.s2i, "", "empty tail")
eq(k.s3d, "none", "row 3 hidden after shrink")
eq(k.s3l, "", "row 3 blank after shrink")

-- A two-handed item repeats in both hands; the ledger just shows it twice
slots.items(s, pkg({ { "Hand 1", "a greatsword" }, { "Hand 2", "a greatsword" } }))
k = slots.keys(s)
eq(k.s1i, "a greatsword", "hand 1")
eq(k.s2i, "a greatsword", "hand 2")

-- Pool overflow: 18 slots show 16 rows and "+2 more"
local many = {}
for i = 1, 18 do many[i] = { "Slot " .. i } end
slots.items(s, pkg(many))
k = slots.keys(s)
eq(k.s16l, "Slot 16", "overflow row 16")
eq(k.slotsMore, "+2 more", "overflow line")
slots.items(s, pkg(VILLAGER))
eq(slots.keys(s).slotsMore, "", "more line clears")

-- Feed arrays reach Lua 0-based under t[i]: ipairs must still walk them
local zero = { slots = {} }
zero.slots[0] = { slot = "Head", instance = nil, item = nil }
zero.slots[1] = { slot = "Body", instance = 1, item = "a tunic" }
slots.items(s, zero)
k = slots.keys(s)
eq(k.s1l, "Body", "ipairs starts at 1; index 0 is MudForge's to fix, not ours")
eq(k.s2d, "none", "only one row seen")

-- Entries without a slot label are skipped, not shown blank
slots.items(s, { slots = { { instance = nil, item = nil }, { slot = "Neck", instance = nil, item = nil } } })
k = slots.keys(s)
eq(k.s1l, "Neck", "unlabelled entry skipped")
eq(k.s2d, "none", "nothing after it")

-- Severed: ledger kept, only the state changes
slots.items(s, pkg(VILLAGER))
slots.sever(s)
k = slots.keys(s)
eq(k.hudState, "severed", "severed state")
eq(k.s2i, "a linen tunic", "row kept while severed")
eq(k.s12l, "Finger 2", "last row kept while severed")

-- Severing an Unfed widget leaves it Unfed
local u = slots.new()
slots.sever(u)
eq(u.state, "unfed", "sever before first push")

-- nil package is ignored
slots.items(s, nil)
eq(slots.keys(s).s2i, "a linen tunic", "nil push ignored")

print("slots_test: OK")
