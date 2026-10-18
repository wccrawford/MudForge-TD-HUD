-- Captured from arrs:4000 (world prism) on 2026-10-18 by tools/mapcap.lua, wayfinder #29.
-- Area.Map. Expedition copy (giltstand-2), lettered ids: names for entered rooms only, no leads on its leaves.
return {
  area = "the Ringing Rows",
  holds = {},
  names = {
    d14 = "the stump rows, the gate side",
    d15 = "the stump rows, the first stumps",
    d16 = "the stump rows",
    d17 = "the stump rows, the wedge stump",
    d18 = "the stump rows",
    d19 = "the stump rows, the far stumps",
    d20 = "the cutters' last cut",
    d21 = "the cutters' last cut, the fresh sawdust",
    d22 = "the cutters' last cut",
    d23 = "the cutters' last cut, the closed cut",
  },
  region = "the Saffron Fall",
  rooms = {
    d14 = {
      doors = {
        south = {
          closed = false,
          name = "yard gate",
        },
      },
      exits = {
        north = "d15",
      },
      leaves = {
        "south",
      },
      terrain = "forest",
      x = 0,
      y = 0,
      z = 0,
    },
    d15 = {
      exits = {
        north = "d16",
        south = "d14",
      },
      terrain = "forest",
      x = 0,
      y = 1,
      z = 0,
    },
    d16 = {
      exits = {
        northeast = "d17",
        south = "d15",
      },
      terrain = "forest",
      x = 0,
      y = 2,
      z = 0,
    },
    d17 = {
      exits = {
        north = "d18",
        southwest = "d16",
      },
      terrain = "forest",
      x = 1,
      y = 3,
      z = 0,
    },
    d18 = {
      exits = {
        north = "d19",
        south = "d17",
      },
      terrain = "forest",
      x = 1,
      y = 4,
      z = 0,
    },
    d19 = {
      exits = {
        east = "d20",
        south = "d18",
      },
      terrain = "forest",
      x = 1,
      y = 5,
      z = 0,
    },
    d20 = {
      exits = {
        east = "d21",
        west = "d19",
      },
      terrain = "forest",
      x = 2,
      y = 5,
      z = 0,
    },
    d21 = {
      exits = {
        northeast = "d22",
        west = "d20",
      },
      terrain = "forest",
      x = 3,
      y = 5,
      z = 0,
    },
    d22 = {
      exits = {
        northeast = "d23",
        southwest = "d21",
      },
      terrain = "forest",
      x = 4,
      y = 6,
      z = 0,
    },
    d23 = {
      doors = {
        north = {
          closed = true,
          name = "lodge door",
        },
      },
      exits = {
        southwest = "d22",
      },
      leaves = {
        "north",
      },
      terrain = "forest",
      x = 5,
      y = 7,
      z = 0,
    },
  },
}
