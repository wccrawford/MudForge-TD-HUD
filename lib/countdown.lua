-- Countdown: a widget-side clock that drains toward an instant the Feed named.
-- Pure Lua 5.1 library: no globals, no clock (`now` is always an argument),
-- library-sandbox stdlib only (no Lua patterns, no string.format widths).
local M = {}

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
