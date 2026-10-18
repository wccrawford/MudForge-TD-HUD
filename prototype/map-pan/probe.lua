-- PROTOTYPE, throwaway (wayfinder #35 "How Following, zoom and panning redraw").
-- Real planes drawn by lib/map.lua (planes.lua, from gen.lua) at a fixed zoom in a
-- window that follows the player, under two mechanisms:
--   A  rewrite: Lua rewrites content on every change; the page reports its pan and
--      zoom to Lua on release, and every rewrite is laid out from them
--   C  message: content is written once per plane; steps and member moves reach the
--      page script by sendWidgetMessage, and the page keeps its own pan and zoom
-- Import panprobe.lua once in the Plugin Manager while connected; nothing ships.
--   pan a <plane> | pan c <plane>   open the window (plane = mere | ochre | town)
--   pan walk                        toggle the player walking (a step every 1.5 s)
--   pan member                      toggle a member walking (a move every 0.7 s)
--   pan report                      timings so far
--   pan clean                       close the probe window
plugin = {
  id = "panprobe",
  name = "panprobe",
  version = "0.0.1",
  author = "wccrawford",
  description = "PROTOTYPE: Map follow/zoom/pan probes (wayfinder #35).",
}

local P = nil       -- the probe in flight: mode, plane, widget, positions, timers
local logl = {}
local ZOOMS = { 20, 24, 28, 34, 40, 48, 56 }
local zoomAt = 4    -- 34 px per cell; kept across probes as a real window would

local function say(s)
  logl[#logl + 1] = s
  print("panprobe: " .. s)
end

local function at(i)
  local path = P.plane.path
  return path[((i - 1) % #path) + 1]
end

local function marker(id, c, title, body)
  return '<g id="' .. id .. '" transform="translate(' .. c[2] .. ' ' .. c[3] .. ')"><title>' .. title .. '</title>' .. body .. '</g>'
end

local YOU = '<rect x="-8.6" y="-8.6" width="17.2" height="17.2" rx="3.5" fill="none" stroke="#ffd33d" stroke-width="2.4"/>'
  .. '<circle r="2.8" fill="#ffd33d" stroke="#0d1117" stroke-width="1.2"/>'
local MEM = '<circle cx="-6" cy="6" r="4" fill="#ff7b72" stroke="#0d1117" stroke-width="1.2"/>'
  .. '<text x="-6" y="7.9" font-size="5.4" text-anchor="middle" fill="#0d1117" font-weight="700">R</text>'

-- The page: a header, the plane in a clipped viewport, and the script that lays it out.
local function content(k)
  local you, mem = at(P.step), at(P.mstep)
  local state = json.encodeForScript({
    mode = P.mode, k = k, zoom = ZOOMS[zoomAt], zooms = ZOOMS, here = { you[2], you[3] },
    pan = P.pan, vb = P.vb, name = you[4], dragging = P.dragging, enc = "caf\195\169",
  })
  return [==[<style>html,body{margin:0;height:100%;background:#0d1117;overflow:hidden;color:#c9d1d9;font:12px system-ui,sans-serif}
#hd{position:absolute;top:0;left:0;right:0;height:22px;display:flex;gap:6px;align-items:center;padding:0 4px;border-bottom:1px solid #30363d;white-space:nowrap;overflow:hidden}
#hd b{color:#e6edf3}#hd button{background:#161b22;color:#c9d1d9;border:1px solid #30363d;border-radius:3px;padding:0 6px;cursor:pointer}
#vp{position:absolute;top:23px;left:0;right:0;bottom:18px;overflow:hidden;cursor:grab;touch-action:none}
#vp.drag{cursor:grabbing}#pl{position:absolute;left:0;top:0;display:block;user-select:none;-webkit-user-drag:none}
#enc{position:absolute;left:0;right:0;bottom:0;background:#161b22;padding:1px 4px;font-size:11px;white-space:nowrap;overflow:hidden;border-top:1px solid #30363d}</style>
<div id="hd"><b>]==] .. P.plane.area .. [==[</b><span id="nm"></span>
<button id="zm">-</button><span id="zv"></span><button id="zp">+</button><button id="me">me</button><span id="st"></span></div>
<div id="vp"><svg id="pl" viewBox="]==] .. P.plane.vb .. [==[">]==] .. P.plane.svg
    .. marker("mem", mem, "Rei", MEM) .. marker("you", you, "You", YOU) .. [==[</svg></div>
<div id="enc">raw:caf]==] .. "\195\169" .. [==[ | ent:caf&#233; | json:<span id="ej"></span> | jsu:<span id="eu"></span> | bound:<span data-mud-bind="bnm"></span> | msg:<span id="em"></span></div>
<script>var S=]==] .. state .. [==[;
document.getElementById('ej').textContent=S.enc;document.getElementById('eu').textContent='café';
var vp=document.getElementById('vp'),pl=document.getElementById('pl'),st=document.getElementById('st');
var t0=performance.now();
function k(){return S.zoom/20}
// one axis: centred when the plane fits, else the point `at` centred and clamped to the edges
function axis(view,size,origin,a){if(size<=view)return (view-size)/2;var t=view/2-(a-origin)*k();return Math.min(0,Math.max(view-size,t))}
// keep the pan inside what the clamp allows, so a release has no dead zone
function clampPan(){var W=vp.clientWidth,H=vp.clientHeight,pw=S.vb[2]*k(),ph=S.vb[3]*k();
 [[0,W,pw],[1,H,ph]].forEach(function(a){var i=a[0],view=a[1],size=a[2];
  if(size<=view){S.pan[i]=0;return}
  var lo=S.vb[i]+view/2/k(),hi=S.vb[i]+S.vb[i+2]-view/2/k(),p=S.here[i]+S.pan[i];
  S.pan[i]=Math.min(hi,Math.max(lo,p))-S.here[i]})}
function layout(){var W=vp.clientWidth,H=vp.clientHeight,pw=S.vb[2]*k(),ph=S.vb[3]*k();
 pl.setAttribute('width',pw);pl.setAttribute('height',ph);
 pl.style.transform='translate('+axis(W,pw,S.vb[0],S.here[0]+S.pan[0])+'px,'+axis(H,ph,S.vb[1],S.here[1]+S.pan[1])+'px)';
 document.getElementById('zv').textContent=S.zoom+'px';
 document.getElementById('nm').textContent=S.name}
// to Lua as an object: a JSON array reaches Lua 0-based
function report(){mudforge.send('view',{px:S.pan[0],py:S.pan[1],zoom:S.zoom,dragging:!!drag})}
var lastRep=0;function reportSoon(){var t=performance.now();if(t-lastRep>60){lastRep=t;report()}}
function zoomBy(d){var i=S.zooms.indexOf(S.zoom)+d;if(i<0||i>=S.zooms.length)return;S.zoom=S.zooms[i];clampPan();layout();report()}
var drag=null,drags=0,moves=0,resumed=0;
function begin(e){drag={x:e.clientX,y:e.clientY,p:S.pan.slice()};try{vp.setPointerCapture(e.pointerId)}catch(_){}vp.classList.add('drag')}
vp.addEventListener('dragstart',function(e){e.preventDefault()});
vp.addEventListener('pointerdown',function(e){if(e.button!==0)return;e.preventDefault();begin(e);drags++});
// a rewrite mid-drag: the new page picks the drag up while the button is still held
vp.addEventListener('pointermove',function(e){
 if(!drag){if(S.dragging&&(e.buttons&1)){begin(e);resumed++;st.textContent='resumed '+resumed}return}
 moves++;S.pan=[drag.p[0]-(e.clientX-drag.x)/k(),drag.p[1]-(e.clientY-drag.y)/k()];clampPan();layout();reportSoon()});
function end(){if(!drag)return;drag=null;S.dragging=false;vp.classList.remove('drag');report();st.textContent='drags '+drags+' moves '+moves}
vp.addEventListener('pointerup',end);vp.addEventListener('pointercancel',end);vp.addEventListener('lostpointercapture',end);
addEventListener('pointerup',function(){if(S.dragging){S.dragging=false;report()}});
var wheels=0;vp.addEventListener('wheel',function(e){e.preventDefault();wheels++;zoomBy(e.deltaY<0?1:-1);st.textContent='wheels '+wheels},{passive:false});
document.getElementById('zm').onclick=function(){zoomBy(-1)};document.getElementById('zp').onclick=function(){zoomBy(1)};
document.getElementById('me').onclick=function(){S.pan=[0,0];layout();report()};
addEventListener('resize',function(){clampPan();layout()});
function done(key,t){requestAnimationFrame(function(){mudforge.send('done',{k:key,js:performance.now()-t})})}
mudforge.onMessage(function(d){var t=performance.now();
 if(d.you){S.here=[d.you[0],d.you[1]];S.pan=[0,0];S.name=d.name;
  document.getElementById('you').setAttribute('transform','translate('+d.you[0]+' '+d.you[1]+')')}
 if(d.enc)document.getElementById('em').textContent=d.enc;
 if(d.mem)document.getElementById('mem').setAttribute('transform','translate('+d.mem[0]+' '+d.mem[1]+')');
 layout();done(d.k,t)});
layout();done(S.k,t0);</script>]==]
end

local function send(k, you, mem, first)
  P.sent[tostring(k)] = getCurrentTime()
  local c0 = os.clock()
  if P.mode == "a" or first then
    local s = content(k)
    setWidgetProperty(P.id, "content", s)
    P.bytes = #s
  else
    local d = { k = k }
    if you then d.you = { you[2], you[3] }; d.name = you[4]; d.enc = "caf\195\169" end
    if mem then d.mem = { mem[2], mem[3] } end
    sendWidgetMessage(P.id, d)
    P.bytes = #json.encode(d)
  end
  P.lua[#P.lua + 1] = (os.clock() - c0) * 1000
  if you then setBoundValues(P.id, { bnm = "caf\195\169" }) end
end

local function nextKey()
  P.k = P.k + 1
  return P.k
end

local function walkStep()
  if not P then return end
  P.step = P.step + 1
  P.pan = { 0, 0 }   -- a step re-centres
  send(nextKey(), at(P.step), nil)
end

local function memberStep()
  if not P then return end
  P.mstep = P.mstep - 1
  send(nextKey(), nil, at(P.mstep))
end

local function stopTimers()
  if P and P.walk then removeTimer(P.walk); P.walk = nil end
  if P and P.mem then removeTimer(P.mem); P.mem = nil end
end

local function median(t)
  local s = {}
  for i = 1, #t do s[i] = t[i] end
  table.sort(s)
  if #s == 0 then return 0 end
  return s[math.floor((#s + 1) / 2)]
end

local function report()
  if not P then return "no probe open\r\n" end
  local lat, js = {}, {}
  for _, v in ipairs(P.got) do lat[#lat + 1] = v.lat; js[#js + 1] = v.js end
  local s = string.format("mode %s plane %s: %d acked; end-to-end ms med %d max %d; page js ms med %.1f; lua ms med %.2f; bytes/update %d; zoom %d; pan %.0f,%.0f",
    P.mode, P.name, #lat, median(lat), (function() local m = 0 for _, v in ipairs(lat) do if v > m then m = v end end return m end)(),
    median(js), median(P.lua), P.bytes or 0, ZOOMS[zoomAt], P.pan[1], P.pan[2])
    .. string.format("; sent %d; got done %d, view %d", P.k, P.msgs.done or 0, P.msgs.view or 0)
  say(s)
  return table.concat(logl, "\r\n") .. "\r\n"
end

local function open(mode, name)
  if mode ~= "a" and mode ~= "c" then return "pan a <plane> | pan c <plane>\r\n" end
  local plane = PLANES[name or ""]
  if not plane then return "planes: mere | ochre | town\r\n" end
  stopTimers()
  if P and P.id then destroyWidget(P.id) end
  local vb = {}
  for v in string.gmatch(plane.vb, "%S+") do vb[#vb + 1] = tonumber(v) end
  local id = createWidget({
    type = "html", name = "panprobe", title = "panprobe " .. mode .. " " .. name,
    position = { x = 120, y = 100 }, size = { width = 420, height = 320 },
  })
  P = { mode = mode, name = name, plane = plane, id = id, vb = vb, step = 1, mstep = 1, pan = { 0, 0 },
    k = 0, sent = {}, got = {}, lua = {}, msgs = {}, dragging = false }
  registerWidgetEvent(id, "luamsg", function(m)
    if not P or P.id ~= id then return end
    P.msgs[m.event] = (P.msgs[m.event] or 0) + 1
    if m.event == "done" then
      local key = tostring(m.data.k)
      local t0 = P.sent[key]
      if t0 then
        P.got[#P.got + 1] = { lat = getCurrentTime() - t0, js = tonumber(m.data.js) or 0 }
        P.sent[key] = nil
      end
    elseif m.event == "view" then
      -- only rewrite mode needs these, but both keep them as the lib would
      local z = tonumber(m.data.zoom)
      P.pan = { tonumber(m.data.px) or 0, tonumber(m.data.py) or 0 }
      P.dragging = m.data.dragging == true
      for i, v in ipairs(ZOOMS) do if v == z then zoomAt = i end end
    end
  end)
  registerWidgetEvent(id, "close", function() stopTimers(); P = nil end)
  send(nextKey(), at(P.step), nil, true)
  return "panprobe " .. mode .. " " .. name .. ": drag to pan, wheel to zoom, hover a tile; then pan walk / pan member\r\n"
end

function init()
  registerCommand("pan", function(args)
    args = args or ""
    local a, b = string.match(args, "^%s*(%S*)%s*(%S*)")
    if a == "a" or a == "c" then return open(a, b) end
    if a == "walk" then
      if not P then return "open one first\r\n" end
      if P.walk then removeTimer(P.walk); P.walk = nil; return "walk off\r\n" end
      P.walk = addTimer(1500, walkStep, true)
      return "walk on\r\n"
    end
    if a == "member" then
      if not P then return "open one first\r\n" end
      if P.mem then removeTimer(P.mem); P.mem = nil; return "member off\r\n" end
      P.mem = addTimer(700, memberStep, true)
      return "member on\r\n"
    end
    if a == "report" then return report() end
    if a == "clean" then
      stopTimers()
      if P and P.id then destroyWidget(P.id) end
      P = nil
      return "closed\r\n"
    end
    return "pan a|c <mere|ochre|town> | walk | member | report | clean\r\n"
  end, "PROTOTYPE map pan probes: a|c <plane> | walk | member | report | clean")
end
