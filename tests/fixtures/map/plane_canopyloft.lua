-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Area.Map. Small interior Area (6 rooms), one leaves.
return {
  area = "The Canopy Loft",
  holds = {},
  region = "the Overgrowth",
  rooms = {
    ["1291"] = {
      exits = {
        north = "1293",
      },
      terrain = "inside",
      x = 1,
      y = -1,
      z = 0,
    },
    ["1292"] = {
      exits = {
        east = "1293",
        north = "1295",
        south = "1296",
      },
      leaves = {
        "out",
      },
      terrain = "inside",
      x = 0,
      y = 0,
      z = 0,
    },
    ["1293"] = {
      exits = {
        north = "1294",
        south = "1291",
        west = "1292",
      },
      terrain = "inside",
      x = 1,
      y = 0,
      z = 0,
    },
    ["1294"] = {
      exits = {
        south = "1293",
      },
      terrain = "inside",
      x = 1,
      y = 1,
      z = 0,
    },
    ["1295"] = {
      exits = {
        south = "1292",
      },
      terrain = "inside",
      x = 0,
      y = 1,
      z = 0,
    },
    ["1296"] = {
      exits = {
        north = "1292",
      },
      terrain = "inside",
      x = 0,
      y = -1,
      z = 0,
    },
  },
}
