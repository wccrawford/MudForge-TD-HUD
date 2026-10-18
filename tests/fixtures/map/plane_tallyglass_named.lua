-- Captured from arrs:4000 (world prism) on 2026-10-18 by tools/mapcap.lua, wayfinder #29.
-- Area.Map. Two levels, 5 cells; one cell leads two ways (northeast, south).
return {
  area = "the Tally Glass",
  holds = {},
  names = {
    ["592"] = "the Tally Glass, the path foot",
    ["593"] = "the Tally Glass, the flat stones",
    ["594"] = "the Tally Glass, the hut front",
    ["595"] = "the Tally Glass, the sand warden's hut",
    ["596"] = "the Tally Glass, the sand cellar",
  },
  region = "the Saffron Fall",
  rooms = {
    ["592"] = {
      exits = {
        north = "593",
      },
      leads = {
        northeast = "the Pane Workings",
        south = "the Sand Road",
      },
      leaves = {
        "northeast",
        "south",
      },
      terrain = "field",
      x = 0,
      y = 0,
      z = 0,
    },
    ["593"] = {
      exits = {
        north = "594",
        south = "592",
      },
      terrain = "field",
      x = 0,
      y = 1,
      z = 0,
    },
    ["594"] = {
      exits = {
        hut = "595",
        south = "593",
      },
      terrain = "field",
      x = 0,
      y = 2,
      z = 0,
    },
    ["595"] = {
      exits = {
        down = "596",
        out = "594",
      },
      terrain = "inside",
      x = 0,
      y = 3,
      z = 0,
    },
    ["596"] = {
      exits = {
        up = "595",
      },
      terrain = "inside",
      x = 0,
      y = 4,
      z = -1,
    },
  },
}
