local bar = require("bar")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

local function has(s, part, label)
  assert(s:find(part, 1, true), label .. ": " .. part .. " not in " .. s)
end

local s = bar.new({ { name = "status", title = "Status" }, { name = "page", title = "Page" } })

-- One open button per window, in bar order
local h = bar.html(s)
has(h, '<span class="btn" data-mud-action="open" data-mud-data="status">Status</span>', "status button")
has(h, 'data-mud-data="page">Page</span>', "page button")
assert(h:find("status", 1, true) < h:find("page", 1, true), "bar order")

-- A click answers the window to open, every time
eq(bar.act(s, "open", "page"), "page", "open page")
eq(bar.act(s, "open", "page"), "page", "open is not a toggle")

-- Unknown clicks answer nothing
eq(bar.act(s, "open", "bogus"), nil, "unknown window")
eq(bar.act(s, "toggle", "page"), nil, "unknown action")

print("bar_test: OK")
