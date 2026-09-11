-- Status: the view-model behind the Status widget (Condition / Focus /
-- Footing meters, Round Time bar, Standing + Encumbrance + held power).
-- Pure Lua 5.1 library: the wiring owns a state table from `new()`, feeds it
-- Feed snapshots and the local clock, and pushes `keys()` through
-- setBoundValues. Widget states are Unfed / Live / Severed (CONTEXT.md).
local countdown = require("countdown")

local M = {}

function M.new()
  return { state = "unfed", vitals = nil, rt = nil, frozen_at = nil }
end

-- Char.Vitals snapshot: the widget goes Live on its own package's first push.
function M.vitals(s, pkg)
  if pkg == nil then return s end
  s.vitals = pkg
  s.state = "live"
  return s
end

-- Char.RoundTime snapshot: `0` or an instant already passed means clear.
function M.roundtime(s, pkg, now)
  if pkg == nil then return s end
  local remaining = 0
  if pkg.clears_at_ms ~= nil and pkg.clears_at_ms ~= 0 then
    remaining = pkg.clears_at_ms - (pkg.now_ms or 0)
  end
  s.rt = countdown.push(s.rt, remaining, now)
  return s
end

-- The local tick; returns true when the Round Time just reached Clear so the
-- caller knows the bar must be pushed one last time.
function M.tick(s, now)
  if s.state == "severed" then return false end
  local had = s.rt ~= nil
  s.rt = countdown.tick(s.rt, now)
  return had and s.rt == nil
end

-- Connection lost: keep the last-known values, freeze the Countdown here.
function M.sever(s, now)
  if s.state == "live" then
    s.state = "severed"
    s.frozen_at = now
  end
  return s
end

local function pct(cur, max)
  if cur == nil or max == nil or max <= 0 then return 0 end
  local p = cur / max * 100
  if p < 0 then p = 0 elseif p > 100 then p = 100 end
  return math.floor(p * 10 + 0.5) / 10
end

local function meter(k, key, m)
  if m == nil then
    k[key .. "Name"] = ""
    k[key .. "Cur"] = ""
    k[key .. "Max"] = ""
    k[key .. "Tier"] = ""
    k[key .. "Pct"] = "0%"
    k[key .. "Tip"] = ""
    return
  end
  k[key .. "Name"] = m.name or ""
  k[key .. "Cur"] = m.cur == nil and "" or m.cur
  k[key .. "Max"] = m.max == nil and "" or m.max
  k[key .. "Tier"] = m.tier == nil and "" or m.tier
  k[key .. "Pct"] = pct(m.cur, m.max) .. "%"
  k[key .. "Tip"] = tostring(m.cur) .. "/" .. tostring(m.max)
end

-- The complete bound-value key set for the Status widget's markup.
function M.keys(s, now)
  local k = { hudState = s.state }
  local v = s.vitals or {}
  meter(k, "cond", v.condition)
  meter(k, "focus", v.focus)
  meter(k, "foot", v.footing)
  if v.power ~= nil then
    k.powerName = v.power.name or ""
    k.powerCur = v.power.cur == nil and "" or v.power.cur
    k.powerTier = v.power.tier == nil and "" or v.power.tier
    k.powerDisplay = ""
  else
    k.powerName = ""
    k.powerCur = ""
    k.powerTier = ""
    k.powerDisplay = "none"
  end
  k.standName = v.standing and v.standing.name or ""
  k.encum = v.encumbrance == nil and "" or v.encumbrance

  if s.state == "severed" and s.frozen_at ~= nil then now = s.frozen_at end
  local cd = countdown.tick(s.rt, now)
  if cd ~= nil then
    k.rtDisplay = ""
    k.rtPct = countdown.pct(cd, now) .. "%"
    k.rtSec = countdown.seconds(cd, now)
  else
    k.rtDisplay = "none"
    k.rtPct = "0%"
    k.rtSec = ""
  end
  return k
end

return M
