-- Group: the view-model behind the Group widget - one row per member of
-- the reader's Group and per Ally of it (summons and Mercenaries), each with
-- its Condition as a bar and figures and a count of the effects on it that
-- help and that harm. Pure Lua 5.1 library: the wiring feeds it
-- Char.Vitals (the reader's own Condition), Char.Group, Char.Allies,
-- Char.Effects (the reader's own effects) and Char.OtherEffects, and
-- rewrites the widget whole from html() (ADR 0002); nothing here counts
-- down, so the server's re-push when an effect ends is what moves a count.
--
-- Rows: the reader first, then the reader's Allies under them, then each
-- other member in roster (join) order with their Allies under them; an
-- Ally whose owner is no row's is listed last. Out of a Group the reader's
-- row and their own Allies are the whole list.
local doc = require("doc")

local M = {}

function M.new()
  return { state = "unfed", me = nil, roster = {}, allies = {}, own = nil, others = {} }
end

local function live(s)
  s.state = "live"
  return s
end

-- Char.Vitals: only the reader's Condition is read here.
function M.vitals(s, pkg)
  if pkg == nil then return s end
  s.me = pkg.condition
  return live(s)
end

-- Char.Group: a bare array of members (ipairs at the door: feed arrays
-- reach Lua 0-based under t[i]).
function M.group(s, pkg)
  if pkg == nil then return s end
  local list = {}
  for _, m in ipairs(pkg) do
    if type(m) == "table" and m.name ~= nil then list[#list + 1] = m end
  end
  s.roster = list
  return live(s)
end

-- Char.Allies: a bare array of Allies, each with its owner.
function M.allies(s, pkg)
  if pkg == nil then return s end
  local list = {}
  for _, a in ipairs(pkg) do
    if type(a) == "table" and a.name ~= nil then list[#list + 1] = a end
  end
  s.allies = list
  return live(s)
end

-- One effect list as counts: `{good, bad, goodTip, badTip}`, each tip the
-- effects' names. An effect with no `helps` counts as neither.
local function count(effects)
  local c = { good = 0, bad = 0 }
  local good, bad = {}, {}
  for _, e in ipairs(effects or {}) do
    if type(e) == "table" and e.name ~= nil then
      if e.helps == true then good[#good + 1] = e.name
      elseif e.helps == false then bad[#bad + 1] = e.name end
    end
  end
  c.good, c.bad = #good, #bad
  c.goodTip = table.concat(good, ", ")
  c.badTip = table.concat(bad, ", ")
  return c
end

-- Char.Effects: the reader's own.
function M.effects(s, pkg)
  if pkg == nil then return s end
  s.own = count(pkg.effects)
  return live(s)
end

-- A Bearer's key: its kind and identity, as Char.OtherEffects and the
-- Group and Allies rows carry them (the name where no id rides).
local function key(kind, row)
  return kind .. ":" .. tostring(row.id or row.name)
end

-- Char.OtherEffects: `{bearers = {{kind, name, id, effects}, ...}}`.
function M.others(s, pkg)
  if pkg == nil then return s end
  local by = {}
  for _, b in ipairs(pkg.bearers or {}) do
    if type(b) == "table" and b.name ~= nil and b.kind ~= nil then
      by[key(b.kind, b)] = count(b.effects)
    end
  end
  s.others = by
  return live(s)
end

-- Connection lost: keep the rows as they stood.
function M.sever(s)
  if s.state == "live" then s.state = "severed" end
  return s
end

local function plural(n, one, many)
  if n == 1 then return "one " .. one end
  return tostring(n) .. " " .. many
end

-- Where a member is, as `group` words it, for the row's tooltip.
local function whereText(m)
  local w = m.where
  if w == "here" then return "here" end
  if w == "away" then
    local moves = tonumber(m.moves)
    local far = moves and plural(moves, "room", "rooms") .. " away" or "away"
    if m.exit ~= nil then return m.exit .. ", " .. far end
    return far
  end
  if w == "out_of_reach" then return "out of reach" end
  if w == "inside" then
    if m.delve ~= nil then return "inside " .. m.delve end
    return "inside"
  end
  if w == nil then return "" end
  return w
end

local NONE = { good = 0, bad = 0, goodTip = "", badTip = "" }

local function allyRow(s, a, owner)
  return {
    name = a.name, ally = true, cond = a.condition,
    tip = owner and (a.name .. ", " .. owner) or a.name,
    fx = s.others[key("ally", a)] or NONE,
  }
end

-- Every row in order, as plain tables (what html() draws):
-- { name, tip, you?, leader?, ally?, offline?, cond?, fx = {good, bad, goodTip, badTip} }
function M.rows(s)
  local rows = {}
  local mine, byOwner, owners = {}, {}, {}
  for _, a in ipairs(s.allies) do
    if a.owner == "you" then mine[#mine + 1] = a
    else
      local o = a.owner or ""
      if byOwner[o] == nil then byOwner[o] = {} end
      byOwner[o][#byOwner[o] + 1] = a
    end
  end
  local meRow = nil
  for _, m in ipairs(s.roster) do
    if m.you then meRow = m end
  end
  rows[#rows + 1] = {
    name = "You", you = true, leader = meRow ~= nil and meRow.leader == true,
    tip = meRow and meRow.name or "You", cond = s.me, fx = s.own or NONE,
  }
  for _, a in ipairs(mine) do rows[#rows + 1] = allyRow(s, a, "yours") end
  for _, m in ipairs(s.roster) do
    if not m.you then
      owners[m.name] = true
      local where = whereText(m)
      rows[#rows + 1] = {
        name = m.name, leader = m.leader == true, offline = m.where == "offline",
        tip = (where ~= "" and where ~= "here") and (m.name .. ": " .. where) or m.name,
        where = m.where, cond = m.condition, fx = s.others[key("member", m)] or NONE,
      }
      for _, a in ipairs(byOwner[m.name] or {}) do
        rows[#rows + 1] = allyRow(s, a, m.name .. "'s")
      end
    end
  end
  -- An Ally whose owner has no row (the roster not yet fed): listed last.
  for _, a in ipairs(s.allies) do
    if a.owner ~= "you" and not owners[a.owner or ""] then
      rows[#rows + 1] = allyRow(s, a, a.owner and (a.owner .. "'s") or nil)
    end
  end
  return rows
end

local function pct(cur, max)
  cur, max = tonumber(cur), tonumber(max)
  if cur == nil or max == nil or max <= 0 then return 0 end
  local p = cur / max * 100
  if p < 0 then p = 0 elseif p > 100 then p = 100 end
  return math.floor(p * 10 + 0.5) / 10
end

-- Condition's ladder is the five-rung tier ramp (shared.css), 1 best.
local function tier(c)
  local t = tonumber(c.tier)
  if t == nil then return "" end
  if t < 1 then t = 1 elseif t > 5 then t = 5 end
  return tostring(math.floor(t))
end

local function attr(name, value)
  if value == nil or value == "" then return "" end
  return " " .. name .. '="' .. doc.escape(value) .. '"'
end

local function figures(c)
  if c == nil or c.cur == nil then return "" end
  if c.max == nil then return tostring(c.cur) end
  return tostring(c.cur) .. "/" .. tostring(c.max)
end

-- One count: hidden at zero, so a row with nothing on it reads clean.
local function pill(cls, n, tip)
  if n == 0 then return '<span class="' .. cls .. ' z"></span>' end
  return '<span class="' .. cls .. '"' .. attr("title", tip) .. ">" .. n .. "</span>"
end

local function row(r)
  local cls = "gr" .. (r.ally and " ally" or "") .. (r.you and " you" or "") .. (r.offline and " off" or "")
    .. ((r.where ~= nil and r.where ~= "here" and not r.offline) and " away" or "")
  local name = '<span class="gn"' .. attr("title", r.tip) .. ">"
    .. (r.leader and '<span class="ld" title="Leader"></span>' or "")
    .. doc.escape(r.name) .. "</span>"
  local bar
  if r.cond ~= nil then
    bar = '<div class="bar"' .. attr("title", figures(r.cond)) .. '><div class="fill" data-tier="' .. tier(r.cond)
      .. '" style="width:' .. pct(r.cond.cur, r.cond.max) .. '%"></div><span class="word">'
      .. doc.escape(r.cond.name or "") .. "</span></div>"
  else
    bar = '<div class="bar empty"><span class="word">' .. (r.offline and "offline" or "") .. "</span></div>"
  end
  local fx = r.fx or NONE
  return '<div class="' .. cls .. '">' .. name .. bar
    .. '<span class="num">' .. doc.escape(figures(r.cond)) .. "</span>"
    .. '<span class="fx">' .. pill("good", fx.good, fx.goodTip) .. pill("bad", fx.bad, fx.badTip) .. "</span>"
    .. "</div>"
end

-- The widget's whole content, in `font` (the widget's own, see doc.fontStyle).
function M.html(s, font)
  local out = {}
  for _, r in ipairs(M.rows(s)) do out[#out + 1] = row(r) end
  return '<div class="hud grp" data-state="' .. s.state .. '"' .. doc.fontStyle(font) .. ">"
    .. table.concat(out) .. "</div>"
end

return M
