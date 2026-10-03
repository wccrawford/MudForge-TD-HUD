-- Quests: the view-model behind the Quest widget - the last quest the
-- player pulled up (Quest.Show, kept current by the server), with the ones
-- pulled up before it kept in Recent as they last stood.
-- Pure Lua 5.1 library, same shape as pages.lua (ADR 0002).
local recent = require("recent")
local doc = require("doc")

local M = {}

function M.new()
  return { state = "unfed", recent = recent.new(), listing = false }
end

-- Quest.Show `{title, status, lines}`. The server re-sends it unasked as the
-- quest moves (and on a resync): the same quest at the head is refreshed in
-- place and whatever the player is browsing stays on show. A different
-- quest was just pulled up, so it goes on show.
function M.show(s, pkg)
  if pkg == nil or pkg.title == nil then return s end
  local e = { title = pkg.title, status = pkg.status or "", lines = doc.copy(pkg.lines) }
  if not recent.refresh(s.recent, pkg.title, e) then
    recent.put(s.recent, pkg.title, e)
    s.listing = false
  end
  s.state = "live"
  return s
end

function M.sever(s)
  if s.state == "live" then s.state = "severed" end
  return s
end

-- A click in the widget; never asks the MUD for anything.
function M.act(s, action, data)
  local r = s.recent
  if action == "older" then recent.older(r); s.listing = false
  elseif action == "newer" then recent.newer(r); s.listing = false
  elseif action == "recent" then s.listing = not s.listing and recent.count(r) > 0
  elseif action == "open" then recent.show(r, tonumber(data)); s.listing = false
  end
  return nil
end

-- A status word as a class: `in progress` -> `st-in-progress`.
local function status(e)
  local cls = (e.status:gsub("[^%w]+", "-"))
  return '<span class="st st-' .. cls .. '">' .. doc.escape(e.status) .. "</span>"
end

-- The widget's whole content, in `font` (the widget's own, see doc.fontStyle).
function M.html(s, font)
  local r = s.recent
  local n = recent.count(r)
  local e = recent.shown(r)
  local v = { state = s.state, at = r.at, count = n, listing = s.listing, font = font }
  if e == nil then
    v.body = doc.empty("No quest pulled up yet.")
  elseif s.listing then
    local rows = {}
    for i, it in ipairs(recent.entries(r)) do
      rows[i] = { label = doc.escape(it.title), sub = status(it) }
    end
    v.label = "Recent quests"
    v.body = doc.recent(rows, r.at)
  else
    v.label = status(e)
    v.body = doc.lines(e.lines)
    -- Only the head is kept current by the server; an older one is a snapshot.
    if r.at > 1 then
      v.body = v.body .. '<div class="note">As last shown. Type <span class="r-Command">quests show</span> to bring it up to date.</div>'
    end
  end
  return doc.frame(v)
end

return M
