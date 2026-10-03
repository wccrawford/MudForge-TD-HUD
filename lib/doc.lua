-- Doc: markup for the reader widgets (Page, Quest), whose content is
-- rewritten whole on every change rather than flipped by bound values
-- (ADR 0002). Pure Lua 5.1 library: everything here returns a string.
-- Fed text is escaped on the way in; nothing fed ever reaches markup raw.
local M = {}

-- The twelve Roles a fed Span may carry (ADR 0058's role names); any other
-- name is drawn plain rather than trusted into a class attribute.
local ROLES = {
  Item = true, Character = true, Place = true, Exit = true, Speech = true,
  Refusal = true, Harm = true, Cue = true, Warning = true, Command = true,
  Act = true, Heading = true,
}

-- Fed `lines` copied into plain tables. Feed arrays reach Lua 0-based
-- under t[i] (wayfinder #6), so every list goes through ipairs at the door.
function M.copy(lines)
  local out = {}
  for _, line in ipairs(lines or {}) do
    local spans = {}
    for _, sp in ipairs(line) do
      if type(sp) == "table" then
        spans[#spans + 1] = { text = sp.text, role = sp.role, hang = sp.hang }
      end
    end
    out[#out + 1] = spans
  end
  return out
end

function M.escape(s)
  s = tostring(s or "")
  s = (s:gsub("&", "&amp;"))
  s = (s:gsub("<", "&lt;"))
  s = (s:gsub(">", "&gt;"))
  s = (s:gsub('"', "&quot;"))
  return s
end

-- A widget's own font, as getWidgetFont answers it (`{family, size, weight}`,
-- the widget's settings cog), as the three bound style keys a bound
-- widget's root carries: fontSize, fontFamily, fontWeight. Absent parts
-- are left to the stylesheet ("" clears a bound style).
function M.fontKeys(font)
  font = font or {}
  return {
    fontSize = font.size ~= nil and (tostring(font.size) .. "px") or "",
    fontFamily = font.family or "",
    fontWeight = font.weight ~= nil and tostring(font.weight) or "",
  }
end

-- The same font as an inline style attribute, for a widget whose markup
-- is rewritten whole; "" when there is none.
function M.fontStyle(font)
  local k = M.fontKeys(font)
  local out = {}
  if k.fontSize ~= "" then out[#out + 1] = "font-size:" .. k.fontSize end
  if k.fontFamily ~= "" then out[#out + 1] = "font-family:" .. k.fontFamily end
  if k.fontWeight ~= "" then out[#out + 1] = "font-weight:" .. k.fontWeight end
  if #out == 0 then return "" end
  return ' style="' .. M.escape(table.concat(out, ";")) .. '"'
end

-- One fed line, a list of Spans `{text, role?}` or hangs `{hang = n}`: its
-- words as role-classed spans, wrapped continuations starting at the last
-- hang's column (ADR 0058: a line with none hangs at 0).
function M.line(spans)
  local out, hang = {}, 0
  for _, sp in ipairs(spans or {}) do
    if type(sp) == "table" then
      if sp.hang ~= nil then
        hang = tonumber(sp.hang) or 0
      elseif sp.text ~= nil and sp.text ~= "" then
        local text = M.escape(sp.text)
        if sp.role ~= nil and ROLES[sp.role] then
          out[#out + 1] = '<span class="r-' .. sp.role .. '">' .. text .. "</span>"
        else
          out[#out + 1] = text
        end
      end
    end
  end
  local style = ""
  if hang > 0 then
    style = ' style="padding-left:' .. hang .. "ch;text-indent:-" .. hang .. 'ch"'
  end
  return '<div class="ln"' .. style .. ">" .. table.concat(out) .. "</div>"
end

-- Every fed line, in order.
function M.lines(lines)
  local out = {}
  for _, l in ipairs(lines or {}) do out[#out + 1] = M.line(l) end
  return table.concat(out)
end

-- A clickable control: `data-mud-action` fires the widget's `action` event
-- (MudForge); a control that cannot act now is drawn dimmed with no action.
function M.button(label, action, data, on, enabled, extra)
  local cls = "btn" .. (on and " on" or "") .. (extra and (" " .. extra) or "")
  if enabled == false then
    return '<span class="' .. cls .. ' off">' .. label .. "</span>"
  end
  local d = data ~= nil and (' data-mud-data="' .. M.escape(data) .. '"') or ""
  return '<span class="' .. cls .. '" data-mud-action="' .. action .. '"' .. d .. ">" .. label .. "</span>"
end

-- The reader frame: widget state for the shared dimming, a navigation bar
-- over Recent, then the body.
--   v = { state, at, count, listing, label, tools?, body, font? }
-- `at`/`count` place the shown entry in Recent (1 = newest); `listing` is
-- true while the Recent list is the body; `tools` is markup for the
-- widget's own buttons, set just before Recent; `font` the widget's own
-- (see fontStyle).
function M.frame(v)
  local bar = {
    M.button("&lsaquo;", "older", nil, false, v.at < v.count, "nav"),
    M.button("&rsaquo;", "newer", nil, false, v.at > 1, "nav"),
    '<span class="pos">' .. (v.count > 0 and (v.at .. "/" .. v.count) or "") .. "</span>",
    '<span class="lbl">' .. (v.label or "") .. "</span>",
    v.tools or "",
    M.button("Recent", "recent", nil, v.listing, v.count > 0),
  }
  return '<div class="hud rd" data-state="' .. v.state .. '"' .. M.fontStyle(v.font) .. ">"
    .. '<div class="bar">' .. table.concat(bar) .. "</div>"
    .. '<div class="body">' .. (v.body or "") .. "</div></div>"
end

-- The Recent list as a body: one row per entry, newest first, the shown
-- one marked; a row opens its entry. rows = { {label, sub?}, ... }
function M.recent(rows, at)
  local out = {}
  for i, row in ipairs(rows) do
    local sub = row.sub and ('<span class="sub">' .. row.sub .. "</span>") or ""
    out[#out + 1] = '<div class="row' .. (i == at and " cur" or "") .. '" data-mud-action="open" data-mud-data="' .. i .. '">'
      .. '<span class="rl">' .. row.label .. "</span>" .. sub .. "</div>"
  end
  return table.concat(out)
end

-- The body of a widget with nothing to show yet.
function M.empty(text)
  return '<div class="none">' .. M.escape(text) .. "</div>"
end

return M
