local countdown = require("countdown")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

-- mm:ss
eq(countdown.mmss(0), "00:00", "mmss zero")
eq(countdown.mmss(65), "01:05", "mmss 65")
eq(countdown.mmss(600), "10:00", "mmss 600")
eq(countdown.mmss(-3), "00:00", "mmss negative")
eq(countdown.mmss(59.9), "00:59", "mmss floors")

-- Anchor at arrival
local cd = countdown.push(nil, 3000, 1000)
eq(cd.ends_at, 4000, "anchor ends_at")
eq(cd.span, 3000, "anchor span")
eq(countdown.remaining(cd, 1800), 2200, "remaining drains on the local clock")
eq(countdown.remaining(cd, 9000), 0, "remaining never negative")
eq(countdown.remaining(nil, 0), 0, "remaining of nil")

-- Nothing left clears; a push while Clear starts fresh
eq(countdown.push(nil, 0, 1000), nil, "push 0 stays clear")
eq(countdown.push(cd, -50, 2000), nil, "push negative clears")
eq(countdown.push(nil, nil, 1000), nil, "push nil stays clear")

-- Dead-band: within 100 ms the running Countdown is kept as-is
cd = countdown.push(nil, 3000, 1000)
local same = countdown.push(cd, 2100, 2000)        -- ends 4100: +100, inside
assert(same == cd, "dead-band keeps the same table (+100)")
same = countdown.push(cd, 1900, 2000)              -- ends 3900: -100, inside
assert(same == cd, "dead-band keeps the same table (-100)")

-- Stack: lengthened beyond the dead-band refills the Span
local stacked = countdown.push(cd, 2500, 2000)     -- ends 4500: +500
eq(stacked.ends_at, 4500, "stack re-anchors")
eq(stacked.span, 2500, "stack span = the new remaining")
eq(countdown.pct(stacked, 2000), 100, "bar refills to full on a Stack")

-- A Brisk 200 ms charge on top of a running RT still lands
local brisk = countdown.push(cd, 2200, 2000)       -- ends 4200: +200
eq(brisk.ends_at, 4200, "200 ms stack is outside the dead-band")

-- Shortened beyond the dead-band: adopted wholesale, Span kept
local shorter = countdown.push(cd, 1000, 2000)     -- ends 3000: -1000
eq(shorter.ends_at, 3000, "shortening re-anchors")
eq(shorter.span, 3000, "shortening keeps the span")
eq(countdown.pct(shorter, 2000), 33.3, "bar drops on a shortening")

-- A push after local Clear is a fresh anchor, not a dead-band comparison
cd = countdown.push(nil, 1000, 1000)
local fresh = countdown.push(cd, 1050, 5000)       -- old one ended at 2000
eq(fresh.ends_at, 6050, "expired countdown does not gate a new push")
eq(fresh.span, 1050, "fresh span")

-- Tick and Clear
cd = countdown.push(nil, 1000, 1000)
assert(countdown.tick(cd, 1999) == cd, "still running at 1999")
eq(countdown.tick(cd, 2000), nil, "clear on the tick that reaches zero")
eq(countdown.tick(nil, 0), nil, "tick nil")

-- Seconds round up; never 0 while running
cd = countdown.push(nil, 3200, 0)
eq(countdown.seconds(cd, 0), 4, "3.2 s reads 4")
eq(countdown.seconds(cd, 200), 3, "3.0 s reads 3")
eq(countdown.seconds(cd, 3150), 1, "50 ms reads 1")
eq(countdown.seconds(cd, 3200), 0, "0 at clear (bar already gone)")
eq(countdown.seconds(nil, 0), 0, "seconds of nil")

-- Pct
eq(countdown.pct(cd, 1600), 50, "half drained")
eq(countdown.pct(cd, 3200), 0, "empty at clear")
eq(countdown.pct(nil, 0), 0, "pct of nil")
eq(countdown.pct(countdown.push(nil, 3000, 0), 1000), 66.7, "one decimal")

print("countdown_test: OK")
