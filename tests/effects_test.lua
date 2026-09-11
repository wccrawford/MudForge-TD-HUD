local effects = require("effects")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

-- A snapshot on the Feed's clock: effects as { name = ms_left } pairs.
local function pkg(now_ms, left)
  local list = {}
  for name, ms in pairs(left) do list[#list + 1] = { name = name, ends_at_ms = now_ms + ms } end
  table.sort(list, function(a, b) return a.name < b.name end)
  return { effects = list, now_ms = now_ms }
end

-- Unfed: every row hidden, no "No effects" either
local s = effects.new()
local k = effects.keys(s, 1000)
eq(k.hudState, "unfed", "unfed state")
eq(k.effEmpty, "none", "unfed hides the empty line")
eq(k.effMore, "", "unfed no more line")
eq(k.e1d, "none", "unfed row 1 hidden")
eq(k.e1n, "", "unfed row 1 blank")
eq(k.e10d, "none", "unfed row 10 hidden")
eq(effects.counting(s), false, "unfed not counting")

-- Live on the first Char.Effects, even an empty one
effects.effects(s, { effects = {}, now_ms = 500000 }, 1000)
k = effects.keys(s, 1000)
eq(k.hudState, "live", "live after first push")
eq(k.effEmpty, "", "empty list shows No effects")
eq(k.e1d, "none", "empty list row hidden")
eq(effects.counting(s), false, "empty list not counting")

-- Three effects, soonest first, mm:ss rounded up, anchored on the local clock
effects.effects(s, pkg(500000, { Haste = 65000, Blur = 4500, Shield = 600000 }), 1000)
k = effects.keys(s, 1000)
eq(k.effEmpty, "none", "rows hide the empty line")
eq(k.e1n, "Blur", "soonest first")
eq(k.e1t, "00:05", "4.5 s reads 00:05")
eq(k.e1u, 1, "under 5 s is urgent")
eq(k.e1p, "100%", "fresh anchor is full")
eq(k.e1d, "", "row 1 shown")
eq(k.e2n, "Haste", "second soonest")
eq(k.e2t, "01:05", "65 s reads 01:05")
eq(k.e2u, 0, "65 s not urgent")
eq(k.e3n, "Shield", "third")
eq(k.e3t, "10:00", "600 s reads 10:00")
eq(k.e4d, "none", "row 4 hidden")
eq(effects.counting(s), true, "counting")

-- Draining on the local clock between pushes
k = effects.keys(s, 21000)
eq(k.e1n, "Haste", "Blur has drained past its Clear")
eq(k.e1t, "00:45", "Haste drained 20 s")
eq(k.e1p, "69.2%", "hairline is remaining / span")
eq(k.e1u, 0, "still not urgent")
k = effects.keys(s, 62100)
eq(k.e1t, "00:04", "3.9 s reads 00:04")
eq(k.e1u, 1, "urgent under 5 s")

-- The tick drops Cleared effects and says so once
eq(effects.tick(s, 5000), false, "nothing clears at 4 s")
eq(effects.tick(s, 5500), true, "Blur clears at 4.5 s")
eq(s.by_name.Blur, nil, "Blur gone")
eq(effects.tick(s, 5600), false, "no second report")
eq(effects.counting(s), true, "still counting the others")

-- Dead-band: a jittered re-push keeps the running Countdown
local haste = s.by_name.Haste
effects.effects(s, pkg(510000, { Haste = 55040, Shield = 590000 }), 11000)   -- +40 ms, inside
assert(s.by_name.Haste == haste, "dead-band keeps the same Countdown")

-- Lengthened beyond the dead-band: re-anchor; Span is the longest ever seen
effects.effects(s, pkg(520000, { Haste = 50000, Shield = 580000 }), 21000)   -- +5 s
k = effects.keys(s, 21000)
eq(k.e1t, "00:50", "re-anchored to the new remaining")
eq(k.e1p, "76.9%", "Span stays at the original 65 s, not the new 50 s")
effects.effects(s, pkg(530000, { Haste = 120000, Shield = 570000 }), 31000)  -- past the old Span
k = effects.keys(s, 31000)
eq(k.e1t, "02:00", "lengthened again")
eq(k.e1p, "100%", "Span grows to the new longest")

-- Shortened beyond the dead-band: re-anchor, Span kept
effects.effects(s, pkg(540000, { Haste = 30000, Shield = 560000 }), 41000)
k = effects.keys(s, 41000)
eq(k.e1t, "00:30", "shortened")
eq(k.e1p, "25%", "Span still 120 s")

-- A snapshot that omits an effect drops it; one already lapsed on the Feed's clock never appears
effects.effects(s, pkg(550000, { Shield = 550000, Stale = -10 }), 51000)
k = effects.keys(s, 51000)
eq(k.e1n, "Shield", "only Shield left")
eq(k.e2d, "none", "Haste gone, Stale never shown")
eq(s.by_name.Stale, nil, "lapsed effect not kept")

-- An effect that comes back after Clearing anchors fresh
effects.effects(s, pkg(560000, { Shield = 540000, Haste = 10000 }), 61000)
k = effects.keys(s, 61000)
eq(k.e1n, "Haste", "Haste back")
eq(k.e1p, "100%", "fresh Span")

-- Pool overflow: 12 effects show 10 rows and "+2 more"
local many = {}
for i = 1, 12 do many["Eff" .. (i < 10 and "0" or "") .. i] = i * 10000 end
effects.effects(s, pkg(600000, many), 100000)
k = effects.keys(s, 100000)
eq(k.e1n, "Eff01", "overflow row 1")
eq(k.e10n, "Eff10", "overflow row 10")
eq(k.effMore, "+2 more", "overflow line")
effects.effects(s, pkg(600000, { A = 1000 }), 100000)
eq(effects.keys(s, 100000).effMore, "", "more line clears")

-- Ties sort by name so the order is stable
effects.effects(s, pkg(700000, { Zeta = 5000, Alpha = 5000, Mid = 5000 }), 200000)
k = effects.keys(s, 200000)
eq(k.e1n, "Alpha", "tie 1")
eq(k.e2n, "Mid", "tie 2")
eq(k.e3n, "Zeta", "tie 3")

-- Severed: rows kept, Countdowns frozen where they stood, tick is a no-op
effects.effects(s, pkg(800000, { Haste = 30000 }), 300000)
effects.sever(s, 310000)
k = effects.keys(s, 900000)
eq(k.hudState, "severed", "severed state")
eq(k.e1n, "Haste", "row kept")
eq(k.e1t, "00:20", "frozen at sever time")
eq(effects.tick(s, 900000), false, "tick does nothing while severed")
eq(s.by_name.Haste ~= nil, true, "still held while severed")
eq(effects.keys(s, 950000).e1t, "00:20", "still frozen")

-- Severing an Unfed widget leaves it Unfed
local u = effects.new()
effects.sever(u, 1)
eq(u.state, "unfed", "sever before first push")

-- nil package is ignored
effects.effects(s, nil, 1)
eq(effects.keys(s, 900000).e1n, "Haste", "nil push ignored")

print("effects_test: OK")
