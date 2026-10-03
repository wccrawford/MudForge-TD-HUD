-- Recent: the newest-first list of the last few documents a reader widget
-- was fed, and which of them is on show (CONTEXT.md: Recent, On show).
-- Pure Lua 5.1 library shared by pages.lua and quests.lua: each entry is
-- the caller's table, found again by the `key` it was put under.
local M = {}

M.LIMIT = 10               -- entries kept; the oldest falls off the end

function M.new(limit)
  return { items = {}, at = 0, limit = limit or M.LIMIT }
end

local function indexOf(r, key)
  for i, it in ipairs(r.items) do
    if it.key == key then return i end
  end
  return nil
end

-- Where the entry under `key` stands (1 = newest), or nil.
M.find = indexOf

-- Put `entry` at the head under `key` and show it. An entry already under
-- that key is taken out first, so a document re-fed moves up, never twice.
function M.put(r, key, entry)
  local i = indexOf(r, key)
  if i ~= nil then table.remove(r.items, i) end
  table.insert(r.items, 1, { key = key, entry = entry })
  while #r.items > r.limit do table.remove(r.items) end
  r.at = 1
  return r
end

-- Replace the head's entry in place when it is under `key`; whatever is on
-- show stays on show. Answers whether it did.
function M.refresh(r, key, entry)
  local head = r.items[1]
  if head == nil or head.key ~= key then return false end
  head.entry = entry
  return true
end

-- The entry on show, or nil while Recent is empty.
function M.shown(r)
  local it = r.items[r.at]
  return it and it.entry
end

function M.count(r)
  return #r.items
end

-- Show entry `i` (1 = newest); out of range is ignored.
function M.show(r, i)
  if i ~= nil and i >= 1 and i <= #r.items then r.at = i end
  return r
end

function M.older(r) return M.show(r, r.at + 1) end
function M.newer(r) return M.show(r, r.at - 1) end

-- Every entry, newest first, as { entry, ... }.
function M.entries(r)
  local out = {}
  for i, it in ipairs(r.items) do out[i] = it.entry end
  return out
end

return M
