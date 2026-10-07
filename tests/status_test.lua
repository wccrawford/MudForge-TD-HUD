local status = require("status")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function vitals(over)
  local v = {
    condition = { name = "Wounded", tier = 2, of = 5, cur = 68, max = 100 },
    footing = { name = "steady", tier = 3, of = 7, cur = 90, max = 100 },
    stamina = { name = "a bit winded", tier = 2, of = 5, cur = 62, max = 100 },
    focus = { name = "clouded", tier = 3, of = 5, cur = 14, max = 60 },
    standing = { name = "Journeyman", tier = 3, of = 5 },
    encumbrance = 35,
    hp = 68, maxhp = 100, mana = 14, maxmana = 60,
  }
  for key, val in pairs(over or {}) do v[key] = val end
  return v
end

-- Unfed: skeleton with blanks, no RT bar, no power line
local s = status.new()
local k = status.keys(s, 1000)
eq(k.hudState, "unfed", "unfed state")
eq(k.condName, "", "unfed cond name")
eq(k.condCur, "", "unfed cond cur")
eq(k.condPct, "0%", "unfed cond pct")
eq(k.condTier, "", "unfed cond tier")
eq(k.focusTip, "", "unfed focus tip")
eq(k.footMark, "0%", "unfed footing mark")
eq(k.stamName, "", "unfed stamina name")
eq(k.stamPct, "0%", "unfed stamina pct")
eq(k.standName, "", "unfed standing")
eq(k.encum, "", "unfed encumbrance")
eq(k.powerDisplay, "none", "unfed power hidden")
eq(k.rtPct, "0%", "unfed rt empty")
eq(k.rtSec, "", "unfed rt sec")

-- Live on the first Char.Vitals
status.vitals(s, vitals())
k = status.keys(s, 1000)
eq(k.hudState, "live", "live after vitals")
eq(k.condName, "Wounded", "cond name")
eq(k.condCur, 68, "cond cur")
eq(k.condMax, 100, "cond max")
eq(k.condTier, 2, "cond tier")
eq(k.condPct, "68%", "cond pct")
eq(k.condTip, "68/100", "cond tip")
eq(k.focusPct, "23.3%", "focus pct one decimal")
eq(k.focusTier, 3, "focus tier")
eq(k.footName, "steady", "footing name")
eq(k.footTier, 1, "footing at the mark rides the ramp's top rung")
eq(k.footPct, "60%", "footing fills over its cap of 150")
eq(k.footMark, "66.7%", "footing mark at 100 of 150")
eq(k.footTip, "90/100", "footing tip")
eq(k.stamName, "a bit winded", "stamina name")
eq(k.stamTier, 2, "stamina tier")
eq(k.stamPct, "62%", "stamina pct")
eq(k.stamCur, 62, "stamina cur")
eq(k.stamMax, 100, "stamina max")
eq(k.standName, "Journeyman", "standing name")
eq(k.encum, 35, "encumbrance")
eq(k.powerDisplay, "none", "no power key -> hidden")
eq(k.powerName, "", "no power name")
eq(k.rtPct, "0%", "no rt yet")

-- Held power present (no max key)
status.vitals(s, vitals({ power = { name = "a moderate charge", tier = 3, of = 4, cur = 8 } }))
k = status.keys(s, 1000)
eq(k.powerDisplay, "", "power shown")
eq(k.powerName, "a moderate charge", "power name")
eq(k.powerCur, 8, "power cur")
eq(k.powerTier, 3, "power tier")

-- Footing above its mark: the two rungs over it, and the surplus figure
status.vitals(s, vitals({ footing = { name = "incredibly balanced", tier = 1, of = 7, cur = 150, max = 100 } }))
k = status.keys(s, 1000)
eq(k.footTier, "over2", "incredibly balanced is two over")
eq(k.footPct, "100%", "footing at the cap is full")
eq(k.footCur, 150, "footing cur past max")
eq(k.footTip, "150/100", "footing tip past max")
status.vitals(s, vitals({ footing = { name = "well balanced", tier = 2, of = 7, cur = 118, max = 100 } }))
eq(status.keys(s, 1000).footTier, "over1", "well balanced is one over")
status.vitals(s, vitals({ footing = { name = "about to fall", tier = 7, of = 7, cur = 2, max = 100 } }))
eq(status.keys(s, 1000).footTier, 5, "about to fall is the ramp's worst")

-- A Feed without Stamina leaves its row blank
local noStamina = vitals()
noStamina.stamina = nil
status.vitals(s, noStamina)
k = status.keys(s, 1000)
eq(k.stamName, "", "no stamina key -> blank")

-- Zero and full meters
status.vitals(s, vitals({ condition = { name = "Dying", tier = 5, of = 5, cur = 0, max = 100 },
                          focus = { name = "sharp", tier = 1, of = 5, cur = 60, max = 60 } }))
k = status.keys(s, 1000)
eq(k.condPct, "0%", "zero pct")
eq(k.condCur, 0, "zero cur is a number, not blank")
eq(k.focusPct, "100%", "full pct")

-- Round Time: anchored at arrival against the local clock, seconds rounded up
status.roundtime(s, { clears_at_ms = 5000, now_ms = 2000 }, 10000)   -- 3 s left
k = status.keys(s, 10000)
eq(k.rtPct, "100%", "rt full at anchor")
eq(k.rtSec, 3, "rt 3 s")
k = status.keys(s, 11500)
eq(k.rtPct, "50%", "rt half")
eq(k.rtSec, 2, "rt 1.5 s reads 2")
k = status.keys(s, 12950)
eq(k.rtSec, 1, "rt 50 ms reads 1")

-- The tick reports the Clear exactly once
eq(status.tick(s, 12999), false, "not clear yet")
eq(status.tick(s, 13000), true, "clear on this tick")
eq(status.tick(s, 13100), false, "already clear")
k = status.keys(s, 13100)
eq(k.rtPct, "0%", "rt empty after clear")
eq(k.rtSec, "", "rt sec blank after clear")

-- Lapse pushes: 0 and a past instant clear; a late one after local Clear is a no-op
status.roundtime(s, { clears_at_ms = 5000, now_ms = 2000 }, 20000)
status.roundtime(s, { clears_at_ms = 0, now_ms = 3000 }, 20500)
eq(status.keys(s, 20500).rtPct, "0%", "clears_at_ms 0 clears")
status.roundtime(s, { clears_at_ms = 5000, now_ms = 2000 }, 30000)
status.roundtime(s, { clears_at_ms = 5000, now_ms = 5000 }, 30500)
eq(status.keys(s, 30500).rtPct, "0%", "clears_at_ms <= now_ms clears")
status.roundtime(s, { clears_at_ms = 0, now_ms = 9000 }, 40000)
eq(status.keys(s, 40000).rtPct, "0%", "late lapse after clear is a no-op")

-- Stack refills the bar
status.roundtime(s, { clears_at_ms = 5000, now_ms = 2000 }, 50000)
status.keys(s, 52000)
status.roundtime(s, { clears_at_ms = 7000, now_ms = 4000 }, 52000)   -- 3 s again at 1 s left
k = status.keys(s, 52000)
eq(k.rtPct, "100%", "stack refills")
eq(k.rtSec, 3, "stack seconds")

-- A missing / nil package is ignored
status.roundtime(s, nil, 52100)
eq(status.keys(s, 52100).rtSec, 3, "nil rt push ignored")
status.vitals(s, nil)
eq(status.keys(s, 52100).hudState, "live", "nil vitals push ignored")

-- Severed: last-known values kept, Countdown frozen where it stood
status.sever(s, 53000)
k = status.keys(s, 53000)
eq(k.hudState, "severed", "severed state")
eq(k.condName, "Dying", "severed keeps values")
eq(k.rtSec, 2, "severed rt frozen at 2 s")
k = status.keys(s, 99000)
eq(k.rtSec, 2, "still 2 s much later")
eq(k.rtPct ~= "0%", true, "frozen bar stays filled")
eq(status.tick(s, 99000), false, "ticks do nothing while severed")

-- Severing an Unfed widget leaves it Unfed
local u = status.new()
status.sever(u, 100)
eq(status.keys(u, 100).hudState, "unfed", "unfed stays unfed on disconnect")

-- new() is the reset back to Unfed
s = status.new()
eq(status.keys(s, 0).hudState, "unfed", "reset")

print("status_test: OK")
