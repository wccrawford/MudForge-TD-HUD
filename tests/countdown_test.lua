local countdown = require("countdown")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

eq(countdown.mmss(0), "00:00", "mmss zero")
eq(countdown.mmss(65), "01:05", "mmss 65")
eq(countdown.mmss(600), "10:00", "mmss 600")
eq(countdown.mmss(-3), "00:00", "mmss negative")
eq(countdown.mmss(59.9), "00:59", "mmss floors")

print("countdown_test: OK")
