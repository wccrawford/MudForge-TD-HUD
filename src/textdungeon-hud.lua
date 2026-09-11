-- TextDungeon HUD: Status / Effects / Slots widgets for MudForge, fed only by
-- TextDungeonC's GMCP Feed. This is the source; the file MudForge imports is
-- the built textdungeon-hud.lua at the repo root (ADR 0001).
plugin = {
  id = "textdungeon-hud",
  name = "textdungeon-hud",
  version = "0.1.0",
  author = "wccrawford",
  description = "TextDungeon's Status, Effects and Slots as MudForge widgets, fed by the GMCP Feed.",
  settings = { saveState = true },
}

local status = require("status")
local effects = require("effects")
local slots = require("slots")
local widgets = require("widgets")   -- { status = html, effects = html, slots = html }, built from src/widgets/

-- One top-anchored column on the right edge (wayfinder #14): Status / Effects /
-- Slots top-down, 12 px from the edge and between widgets. Heights include
-- MudForge's ~30 px title bar. Each widget ticket appends its entry here.
local COLUMN = { width = 240, edge = 12, gap = 12 }
local ORDER = {
  { name = "status", title = "Status", height = 176 },
  { name = "effects", title = "Effects", height = 164 },   -- five timer rows before scrolling
  { name = "slots", title = "Slots", height = 256 },       -- the villager's twelve rows before scrolling
}

local TICK_MS = 100       -- the shared Countdown tick
local REPUSH_MS = 750     -- bound values pushed right after content is set are lost (#6)

local hud = {
  status = { id = nil, s = status.new() },
  effects = { id = nil, s = effects.new() },
  slots = { id = nil, s = slots.new() },
}
local tick = nil
local repushDue = false   -- one re-push owed after init set the content

-- Create every widget in ORDER down the column. MudForge's saved placement
-- overrides these positions on later loads, so this only decides first install.
local function createColumn()
  local win = getWindowSize() or {}
  local x = (win.width or 0) - COLUMN.width - COLUMN.edge
  if x < 0 then x = 0 end
  local y = COLUMN.edge
  for _, w in ipairs(ORDER) do
    local id = createWidget({
      type = "html",
      name = w.name,
      title = w.title,
      position = { x = x, y = y },
      size = { width = COLUMN.width, height = w.height },
    })
    setWidgetProperty(id, "content", widgets[w.name])
    hud[w.name].id = id
    y = y + w.height + COLUMN.gap
  end
end

local function pushStatus(now)
  setBoundValues(hud.status.id, status.keys(hud.status.s, now))
end

local function pushEffects(now)
  setBoundValues(hud.effects.id, effects.keys(hud.effects.s, now))
end

-- Slots has no Countdown, so it takes no clock and never rides the tick.
local function pushSlots()
  setBoundValues(hud.slots.id, slots.keys(hud.slots.s))
end

local function pushAll()
  local now = getCurrentTime()
  pushStatus(now)
  pushEffects(now)
  pushSlots()
end

-- Each widget is pushed on every tick while it has a Countdown running,
-- including the tick that reaches Clear.
local function onTick()
  local now = getCurrentTime()
  local s = hud.status.s
  local counting = s.rt ~= nil
  status.tick(s, now)
  if counting then pushStatus(now) end
  local e = hud.effects.s
  counting = effects.counting(e)
  effects.tick(e, now)
  if counting then pushEffects(now) end
end

local function stopTick()
  if tick ~= nil and tick ~= "" then removeTimer(tick) end
  tick = nil
end

-- addTimer answers "" (and warns in the terminal) while MudForge considers
-- the session disconnected, and onConnect fires before it stops doing so.
-- Every feed push proves the session is up, so all timers start from the
-- feed handlers: the tick until it takes, and the one re-push owed after init.
local function ensureTick()
  if tick ~= nil and tick ~= "" then return end
  tick = addTimer(TICK_MS, onTick, true)
  if tick ~= "" and repushDue then
    repushDue = false
    addTimer(REPUSH_MS, pushAll, false)
  end
end

-- The attach routine (wayfinder #9), shared by init and onConnect: reset every
-- widget to Unfed; the tick follows with the first feed push.
local function attach()
  hud.status.s = status.new()
  hud.effects.s = effects.new()
  hud.slots.s = slots.new()
  pushAll()
  stopTick()
end

function init()
  createColumn()

  onGMCPUpdate("Char.Vitals", function(pkg)
    ensureTick()
    status.vitals(hud.status.s, pkg)
    pushStatus(getCurrentTime())
  end)
  onGMCPUpdate("Char.RoundTime", function(pkg)
    ensureTick()
    local now = getCurrentTime()
    status.roundtime(hud.status.s, pkg, now)
    pushStatus(now)
  end)
  onGMCPUpdate("Char.Effects", function(pkg)
    ensureTick()
    local now = getCurrentTime()
    effects.effects(hud.effects.s, pkg, now)
    pushEffects(now)
  end)
  onGMCPUpdate("Char.Items", function(pkg)
    ensureTick()
    slots.items(hud.slots.s, pkg)
    pushSlots()
  end)

  attach()
  repushDue = true
  -- A hot-reload mid-session gets no feed until the server is asked; any
  -- Core.Hello makes TextDungeonC re-send every package with a fresh now_ms.
  -- A real connect already gets that from the server's own DO GMCP re-push,
  -- so this is sent here only, not from onConnect (MudForge echoes every
  -- sendGMCP into the terminal).
  sendGMCP("Core.Hello", { client = plugin.id, version = plugin.version })
end

function onConnect()
  attach()
end

function onDisconnect()
  local now = getCurrentTime()
  status.sever(hud.status.s, now)
  effects.sever(hud.effects.s, now)
  slots.sever(hud.slots.s)
  pushAll()
  stopTick()
end
