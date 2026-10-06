-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). At the closed vault door, west to the windlass, work it: Area.Map re-sent alone with closed = false.
return {
  {
    data = {
      area = "the Spit Cut",
      contents = {
        "a chest",
        "a slip eel",
        "a slip eel",
        "a slip eel",
      },
      desc = "The vault door is a slab of tarred timber set into the spit'...",
      doors = {
        north = {
          closed = true,
          name = "vault door",
        },
      },
      exits = {
        north = 708,
        west = 691,
      },
      key = "jarvaults-1.tide_slip_vault_door",
      name = "the tide slip, the vault door",
      num = 690,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1426,
    t = 1791288579229,
  },
  {
    data = {
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
    },
    pkg = "Area.Map",
    seq = 1427,
    t = 1791288579231,
  },
  {
    data = {
      here = "d12",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1428,
    t = 1791288579231,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655753410,
    },
    pkg = "Char.RoundTime",
    seq = 1429,
    t = 1791288580390,
  },
  {
    data = {
      clears_at_ms = 655753882,
      now_ms = 655753616,
    },
    pkg = "Char.RoundTime",
    seq = 1439,
    t = 1791288580602,
  },
  {
    data = {
      area = "the Spit Cut",
      contents = {
        "the slip windlass",
      },
      desc = "A windlass stands on the planks against the vault face, its ...",
      exits = {
        east = 690,
        west = 687,
      },
      key = "jarvaults-1.tide_slip_windlass",
      name = "the tide slip, the windlass",
      num = 691,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1440,
    t = 1791288580602,
  },
  {
    data = {
      here = "d11",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1441,
    t = 1791288580603,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655754408,
    },
    pkg = "Char.RoundTime",
    seq = 1442,
    t = 1791288581390,
  },
  {
    data = {
      clears_at_ms = 655758769,
      now_ms = 655758569,
    },
    pkg = "Char.RoundTime",
    seq = 1447,
    t = 1791288585560,
  },
  {
    data = {
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
              closed = false,
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
    },
    pkg = "Area.Map",
    seq = 1448,
    t = 1791288585560,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655759405,
    },
    pkg = "Char.RoundTime",
    seq = 1449,
    t = 1791288586391,
  },
}
