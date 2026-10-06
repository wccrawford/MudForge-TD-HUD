-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Area.Map. Expedition member 1 at the vault door: 12 rooms, the door in leaves is closed.
return {
  area = "the Spit Cut",
  holds = {},
  region = "the Saffron Fall",
  rooms = {
    d1 = {
      exits = {
        north = "d2",
      },
      leaves = {
        "south",
      },
      terrain = "field",
      x = 0,
      y = 0,
      z = 0,
    },
    d10 = {
      exits = {
        east = "d11",
        southwest = "d9",
      },
      terrain = "field",
      x = 1,
      y = 9,
      z = 0,
    },
    d11 = {
      exits = {
        east = "d12",
        west = "d10",
      },
      terrain = "field",
      x = 2,
      y = 9,
      z = 0,
    },
    d12 = {
      doors = {
        north = {
          closed = true,
          name = "vault door",
        },
      },
      exits = {
        west = "d11",
      },
      leaves = {
        "north",
      },
      terrain = "field",
      x = 3,
      y = 9,
      z = 0,
    },
    d2 = {
      exits = {
        northeast = "d3",
        south = "d1",
      },
      terrain = "field",
      x = 0,
      y = 1,
      z = 0,
    },
    d3 = {
      exits = {
        north = "d4",
        southwest = "d2",
      },
      terrain = "field",
      x = 1,
      y = 2,
      z = 0,
    },
    d4 = {
      exits = {
        north = "d5",
        south = "d3",
      },
      terrain = "field",
      x = 1,
      y = 3,
      z = 0,
    },
    d5 = {
      exits = {
        northwest = "d6",
        south = "d4",
      },
      terrain = "field",
      x = 1,
      y = 4,
      z = 0,
    },
    d6 = {
      exits = {
        northwest = "d7",
        southeast = "d5",
      },
      terrain = "field",
      x = 0,
      y = 5,
      z = 0,
    },
    d7 = {
      exits = {
        north = "d8",
        southeast = "d6",
      },
      terrain = "field",
      x = -1,
      y = 6,
      z = 0,
    },
    d8 = {
      exits = {
        northeast = "d9",
        south = "d7",
      },
      terrain = "field",
      x = -1,
      y = 7,
      z = 0,
    },
    d9 = {
      exits = {
        northeast = "d10",
        southwest = "d8",
      },
      terrain = "field",
      x = 0,
      y = 8,
      z = 0,
    },
  },
}
