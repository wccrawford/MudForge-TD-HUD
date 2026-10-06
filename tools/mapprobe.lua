-- PROTOTYPE, throwaway (wayfinder #21 "How the Map window redraws").
-- Desktop probes P1-P6 from docs/research/mudforge-widget-drawing.md, plus a
-- race between redraw methods on a worst-case 21 x 23 grid. Import it once in
-- the Plugin Manager while connected; nothing here ships.
--   probe p1        SVG renders and scales (P1, with P2's three dots unplaced)
--   probe p2        place P2's dots with setBoundValues
--   probe p3        script, canvas, inline handler (P3)
--   probe p4        tooltips (P4)
--   probe p6        resize signals (P6); also logs the close event
--   probe race <m>  20 marker steps by m = bind | msg | rewrite | plane
--   probe report    everything logged so far
--   probe clean     destroy every probe widget
plugin = {
  id = "mapprobe",
  name = "mapprobe",
  version = "0.0.1",
  author = "wccrawford",
  description = "PROTOTYPE: Map window redraw probes (wayfinder #21).",
}

local W = {}       -- probe name -> widget id
local logl = {}
local race = nil   -- the race in flight

local function say(s)
  logl[#logl + 1] = s
  print("probe: " .. s)
end

local function widget(name, w, h, x)
  if W[name] then destroyWidget(W[name]) end
  local id = createWidget({
    type = "html", name = "probe-" .. name, title = "probe " .. name,
    position = { x = x or 80, y = 80 }, size = { width = w, height = h },
  })
  W[name] = id
  registerWidgetEvent(id, "resize", function(e)
    say(name .. " LUA resize " .. tostring(e.width) .. "x" .. tostring(e.height))
  end)
  registerWidgetEvent(id, "close", function() say(name .. " close event") end)
  return id
end

local function msgs(name, id, fn)
  registerWidgetEvent(id, "luamsg", function(m)
    if fn and fn(m) then return end
    say(name .. " luamsg " .. tostring(m.event) .. " " .. json.encode(m.data or {}))
  end)
end

-- P1 + P2 ---------------------------------------------------------------

local function p1()
  local id = widget("p1", 300, 300, 80)
  setWidgetProperty(id, "content", [[
<style>html,body{margin:0;height:100%;background:#111}</style>
<svg viewBox="0 0 210 230" width="100%" height="100%" preserveAspectRatio="xMidYMid meet">
  <rect x="0" y="0" width="210" height="230" fill="none" stroke="#888"/>
  <line x1="5" y1="5" x2="205" y2="225" stroke="#c84"/>
  <circle cx="105" cy="115" r="6" fill="#4cf"/>
  <g data-mud-bind-attr="transform:gt"><circle r="4" fill="#f44"/></g>
  <circle r="4" fill="#4f4" data-mud-bind-attr="cx:cx; cy:cy"/>
  <circle r="4" fill="#ff4" data-mud-bind-style="transform:ct"/>
</svg>]])
  return "p1 up: box, corner-to-corner diagonal, blue dot; resize it by the corner\r\n"
end

local p2n = 0
local function p2()
  if not W.p1 then p1() end
  p2n = p2n + 1
  local d = (p2n % 2 == 0) and 0 or 60
  setBoundValues(W.p1, {
    gt = "translate(" .. (30 + d) .. "," .. 40 .. ")",
    cx = 60 + d, cy = 80,
    ct = "translate(" .. (90 + d) .. "px,120px)",
  })
  return "p2: red (30,40) green (60,80) yellow (90px,120px), +" .. d .. " in x\r\n"
end

-- P3 / P4 / P6 ------------------------------------------------------------

local function p3()
  local id = widget("p3", 260, 140, 400)
  msgs("p3", id)
  setWidgetProperty(id, "content",
    [[<style>html,body{margin:0;background:#222;color:#ddd}</style>]] ..
    [[<canvas id="c" width="100" height="50"></canvas>]] ..
    [[<button onclick="mudforge.send('inline',{})">x</button>]] ..
    [[<script>document.getElementById('c').getContext('2d').fillStyle='#4cf';]] ..
    [[document.getElementById('c').getContext('2d').fillRect(10,10,30,30);]] ..
    [[mudforge.send('ready',{ua:navigator.userAgent})</script>]])
  return "p3 up: expect a filled square, 'ready' now, 'inline' on clicking x\r\n"
end

local function p4()
  local id = widget("p4", 260, 160, 680)
  setWidgetProperty(id, "content",
    [[<style>html,body{margin:0;background:#222;color:#ddd}</style>]] ..
    [[<div title="html tip" style="padding:8px;border:1px solid #888">hover div</div>]] ..
    [[<svg width="200" height="80"><rect x="10" y="10" width="50" height="50" fill="#c84">]] ..
    [[<title>svg tip</title></rect><rect x="80" y="10" width="50" height="50" fill="#48c">]] ..
    [[<title data-mud-bind="tip"></title></rect></svg>]])
  setBoundValues(id, { tip = "bound svg tip" })
  return "p4 up: hover each box ~1 s; expect 'html tip', 'svg tip', 'bound svg tip'\r\n"
end

local function p6()
  local id = widget("p6", 260, 160, 960)
  msgs("p6", id)
  setWidgetProperty(id, "content",
    [[<style>html,body{margin:0;background:#222;color:#ddd}</style><div id="s"></div>]] ..
    [[<script>function r(){document.getElementById('s').textContent=innerWidth+'x'+innerHeight;]] ..
    [[mudforge.send('size',{w:innerWidth,h:innerHeight})}]] ..
    [[var t;addEventListener('resize',function(){clearTimeout(t);t=setTimeout(r,150)});r()</script>]])
  return "p6 up: drag-resize it, dock it, resize the tile, then close it with its x\r\n"
end

-- The race ---------------------------------------------------------------

local COLS, ROWS, CELL = 21, 23, 20
local STEPS, GAP = 20, 150

local function pos(k)
  local x = k % COLS
  local y = math.floor(k / COLS) % ROWS
  return x * CELL + CELL / 2, y * CELL + CELL / 2
end

local function tr(k)
  local x, y = pos(k)
  return "translate(" .. x .. "," .. y .. ")"
end

local TERR = { "#3a5", "#875", "#557", "#a94" }

-- The plane as markup: a rect per cell, a line to each east/south neighbour.
local function planeMarkup(shift)
  local t = {}
  for y = 0, ROWS - 1 do
    for x = 0, COLS - 1 do
      local cx, cy = x * CELL + CELL / 2, y * CELL + CELL / 2
      if x < COLS - 1 then
        t[#t + 1] = '<line x1="' .. cx .. '" y1="' .. cy .. '" x2="' .. (cx + CELL) ..
          '" y2="' .. cy .. '" stroke="#666"/>'
      end
      if y < ROWS - 1 then
        t[#t + 1] = '<line x1="' .. cx .. '" y1="' .. cy .. '" x2="' .. cx ..
          '" y2="' .. (cy + CELL) .. '" stroke="#666"/>'
      end
      t[#t + 1] = '<rect x="' .. (cx - 6) .. '" y="' .. (cy - 6) ..
        '" width="12" height="12" fill="' .. TERR[(x + y + shift) % 4 + 1] .. '"/>'
    end
  end
  return table.concat(t)
end

-- The same plane as data, for the plane method's script to build.
local function planeData(shift)
  local t = {}
  for y = 0, ROWS - 1 do
    for x = 0, COLS - 1 do
      t[#t + 1] = { x = x, y = y, c = TERR[(x + y + shift) % 4 + 1],
        e = x < COLS - 1, s = y < ROWS - 1 }
    end
  end
  return t
end

-- mode: which redraw method the script serves; k: the step baked in.
local function raceContent(mode, k)
  local me = '<g id="me" transform="' .. tr(k) .. '"' ..
    (mode == "bind" and ' data-mud-bind-attr="transform:me"' or '') ..
    '><circle r="7" fill="#4cf" stroke="#fff"/></g>'
  return '<style>html,body{margin:0;height:100%;background:#111}svg{display:block}</style>' ..
    '<svg viewBox="0 0 ' .. (COLS * CELL) .. ' ' .. (ROWS * CELL) ..
    '" width="100%" height="100%" preserveAspectRatio="xMidYMid meet"><g id="plane">' ..
    planeMarkup(0) .. '</g>' .. me .. '</svg>' ..
    '<script>var MODE=' .. json.encodeForScript(mode) .. ',K=' .. k .. ',C=' .. CELL .. ';' ..
    [[var me=document.getElementById('me'),pl=document.getElementById('plane');
function done(k,t0){requestAnimationFrame(function(){mudforge.send('done',{k:k,js:performance.now()-t0})})}
if(MODE==='bind'){new MutationObserver(function(){var t0=performance.now();done(me.getAttribute('transform'),t0)})
 .observe(me,{attributes:true,attributeFilter:['transform']})}
mudforge.onMessage(function(d){var t0=performance.now();
 if(d.cells){var h='';for(var i=0;i<d.cells.length;i++){var c=d.cells[i],x=c.x*C+C/2,y=c.y*C+C/2;
  if(c.e)h+='<line x1="'+x+'" y1="'+y+'" x2="'+(x+C)+'" y2="'+y+'" stroke="#666"/>';
  if(c.s)h+='<line x1="'+x+'" y1="'+y+'" x2="'+x+'" y2="'+(y+C)+'" stroke="#666"/>';
  h+='<rect x="'+(x-6)+'" y="'+(y-6)+'" width="12" height="12" fill="'+c.c+'"/>'}pl.innerHTML=h}
 me.setAttribute('transform',d.t);done(d.k,t0)});
if(MODE==='rewrite')done(K,0);else mudforge.send('ready',{})</script>]]
end

local function median(t)
  local s = {}
  for i = 1, #t do s[i] = t[i] end
  table.sort(s)
  if #s == 0 then return 0 end
  return s[math.floor((#s + 1) / 2)]
end

local function summary()
  local r = race
  local lat, js = {}, {}
  for _, v in pairs(r.got) do lat[#lat + 1] = v.lat; js[#js + 1] = v.js end
  table.sort(lat)
  say(string.format("race %s: %d/%d acked; end-to-end ms min %d med %d max %d; " ..
    "widget-side js ms med %.1f; lua build+send ms med %.2f max %.2f; bytes/step %d",
    r.mode, #lat, STEPS, lat[1] or -1, median(lat), lat[#lat] or -1, median(js),
    median(r.lua), (function() local m = 0 for _, v in ipairs(r.lua) do if v > m then m = v end end return m end)(),
    r.bytes))
  race = nil
end

local function step()
  local r = race
  if not r then return end
  r.k = r.k + 1
  if r.k > STEPS then
    if r.timer and r.timer ~= "" then removeTimer(r.timer) end
    addTimer(1000, summary, false)
    return
  end
  local k = r.k
  local c0 = os.clock()
  if r.mode == "bind" then
    local t = tr(k)
    r.sent[t] = getCurrentTime()
    setBoundValues(r.id, { me = t })
    r.bytes = #t
  elseif r.mode == "msg" then
    r.sent[tostring(k)] = getCurrentTime()
    sendWidgetMessage(r.id, { k = tostring(k), t = tr(k) })
    r.bytes = #json.encode({ k = tostring(k), t = tr(k) })
  elseif r.mode == "plane" then
    local d = { k = tostring(k), t = tr(k), cells = planeData(k) }
    r.sent[tostring(k)] = getCurrentTime()
    sendWidgetMessage(r.id, d)
    r.bytes = #json.encode(d)
  else
    local s = raceContent("rewrite", k)
    r.sent[tostring(k)] = getCurrentTime()
    setWidgetProperty(r.id, "content", s)
    r.bytes = #s
  end
  r.lua[#r.lua + 1] = (os.clock() - c0) * 1000
end

local function startRace(mode)
  if race then return "a race is still running\r\n" end
  if mode ~= "bind" and mode ~= "msg" and mode ~= "rewrite" and mode ~= "plane" then
    return "probe race bind | msg | rewrite | plane\r\n"
  end
  local id = widget("race", 440, 480, 80)
  race = { mode = mode, id = id, k = 0, sent = {}, got = {}, lua = {}, bytes = 0 }
  local go = function()
    race.timer = addTimer(GAP, step, true)
    if race.timer == "" then say("addTimer refused (disconnected?)") race = nil end
  end
  msgs("race", id, function(m)
    local r = race
    if not r then return true end
    if m.event == "ready" then go() return true end
    if m.event == "done" then
      local key = tostring(m.data.k)
      if r.mode == "rewrite" and key == "0" then go() return true end
      local t0 = r.sent[key]
      if t0 then
        r.got[key] = { lat = getCurrentTime() - t0, js = tonumber(m.data.js) or 0 }
        r.sent[key] = nil
      end
      return true
    end
  end)
  local c0 = os.clock()
  setWidgetProperty(id, "content", raceContent(mode, 0))
  say(string.format("race %s: first content %.2f ms lua, %d bytes", mode,
    (os.clock() - c0) * 1000, #raceContent(mode, 0)))
  return "race " .. mode .. ": " .. STEPS .. " steps every " .. GAP .. " ms; watch for flicker\r\n"
end

function init()
  registerCommand("probe", function(args)
    args = args or ""
    local a, b = string.match(args, "^%s*(%S*)%s*(%S*)")
    if a == "p1" then return p1()
    elseif a == "p2" then return p2()
    elseif a == "p3" then return p3()
    elseif a == "p4" then return p4()
    elseif a == "p6" then return p6()
    elseif a == "race" then return startRace(b)
    elseif a == "clean" then
      for k, id in pairs(W) do destroyWidget(id) W[k] = nil end
      return "probe: cleaned\r\n"
    end
    return table.concat(logl, "\r\n") .. "\r\n"
  end, "PROTOTYPE map redraw probes: p1 p2 p3 p4 p6 | race bind|msg|rewrite|plane | report | clean")
end
