-- Countdown: a widget-side clock that drains toward an instant the Feed named.
-- Pure Lua 5.1 library: no globals, no clock (`now` is always an argument),
-- library-sandbox stdlib only (no Lua patterns, no string.format widths).
--
-- A Countdown is `{ ends_at = ms, span = ms }` on the caller's clock, or nil
-- when Clear. Policy (CONTEXT.md, wayfinder #7): anchor at arrival, 100 ms
-- dead-band, a Stack refills the Span, local Clear is authoritative.
local M = {}

M.DEAD_BAND_MS = 100

-- Apply a push carrying `remaining` ms (already `end - now_ms` from the Feed's
-- own clock). Returns the Countdown to keep. A push of nothing left clears.
function M.push(cd, remaining, now)
  if remaining == nil or remaining <= 0 then return nil end
  local ends_at = now + remaining
  if cd ~= nil and cd.ends_at > now then
    local delta = ends_at - cd.ends_at
    if delta >= -M.DEAD_BAND_MS and delta <= M.DEAD_BAND_MS then return cd end
    -- A Stack (lengthened) refills the bar; a shortening keeps the Span.
    local span = cd.span
    if delta > 0 then span = remaining end
    return { ends_at = ends_at, span = span }
  end
  return { ends_at = ends_at, span = remaining }
end

-- Advance the local clock: nil once the Countdown has reached Clear.
function M.tick(cd, now)
  if cd == nil or cd.ends_at <= now then return nil end
  return cd
end

-- Milliseconds left, never negative; 0 when nil.
function M.remaining(cd, now)
  if cd == nil then return 0 end
  local left = cd.ends_at - now
  if left < 0 then left = 0 end
  return left
end

-- Whole seconds, rounded up: reads `1` until the instant of Clear, never `0`.
function M.seconds(cd, now)
  return math.ceil(M.remaining(cd, now) / 1000)
end

-- Fill percentage of a draining bar (0..100, one decimal).
function M.pct(cd, now)
  if cd == nil or cd.span <= 0 then return 0 end
  local p = M.remaining(cd, now) / cd.span * 100
  if p > 100 then p = 100 end
  return math.floor(p * 10 + 0.5) / 10
end

local function pad2(n)
  if n < 10 then return "0" .. n end
  return "" .. n
end

-- Whole seconds -> "mm:ss". Negative counts as zero.
function M.mmss(seconds)
  if seconds < 0 then seconds = 0 end
  seconds = math.floor(seconds)
  local m = math.floor(seconds / 60)
  return pad2(m) .. ":" .. pad2(seconds - m * 60)
end

return M
