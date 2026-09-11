-- Effects: the view-model behind the Effects widget (Active Effects as timer
-- rows, soonest first). Pure Lua 5.1 library, same shape as status.lua: the
-- wiring owns a state table from `new()`, feeds it Char.Effects snapshots and
-- the local clock, and pushes `keys()` through setBoundValues. Each effect
-- runs its own Countdown (CONTEXT.md); the markup is a fixed pool of POOL
-- rows flipped by bound values, never rebuilt (wayfinder #6).
local countdown = require("countdown")

local M = {}

M.POOL = 10                -- rows in the markup; beyond that only "+N more"
M.URGENT_MS = 5000         -- time and hairline turn red under this

function M.new()
  return { state = "unfed", by_name = {}, frozen_at = nil }
end

-- Char.Effects snapshot: `{ effects = { {name, ends_at_ms}, ... }, now_ms }`.
-- Walks the array with ipairs (feed arrays reach Lua 0-based under t[i]).
-- An Effect's Span is the longest remaining ever seen for its name while it
-- ran, so a re-push that lengthens it beyond the dead-band refills toward
-- that, not to the new remaining as a Round Time Stack would.
function M.effects(s, pkg, now)
  if pkg == nil then return s end
  local next_by_name = {}
  local now_ms = pkg.now_ms or 0
  for _, e in ipairs(pkg.effects or {}) do
    if e.name ~= nil and e.ends_at_ms ~= nil then
      local prev = s.by_name[e.name]
      local cd = countdown.push(prev, e.ends_at_ms - now_ms, now)
      if cd ~= nil and prev ~= nil and cd ~= prev and prev.span > cd.span then
        cd = { ends_at = cd.ends_at, span = prev.span }
      end
      if cd ~= nil then next_by_name[e.name] = cd end
    end
  end
  s.by_name = next_by_name
  s.state = "live"
  return s
end

-- The local tick; returns true when any Effect just reached Clear so the
-- caller knows its row must be pushed away.
function M.tick(s, now)
  if s.state == "severed" then return false end
  local cleared = false
  for name, cd in pairs(s.by_name) do
    if countdown.tick(cd, now) == nil then
      s.by_name[name] = nil
      cleared = true
    end
  end
  return cleared
end

-- True while any Effect is running, i.e. the tick has rows to drain.
-- (`next` is not in MudForge's sandbox; pairs is.)
function M.counting(s)
  for _ in pairs(s.by_name) do return true end
  return false
end

-- Connection lost: keep the rows, freeze every Countdown here.
function M.sever(s, now)
  if s.state == "live" then
    s.state = "severed"
    s.frozen_at = now
  end
  return s
end

-- Running Effects soonest first (name breaks ties so the order is stable).
local function sorted(s, now)
  local list = {}
  for name, cd in pairs(s.by_name) do
    if countdown.tick(cd, now) ~= nil then
      list[#list + 1] = { name = name, cd = cd }
    end
  end
  table.sort(list, function(a, b)
    if a.cd.ends_at ~= b.cd.ends_at then return a.cd.ends_at < b.cd.ends_at end
    return a.name < b.name
  end)
  return list
end

-- The complete bound-value key set for the Effects widget's markup:
-- hudState, effEmpty, effMore, and e<i>n / e<i>t / e<i>u / e<i>p / e<i>d
-- (name, mm:ss, urgency flag, hairline width, row display) for each pool row.
function M.keys(s, now)
  if s.state == "severed" and s.frozen_at ~= nil then now = s.frozen_at end
  local k = { hudState = s.state }
  local list = sorted(s, now)
  k.effEmpty = (s.state ~= "unfed" and #list == 0) and "" or "none"
  k.effMore = (#list > M.POOL) and ("+" .. (#list - M.POOL) .. " more") or ""
  for i = 1, M.POOL do
    local p = "e" .. i
    local e = list[i]
    if e ~= nil then
      local left = countdown.remaining(e.cd, now)
      k[p .. "n"] = e.name
      k[p .. "t"] = countdown.mmss(countdown.seconds(e.cd, now))
      k[p .. "u"] = (left < M.URGENT_MS) and 1 or 0
      k[p .. "p"] = countdown.pct(e.cd, now) .. "%"
      k[p .. "d"] = ""
    else
      k[p .. "n"] = ""
      k[p .. "t"] = ""
      k[p .. "u"] = 0
      k[p .. "p"] = "0%"
      k[p .. "d"] = "none"
    end
  end
  return k
end

return M
