-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Area.Map. Depth 1 fully walked: no terrain, no region; leaves up and down.
return {
  area = "the Lees, Depth 1",
  holds = {},
  rooms = {
    d1 = {
      exits = {
        east = "d6",
        southwest = "d9",
        west = "d2",
      },
      leaves = {
        "up",
      },
      x = 0,
      y = 0,
      z = 0,
    },
    d10 = {
      exits = {
        east = "d5",
      },
      x = 0,
      y = 2,
      z = 0,
    },
    d11 = {
      doors = {
        east = {
          closed = false,
          name = "wax seal",
        },
      },
      exits = {
        east = "d12",
        southwest = "d7",
      },
      x = 2,
      y = 0,
      z = 0,
    },
    d12 = {
      doors = {
        west = {
          closed = false,
          name = "wax seal",
        },
      },
      exits = {
        west = "d11",
      },
      leaves = {
        "down",
      },
      x = 3,
      y = 0,
      z = 0,
    },
    d2 = {
      exits = {
        east = "d1",
        north = "d3",
      },
      x = -1,
      y = 0,
      z = 0,
    },
    d3 = {
      exits = {
        east = "d4",
        south = "d2",
      },
      x = -1,
      y = 1,
      z = 0,
    },
    d4 = {
      exits = {
        northeast = "d5",
        southeast = "d6",
        west = "d3",
      },
      x = 0,
      y = 1,
      z = 0,
    },
    d5 = {
      exits = {
        southwest = "d4",
        west = "d10",
      },
      x = 1,
      y = 2,
      z = 0,
    },
    d6 = {
      exits = {
        northwest = "d4",
        south = "d7",
        southwest = "d8",
        west = "d1",
      },
      x = 1,
      y = 0,
      z = 0,
    },
    d7 = {
      exits = {
        north = "d6",
        northeast = "d11",
        west = "d8",
      },
      x = 1,
      y = -1,
      z = 0,
    },
    d8 = {
      exits = {
        east = "d7",
        northeast = "d6",
      },
      x = 0,
      y = -1,
      z = 0,
    },
    d9 = {
      exits = {
        northeast = "d1",
      },
      x = -1,
      y = -1,
      z = 0,
    },
  },
}
