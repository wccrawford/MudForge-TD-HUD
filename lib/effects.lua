-- Effects: the view-model behind the Effects widget (Active Effects as timer
-- rows). Pure Lua 5.1 library, same shape as status.lua: the wiring owns a
-- state table from `new()`, feeds it Char.Effects (the reader's own) and
-- Char.OtherEffects (the Group's members and Allies) snapshots and the local
-- clock, and pushes `keys()` through setBoundValues. Each effect runs its own
-- Countdown (CONTEXT.md); the markup is a fixed pool of POOL rows flipped by
-- bound values, never rebuilt (wayfinder #6).
--
-- Rows run the reader's own effects first, then each other Bearer's in the
-- feed's order, each Bearer's soonest first. While any other Bearer has a
-- row, every Bearer's first row carries its name above it ("You" for the
-- reader); with only the reader's own, no names are drawn.
local countdown = require("countdown")

local M = {}

M.POOL = 16                -- rows in the markup; beyond that only "+N more"
M.URGENT_MS = 5000         -- time and hairline turn red under this
-- A remaining past this is no deadline: the server ships a fight-bound
-- effect's end as u64::MAX (THIS_FIGHT_MS), which reaches Lua as 2^64, and
-- marks it `this_fight`. `status` prints those "(this fight)"; so does the row.
M.FIGHT_MS = 2^53
local FIGHT_LEFT = 2^64

-- The bearers of Char.OtherEffects this widget shows: the Group's members
-- and Allies. Foes are the fight's, not the side's.
local SHOWN = { member = true, ally = true }

function M.new()
  return { state = "unfed", by_name = {}, others = {}, frozen_at = nil }
end

-- One effect list anchored against the previous one: name -> entry
-- `{cd, helps, does}`. An Effect's Span is the longest remaining ever seen
-- for its name while it ran, so a re-push that lengthens it beyond the
-- dead-band refills toward that, not to the new remaining as a Round Time
-- Stack would. Walks the array with ipairs (feed arrays reach Lua 0-based
-- under t[i]).
local function anchor(prev_by_name, list, now_ms, now)
  local by_name = {}
  for _, e in ipairs(list or {}) do
    if e.name ~= nil and e.ends_at_ms ~= nil then
      local prev = prev_by_name[e.name]
      local pcd = prev and prev.cd or nil
      local left = e.ends_at_ms - now_ms
      if e.this_fight == true then left = FIGHT_LEFT end
      local cd = countdown.push(pcd, left, now)
      if cd ~= nil and pcd ~= nil and cd ~= pcd and pcd.span > cd.span then
        cd = { ends_at = cd.ends_at, span = pcd.span }
      end
      if cd ~= nil then
        local helps = nil
        if e.helps == true or e.helps == false then helps = e.helps end
        by_name[e.name] = { cd = cd, helps = helps, does = e.does }
      end
    end
  end
  return by_name
end

-- Char.Effects snapshot: `{ effects = { {name, helps?, does?, this_fight?,
-- ends_at_ms}, ... }, now_ms }`.
function M.effects(s, pkg, now)
  if pkg == nil then return s end
  s.by_name = anchor(s.by_name, pkg.effects, pkg.now_ms or 0, now)
  s.state = "live"
  return s
end

-- A Bearer's name as its rows head it: a member's own name, an Ally's with
-- whose it is.
local function label(b)
  if b.kind ~= "ally" or b.owner == nil then return b.name end
  if b.owner == "you" then return b.name .. " (yours)" end
  return b.name .. " (" .. b.owner .. "'s)"
end

-- Char.OtherEffects snapshot: `{ bearers = { {kind, name, id, owner?,
-- effects}, ... }, now_ms }`. A Bearer is known by kind and id, so two
-- Allies sharing a name keep their own Countdowns.
function M.others(s, pkg, now)
  if pkg == nil then return s end
  local prev = {}
  for _, b in ipairs(s.others) do prev[b.key] = b end
  local list = {}
  for _, b in ipairs(pkg.bearers or {}) do
    if SHOWN[b.kind] and b.name ~= nil then
      local key = b.kind .. ":" .. tostring(b.id or b.name)
      local p = prev[key]
      list[#list + 1] = {
        key = key,
        label = label(b),
        by_name = anchor(p and p.by_name or {}, b.effects, pkg.now_ms or 0, now),
      }
    end
  end
  s.others = list
  s.state = "live"
  return s
end

local function drain(by_name, now)
  local cleared = false
  for name, e in pairs(by_name) do
    if countdown.tick(e.cd, now) == nil then
      by_name[name] = nil
      cleared = true
    end
  end
  return cleared
end

local function any(by_name)
  for _ in pairs(by_name) do return true end
  return false
end

-- The local tick; returns true when any Effect just reached Clear so the
-- caller knows its row must be pushed away.
function M.tick(s, now)
  if s.state == "severed" then return false end
  local cleared = drain(s.by_name, now)
  for _, b in ipairs(s.others) do
    if drain(b.by_name, now) then cleared = true end
  end
  return cleared
end

-- True while any Effect is running, i.e. the tick has rows to drain.
-- (`next` is not in MudForge's sandbox; pairs is.)
function M.counting(s)
  if any(s.by_name) then return true end
  for _, b in ipairs(s.others) do
    if any(b.by_name) then return true end
  end
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

-- One Bearer's running Effects soonest first (name breaks ties so the order
-- is stable).
local function sorted(by_name, now)
  local list = {}
  for name, e in pairs(by_name) do
    if countdown.tick(e.cd, now) ~= nil then
      list[#list + 1] = { name = name, cd = e.cd, helps = e.helps, does = e.does }
    end
  end
  table.sort(list, function(a, b)
    if a.cd.ends_at ~= b.cd.ends_at then return a.cd.ends_at < b.cd.ends_at end
    return a.name < b.name
  end)
  return list
end

-- What an effect does, as its row's tooltip: "Helps: raises your
-- resistance to fire", "Harms", or "".
local function tip(e)
  local sign = ""
  if e.helps == true then sign = "Helps" elseif e.helps == false then sign = "Harms" end
  if e.does == nil or e.does == "" then return sign end
  if sign == "" then return e.does end
  return sign .. ": " .. e.does
end

local function helpsKey(helps)
  if helps == true then return "1" elseif helps == false then return "0" end
  return ""
end

-- Every row in order: { bearer label or nil, effect }.
local function rows(s, now)
  local out = {}
  local others = {}
  for _, b in ipairs(s.others) do
    local list = sorted(b.by_name, now)
    if #list > 0 then others[#others + 1] = { label = b.label, list = list } end
  end
  local named = #others > 0
  for i, e in ipairs(sorted(s.by_name, now)) do
    out[#out + 1] = { bearer = (named and i == 1) and "You" or nil, e = e }
  end
  for _, b in ipairs(others) do
    for i, e in ipairs(b.list) do
      out[#out + 1] = { bearer = (i == 1) and b.label or nil, e = e }
    end
  end
  return out
end

-- The complete bound-value key set for the Effects widget's markup:
-- hudState, effEmpty, effMore, and per pool row e<i>n / e<i>t / e<i>u /
-- e<i>p / e<i>d (name, mm:ss, urgency flag, hairline width, row display),
-- e<i>h / e<i>w (helps "1", harms "0" or unknown "", and the tooltip saying
-- what it does) and e<i>b / e<i>bd (the Bearer's name over its first row,
-- and that line's display).
function M.keys(s, now)
  if s.state == "severed" and s.frozen_at ~= nil then now = s.frozen_at end
  local k = { hudState = s.state }
  local list = rows(s, now)
  k.effEmpty = (s.state ~= "unfed" and #list == 0) and "" or "none"
  k.effMore = (#list > M.POOL) and ("+" .. (#list - M.POOL) .. " more") or ""
  for i = 1, M.POOL do
    local p = "e" .. i
    local r = list[i]
    if r ~= nil then
      local e = r.e
      local left = countdown.remaining(e.cd, now)
      local fight = left >= M.FIGHT_MS
      k[p .. "n"] = e.name
      k[p .. "t"] = fight and "this fight" or countdown.mmss(countdown.seconds(e.cd, now))
      k[p .. "u"] = (left < M.URGENT_MS) and 1 or 0
      k[p .. "p"] = fight and "100%" or (countdown.pct(e.cd, now) .. "%")
      k[p .. "d"] = ""
      k[p .. "h"] = helpsKey(e.helps)
      k[p .. "w"] = tip(e)
      k[p .. "b"] = r.bearer or ""
      k[p .. "bd"] = r.bearer and "" or "none"
    else
      k[p .. "n"] = ""
      k[p .. "t"] = ""
      k[p .. "u"] = 0
      k[p .. "p"] = "0%"
      k[p .. "d"] = "none"
      k[p .. "h"] = ""
      k[p .. "w"] = ""
      k[p .. "b"] = ""
      k[p .. "bd"] = "none"
    end
  end
  return k
end

return M
