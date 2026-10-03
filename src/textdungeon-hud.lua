-- TextDungeon HUD: Status / Effects / Slots widgets, the Page and Quest
-- readers and the Windows bar for MudForge, fed only by TextDungeonC's GMCP
-- Feed. This is the source; the file MudForge imports is
-- the built textdungeon-hud.lua at the repo root (ADR 0001).
plugin = {
  id = "textdungeon-hud",
  name = "textdungeon-hud",
  version = "0.2.0",
  author = "wccrawford",
  description = "TextDungeon's Status, Effects, Slots, Page and Quest as MudForge widgets, fed by the GMCP Feed.",
  settings = { saveState = true },
}

local status = require("status")
local effects = require("effects")
local slots = require("slots")
local pages = require("pages")
local quests = require("quests")
local bar = require("bar")
local doc = require("doc")
local widgets = require("widgets")   -- { status = html, ..., reader = css, bar = css }, built from src/widgets/

-- Top-anchored columns from the right edge (wayfinder #14): the state column
-- (Status / Effects / Slots) against the edge, the reader column (the
-- Windows bar, Quest, Page) to its left, 12 px from the edge and between
-- widgets. Heights include MudForge's title bar.
local GAP = 12
local COLUMNS = {
  { width = 240, bound = true, widgets = {
    { name = "status", title = "Status", height = 176 },
    { name = "effects", title = "Effects", height = 164 },   -- five timer rows before scrolling
    { name = "slots", title = "Slots", height = 256 },       -- the villager's twelve rows before scrolling
  } },
  { width = 360, widgets = {
    { name = "bar", title = "Windows", height = 76 },
    { name = "quest", title = "Quest", height = 300 },
    { name = "page", title = "Page", height = 360 },
  } },
}
-- What the Windows bar opens, in bar order; never the bar itself.
local WINDOWS = {
  { name = "status", title = "Status" }, { name = "effects", title = "Effects" },
  { name = "slots", title = "Slots" }, { name = "quest", title = "Quest" },
  { name = "page", title = "Page" },
}

local TICK_MS = 100       -- the shared Countdown tick
local REPUSH_MS = 750     -- bound values pushed right after content is set are lost (#6)

local hud = {
  status = { id = nil, s = status.new() },
  effects = { id = nil, s = effects.new() },
  slots = { id = nil, s = slots.new() },
  page = { id = nil, s = pages.new() },
  quest = { id = nil, s = quests.new() },
  bar = { id = nil, s = bar.new(WINDOWS) },
}
local tick = nil
local repushDue = false   -- one re-push owed after init set the content

-- Create every widget down its column. MudForge's saved placement overrides
-- these positions on later loads, so this only decides first install. A
-- `bound` column's content is set once here; the reader column's widgets
-- are rendered whole, below.
local function createColumns()
  local win = getWindowSize() or {}
  local right = (win.width or 0) - GAP
  for _, col in ipairs(COLUMNS) do
    local x = right - col.width
    if x < 0 then x = 0 end
    local y = GAP
    for _, w in ipairs(col.widgets) do
      local id = createWidget({
        type = "html",
        name = w.name,
        title = w.title,
        position = { x = x, y = y },
        size = { width = col.width, height = w.height },
      })
      if col.bound then setWidgetProperty(id, "content", widgets[w.name]) end
      hud[w.name].id = id
      y = y + w.height + GAP
    end
    right = x - GAP
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

-- Each widget's own font, from its settings cog. The markup sizes in em
-- from it, so the HUD reads at the size the player set, like the stock
-- panels; MudForge does not carry it into an html widget by itself.
local function fontOf(name)
  return getWidgetFont(hud[name].id)
end

-- The bound widgets take theirs as bound style keys on the root.
local function pushFont(name)
  setBoundValues(hud[name].id, doc.fontKeys(fontOf(name)))
end

-- The readers and the bar are rewritten whole on every change (ADR 0002).
local function renderPage()
  setWidgetProperty(hud.page.id, "content", widgets.reader .. pages.html(hud.page.s, fontOf("page")))
end

local function renderQuest()
  setWidgetProperty(hud.quest.id, "content", widgets.reader .. quests.html(hud.quest.s, fontOf("quest")))
end

local function renderBar()
  setWidgetProperty(hud.bar.id, "content", widgets.bar .. bar.html(hud.bar.s, fontOf("bar")))
end

-- How each widget follows a new font. An html widget gets no event when the
-- player picks one (the resize event the docs promise is a canvas widget's),
-- so the tick asks every FONT_TICKS; only a font that differs from the one
-- applied re-applies, so a reader keeps its scroll otherwise.
local FONT_TICKS = 10      -- once a second
local REFONT = {
  status = function() pushFont("status") end,
  effects = function() pushFont("effects") end,
  slots = function() pushFont("slots") end,
  page = function() renderPage() end,
  quest = function() renderQuest() end,
  bar = function() renderBar() end,
}
local lastFont = {}         -- name -> the font css last applied
local fontTicks = 0

-- Note every widget's font as applied (the renders and pushes read it).
local function noteFonts()
  for name in pairs(REFONT) do lastFont[name] = fontOf(name).css end
end

local function checkFonts()
  for name, refont in pairs(REFONT) do
    local css = fontOf(name).css
    if css ~= lastFont[name] then
      lastFont[name] = css
      refont()
    end
  end
end

-- MudForge cannot yet bring back a closed custom window, so the bar is shown
-- on every start, even if the player closed it last time. force: overrides
-- a hide made in the Plugin Manager too.
local function showBar()
  showWidget(hud.bar.id, true)
end

local function pushAll()
  local now = getCurrentTime()
  pushStatus(now)
  pushEffects(now)
  pushSlots()
  pushFont("status")
  pushFont("effects")
  pushFont("slots")
end

-- The one re-push owed after init: bound values set with the content are
-- lost (#6), and a saved layout may hide the bar after init ran.
local function afterInit()
  pushAll()
  showBar()
end

-- Each widget is pushed on every tick while it has a Countdown running,
-- including the tick that reaches Clear.
local function onTick()
  fontTicks = fontTicks + 1
  if fontTicks >= FONT_TICKS then
    fontTicks = 0
    checkFonts()
  end
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
    addTimer(REPUSH_MS, afterInit, false)
  end
end

-- The attach routine (wayfinder #9), shared by init and onConnect: reset every
-- widget to Unfed; the tick follows with the first feed push.
local function attach()
  hud.status.s = status.new()
  hud.effects.s = effects.new()
  hud.slots.s = slots.new()
  hud.page.s = pages.new()
  hud.quest.s = quests.new()
  pushAll()
  renderPage()
  renderQuest()
  stopTick()
end

-- Clicks inside a reader (`data-mud-action`): navigate Recent, or send the
-- command the click asks for. Focus goes back to the command line either way.
local function onReaderAction(w, lib, render)
  registerWidgetEvent(hud[w].id, "action", function(d)
    local cmd = lib.act(hud[w].s, d.action, d.data)
    render()
    if cmd ~= nil then send(cmd) end
    focusPrompt()
  end)
end

local function onBarAction()
  registerWidgetEvent(hud.bar.id, "action", function(d)
    -- force: brings back a window closed from its own chrome, and one
    -- hidden in the Plugin Manager
    local name = bar.act(hud.bar.s, d.action, d.data)
    if name ~= nil then showWidget(hud[name].id, true) end
    focusPrompt()
  end)
end

function init()
  createColumns()
  renderBar()
  noteFonts()
  onReaderAction("page", pages, renderPage)
  onReaderAction("quest", quests, renderQuest)
  onBarAction()

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
  onGMCPUpdate("Writing.Read", function(pkg)
    ensureTick()
    pages.read(hud.page.s, pkg)
    renderPage()
  end)
  onGMCPUpdate("Quest.Show", function(pkg)
    ensureTick()
    quests.show(hud.quest.s, pkg)
    renderQuest()
  end)

  attach()
  showBar()
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
  pages.sever(hud.page.s)
  quests.sever(hud.quest.s)
  pushAll()
  renderPage()
  renderQuest()
  stopTick()
end
