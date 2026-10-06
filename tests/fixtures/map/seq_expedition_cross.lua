-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). Spit Cut to the Stopper Vaults and back: a new Area.Map each way.
return {
  {
    data = {
      clears_at_ms = 655760911,
      now_ms = 655760645,
    },
    pkg = "Char.RoundTime",
    seq = 1460,
    t = 1791288587635,
  },
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
          closed = false,
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
    seq = 1461,
    t = 1791288587636,
  },
  {
    data = {
      here = "d12",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1462,
    t = 1791288587637,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655761404,
    },
    pkg = "Char.RoundTime",
    seq = 1463,
    t = 1791288588391,
  },
  {
    data = {
      clears_at_ms = 655762153,
      now_ms = 655761887,
    },
    pkg = "Char.RoundTime",
    seq = 1475,
    t = 1791288588879,
  },
  {
    data = {
      area = "the Stopper Vaults",
      contents = {
        "Wenna Hask",
      },
      desc = "The vault door gives onto a hall cut back into the spit, its...",
      doors = {
        south = {
          closed = false,
          name = "vault door",
        },
      },
      exits = {
        east = 710,
        north = 709,
        south = 690,
        west = 707,
      },
      key = "jarvaults-2.vault_hall_hall_1",
      name = "the vault hall",
      num = 708,
      terrain = "inside",
    },
    pkg = "Room.Info",
    seq = 1476,
    t = 1791288588879,
  },
  {
    data = {
      area = "the Stopper Vaults",
      holds = {},
      region = "the Saffron Fall",
      rooms = {
        d13 = {
          doors = {
            south = {
              closed = false,
              name = "vault door",
            },
          },
          leaves = {
            "south",
          },
          terrain = "inside",
          unexplored = {
            "north",
            "west",
            "east",
          },
          x = 0,
          y = 0,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 1477,
    t = 1791288588880,
  },
  {
    data = {
      here = "d13",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1478,
    t = 1791288588880,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655762402,
    },
    pkg = "Char.RoundTime",
    seq = 1479,
    t = 1791288589391,
  },
  {
    data = {
      clears_at_ms = 655777540,
      now_ms = 655777274,
    },
    pkg = "Char.RoundTime",
    seq = 1492,
    t = 1791288604276,
  },
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
          closed = false,
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
    seq = 1493,
    t = 1791288604276,
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
    seq = 1494,
    t = 1791288604278,
  },
  {
    data = {
      here = "d12",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1495,
    t = 1791288604278,
  },
}
