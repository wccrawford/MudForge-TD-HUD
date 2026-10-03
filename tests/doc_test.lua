local doc = require("doc")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": " .. part .. " not in " .. s)
end

local function lacks(s, part, label)
  assert(not s:find(part, 1, true), label .. ": " .. part .. " in " .. s)
end

-- Escaping: fed text never reaches markup raw
eq(doc.escape([[<b>"Tom & Jerry"</b>]]), "&lt;b&gt;&quot;Tom &amp; Jerry&quot;&lt;/b&gt;", "escape")
eq(doc.escape(nil), "", "escape nil")
eq(doc.escape(3), "3", "escape number")

-- A plain line
eq(doc.line({ { text = "Rat Problem [in progress]" } }), '<div class="ln">Rat Problem [in progress]</div>', "plain line")

-- Roled spans get a class; an unknown role is drawn plain
local l = doc.line({ { text = "Type \"" }, { text = "quests show", role = "Command" }, { text = "x", role = "bogus\" onclick=\"" } })
has(l, '<span class="r-Command">quests show</span>', "role class")
lacks(l, "onclick=\"", "unknown role not trusted into markup")
has(l, "Type &quot;", "plain span escaped")

-- A hang sets the continuation column; the last one wins
l = doc.line({ { hang = 2 }, { text = "- Kill two rats. (0/2)" } })
has(l, "padding-left:2ch;text-indent:-2ch", "hang")
l = doc.line({ { hang = 2 }, { text = "Way: " }, { hang = 7 }, { text = "north" } })
has(l, "padding-left:7ch", "last hang wins")
lacks(doc.line({ { text = "x" } }), "padding", "no hang, no indent")

-- An empty line is still a line
eq(doc.line({}), '<div class="ln"></div>', "empty line")

-- lines walks every line in order
eq(doc.lines({ { { text = "a" } }, { { text = "b" } } }), '<div class="ln">a</div><div class="ln">b</div>', "lines")

-- copy walks with ipairs: index 0 is MudForge's to fix, not ours
local fed = { [0] = { { text = "zero" } }, [1] = { { text = "one", role = "Item" }, { hang = 4 } } }
local c = doc.copy(fed)
eq(#c, 1, "copy skips index 0")
eq(c[1][1].text, "one", "copy text")
eq(c[1][1].role, "Item", "copy role")
eq(c[1][2].hang, 4, "copy hang")

-- Buttons: an enabled one carries its action, a disabled one none
has(doc.button("Recent", "recent", nil, true), 'data-mud-action="recent"', "button action")
has(doc.button("Recent", "recent", nil, true), 'class="btn on"', "button lit")
has(doc.button("x", "open", 3), 'data-mud-data="3"', "button data")
lacks(doc.button("x", "older", nil, false, false), "data-mud-action", "disabled button has no action")

-- The frame: prev/next only where there is somewhere to go
local f = doc.frame({ state = "live", at = 1, count = 3, listing = false, label = "L", body = "B" })
has(f, 'data-state="live"', "frame state")
has(f, 'data-mud-action="older"', "older enabled")
lacks(f, 'data-mud-action="newer"', "newer disabled at the newest")
has(f, "1/3", "position")
f = doc.frame({ state = "unfed", at = 0, count = 0, listing = false, body = "B" })
lacks(f, "data-mud-action", "nothing to click while empty")

-- The Recent list marks the shown entry
local list = doc.recent({ { label = "a" }, { label = "b", sub = "s" } }, 2)
has(list, 'class="row cur" data-mud-action="open" data-mud-data="2"', "current row")
has(list, '<span class="sub">s</span>', "sub")

-- The widget's own font: bound keys for a bound root, a style for markup
local font = { family = '"Fira Code", monospace', size = 16, weight = "bold", css = "bold 16px x" }
local k = doc.fontKeys(font)
eq(k.fontSize, "16px", "font size in px")
eq(k.fontFamily, '"Fira Code", monospace', "font family verbatim")
eq(k.fontWeight, "bold", "font weight")
k = doc.fontKeys(nil)
eq(k.fontSize, "", "no font clears the size")
eq(k.fontFamily, "", "no font clears the family")
eq(doc.fontStyle(font), ' style="font-size:16px;font-family:&quot;Fira Code&quot;, monospace;font-weight:bold"', "font style escaped")
eq(doc.fontStyle({}), "", "no font, no style")
has(doc.frame({ state = "live", at = 0, count = 0, body = "", font = font }), 'class="hud rd" data-state="live" style="font-size:16px', "frame carries the font")

print("doc_test: OK")
