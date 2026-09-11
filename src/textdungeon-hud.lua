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

local countdown = require("countdown")
local widgets = require("widgets")   -- { status = html, effects = html, slots = html }, built from src/widgets/

function init()
end
