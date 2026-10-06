-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). Entering the Spit Cut and walking: Area.Map re-sent in full as each room is entered.
return {
  {
    data = {
      clears_at_ms = 655739002,
      now_ms = 655738736,
    },
    pkg = "Char.RoundTime",
    seq = 1273,
    t = 1791288565707,
  },
  {
    data = {
      area = "the Spit Cut",
      contents = {},
      desc = "Steps cut into the white shell grit drop off the spit at the...",
      exits = {
        north = 684,
        south = 401,
      },
      key = "jarvaults-1.lamp_foot_spit_stair",
      name = "the lamp foot, the spit stair",
      num = 686,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1274,
    t = 1791288565708,
  },
  {
    data = {
      area = "the Spit Cut",
      holds = {},
      region = "the Saffron Fall",
      rooms = {
        d1 = {
          leaves = {
            "south",
          },
          terrain = "field",
          unexplored = {
            "north",
          },
          x = 0,
          y = 0,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 1275,
    t = 1791288565709,
  },
  {
    data = {
      here = "d1",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1276,
    t = 1791288565709,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655739428,
    },
    pkg = "Char.RoundTime",
    seq = 1277,
    t = 1791288566391,
  },
  {
    data = {
      clears_at_ms = 655748166,
      now_ms = 655747900,
    },
    pkg = "Char.RoundTime",
    seq = 1289,
    t = 1791288574863,
  },
  {
    data = {
      area = "the Spit Cut",
      contents = {},
      desc = "The path runs along under the spit's bank, where the grit ha...",
      exits = {
        northeast = 685,
        south = 686,
      },
      key = "jarvaults-1.lamp_foot_2",
      name = "the lamp foot",
      num = 684,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1290,
    t = 1791288574863,
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
        d2 = {
          exits = {
            south = "d1",
          },
          terrain = "field",
          unexplored = {
            "northeast",
          },
          x = 0,
          y = 1,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 1291,
    t = 1791288574865,
  },
  {
    data = {
      here = "d2",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1292,
    t = 1791288574865,
  },
  {
    data = {
      clears_at_ms = 655748541,
      now_ms = 655748275,
    },
    pkg = "Char.RoundTime",
    seq = 1302,
    t = 1791288575247,
  },
  {
    data = {
      area = "the Spit Cut",
      contents = {
        "a grit louse",
        "a grit louse",
        "a grit louse",
      },
      desc = "The bank opens here into a cut through the grit, its walls s...",
      exits = {
        north = 680,
        southwest = 684,
      },
      key = "jarvaults-1.lamp_foot_head_of_the_cut",
      name = "the lamp foot, the cut's head",
      num = 685,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1303,
    t = 1791288575247,
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
            southwest = "d2",
          },
          terrain = "field",
          unexplored = {
            "north",
          },
          x = 1,
          y = 2,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 1304,
    t = 1791288575248,
  },
  {
    data = {
      here = "d3",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1305,
    t = 1791288575248,
  },
  {
    data = {
      clears_at_ms = 655748932,
      now_ms = 655748666,
    },
    pkg = "Char.RoundTime",
    seq = 1316,
    t = 1791288575641,
  },
  {
    data = {
      area = "the Spit Cut",
      contents = {},
      desc = "The cut runs down between walls of packed shell, white and l...",
      exits = {
        north = 683,
        south = 685,
      },
      key = "jarvaults-1.grit_cut_1",
      name = "the grit cut",
      num = 680,
      terrain = "field",
    },
    pkg = "Room.Info",
    seq = 1317,
    t = 1791288575641,
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
            south = "d3",
          },
          terrain = "field",
          unexplored = {
            "north",
          },
          x = 1,
          y = 3,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 1318,
    t = 1791288575643,
  },
  {
    data = {
      here = "d4",
      members = {},
    },
    pkg = "Area.Where",
    seq = 1319,
    t = 1791288575643,
  },
}
