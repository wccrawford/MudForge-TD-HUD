-- Bar: the view-model behind the Windows bar - one button per HUD window,
-- each opening its window. MudForge has no way yet to bring back a custom
-- window the player closed, so this bar is how they do it, and the wiring
-- shows the bar itself on every start (ADR 0002 for the markup). It only
-- opens: MudForge tells a plugin nothing when a window is closed from its
-- own chrome, so a toggle could not know which way to go.
-- Pure Lua 5.1 library: act() answers which window a click opens.
local doc = require("doc")

local M = {}

-- windows = { {name, title}, ... } in bar order.
function M.new(windows)
  local s = { windows = {} }
  for i, w in ipairs(windows) do
    s.windows[i] = { name = w.name, title = w.title }
  end
  return s
end

-- A click: `open` on a window the bar holds answers its name.
function M.act(s, action, data)
  if action ~= "open" then return nil end
  for _, w in ipairs(s.windows) do
    if w.name == data then return w.name end
  end
  return nil
end

-- The bar's whole content, in `font` (the widget's own, see doc.fontStyle).
function M.html(s, font)
  local out = {}
  for _, w in ipairs(s.windows) do
    out[#out + 1] = doc.button(doc.escape(w.title), "open", w.name)
  end
  return '<div class="wbar"' .. doc.fontStyle(font) .. ">" .. table.concat(out) .. "</div>"
end

return M
