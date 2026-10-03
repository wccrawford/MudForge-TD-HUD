-- Pages: the view-model behind the Page widget - what `read` last printed
-- (Writing.Read, a page or a table of contents), kept in Recent so the
-- player can page back through what they read this connection.
-- Pure Lua 5.1 library, same shape as slots.lua (new / feed / sever) plus
-- act() for the widget's clicks and html() for its whole content (ADR 0002).
local recent = require("recent")
local doc = require("doc")

local M = {}

function M.new()
  return { state = "unfed", recent = recent.new(), listing = false }
end

local function copyRows(pages)
  local out = {}
  for _, r in ipairs(pages or {}) do
    if r.page ~= nil then
      out[#out + 1] = { page = r.page, title = r.title or "", section = r.section, rung = r.rung }
    end
  end
  return out
end

-- Writing.Read: `{kind = "page", writing, page, title, lines}` or
-- `{kind = "contents", writing, pages}`. It answers a `read` the player just
-- typed, so it always goes on show, even over an older entry being browsed.
function M.read(s, pkg)
  if pkg == nil or pkg.writing == nil then return s end
  local e
  if pkg.kind == "contents" then
    e = { kind = "contents", writing = pkg.writing, rows = copyRows(pkg.pages) }
    recent.put(s.recent, pkg.writing .. "#contents", e)
  elseif pkg.kind == "page" then
    e = { kind = "page", writing = pkg.writing, page = pkg.page, title = pkg.title or "", lines = doc.copy(pkg.lines) }
    recent.put(s.recent, pkg.writing .. "#" .. tostring(pkg.page), e)
  else
    return s
  end
  s.listing = false
  s.state = "live"
  return s
end

-- Connection lost: Recent is kept, only the state changes.
function M.sever(s)
  if s.state == "live" then s.state = "severed" end
  return s
end

-- A click in the widget (its `data-mud-action` / `data-mud-data`). Answers
-- the command to send the MUD, if the click asks for one: a contents row
-- reads its page, and Contents on a page reads its book's contents unless
-- they are already in Recent, which it shows instead.
function M.act(s, action, data)
  local r = s.recent
  if action == "older" then recent.older(r); s.listing = false
  elseif action == "newer" then recent.newer(r); s.listing = false
  elseif action == "recent" then s.listing = not s.listing and recent.count(r) > 0
  elseif action == "open" then recent.show(r, tonumber(data)); s.listing = false
  elseif action == "read" then
    local e = recent.shown(r)
    local n = tonumber(data)
    if e ~= nil and e.kind == "contents" and n ~= nil then
      return "read " .. e.writing .. " " .. n
    end
  elseif action == "contents" then
    local e = recent.shown(r)
    if e ~= nil and e.kind == "page" then
      local i = recent.find(r, e.writing .. "#contents")
      if i == nil then return "read " .. e.writing end
      recent.show(r, i)
      s.listing = false
    end
  end
  return nil
end

local function label(e)
  if e.kind == "contents" then return doc.escape(e.writing) .. " - contents" end
  return doc.escape(e.writing) .. " - p. " .. doc.escape(e.page)
end

-- `read <book>`'s contents, as read prints them: section headings, then
-- each page row clickable to read it, its rung in brackets.
local function contents(e)
  local out = { '<div class="ln"><span class="r-Heading">' .. doc.escape(e.writing) .. "</span></div>" }
  local heading = nil
  for _, row in ipairs(e.rows) do
    if row.section ~= nil and row.section ~= heading then
      heading = row.section
      out[#out + 1] = '<div class="ln sec"><span class="r-Heading">' .. doc.escape(heading) .. "</span></div>"
    end
    local rung = row.rung ~= nil and ('  <span class="sub">(' .. doc.escape(row.rung) .. ")</span>") or ""
    out[#out + 1] = '<div class="row" data-mud-action="read" data-mud-data="' .. doc.escape(row.page) .. '">'
      .. '<span class="pn">' .. doc.escape(row.page) .. ".</span>"
      .. '<span class="rl">' .. doc.escape(row.title) .. rung .. "</span></div>"
  end
  return table.concat(out)
end

-- The widget's whole content, in `font` (the widget's own, see doc.fontStyle).
function M.html(s, font)
  local r = s.recent
  local n = recent.count(r)
  local e = recent.shown(r)
  local v = { state = s.state, at = r.at, count = n, listing = s.listing, font = font }
  if e == nil then
    v.body = doc.empty("Nothing read yet.")
  elseif s.listing then
    local rows = {}
    for i, it in ipairs(recent.entries(r)) do
      rows[i] = { label = label(it), sub = it.kind == "page" and doc.escape(it.title) or nil }
    end
    v.label = "Recent pages"
    v.body = doc.recent(rows, r.at)
  else
    v.label = label(e)
    v.body = e.kind == "contents" and contents(e) or doc.lines(e.lines)
    if e.kind == "page" then v.tools = doc.button("Contents", "contents") end
  end
  return doc.frame(v)
end

return M
