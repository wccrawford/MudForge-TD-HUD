-- Slots: the view-model behind the Slots widget (every worn and held Slot
-- of the character's Race as a ledger, `label | item`, empties dimmed with a
-- dash the markup draws from the empty flag; bound text is ASCII only, since
-- MudForge's Lua-to-JS bridge shows a UTF-8 string's bytes as Latin-1).
-- Pure Lua 5.1 library, same shape as status.lua: the wiring owns a state
-- table from `new()`, feeds it Char.Items snapshots, and pushes `keys()`
-- through setBoundValues. No Countdown here, so no clock and no tick; the
-- markup is a fixed pool of POOL rows flipped by bound values, never rebuilt
-- (wayfinder #6). Order is the Feed's, which is the Race's (wayfinder #4).
local M = {}

M.POOL = 16                -- rows in the markup; beyond that only "+N more"

function M.new()
  return { state = "unfed", slots = {} }
end

-- Char.Items snapshot: `{ slots = { {slot, instance, item|null}, ... } }`.
-- Walks the array with ipairs (feed arrays reach Lua 0-based under t[i]) and
-- keeps only what the ledger shows; `instance` is dropped. A Race with no
-- Slots is an empty list, which is still Live.
function M.items(s, pkg)
  if pkg == nil then return s end
  local list = {}
  for _, e in ipairs(pkg.slots or {}) do
    if e.slot ~= nil then
      list[#list + 1] = { label = e.slot, item = e.item }
    end
  end
  s.slots = list
  s.state = "live"
  return s
end

-- Connection lost: keep the last-known ledger, only the state changes.
function M.sever(s)
  if s.state == "live" then s.state = "severed" end
  return s
end

-- The complete bound-value key set for the Slots widget's markup:
-- hudState, slotsEmpty, slotsMore, and s<i>l / s<i>i / s<i>e / s<i>d
-- (label, item, empty flag, row display) for each pool row.
function M.keys(s)
  local k = { hudState = s.state }
  local n = #s.slots
  k.slotsEmpty = (s.state ~= "unfed" and n == 0) and "" or "none"
  k.slotsMore = (n > M.POOL) and ("+" .. (n - M.POOL) .. " more") or ""
  for i = 1, M.POOL do
    local p = "s" .. i
    local e = s.slots[i]
    if e ~= nil then
      k[p .. "l"] = e.label
      k[p .. "i"] = e.item ~= nil and e.item or ""
      k[p .. "e"] = (e.item == nil) and 1 or 0
      k[p .. "d"] = ""
    else
      k[p .. "l"] = ""
      k[p .. "i"] = ""
      k[p .. "e"] = 1
      k[p .. "d"] = "none"
    end
  end
  return k
end

return M
