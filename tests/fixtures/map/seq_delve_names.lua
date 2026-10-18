-- Captured from arrs:4000 (world prism) on 2026-10-18 by tools/mapcap.lua, wayfinder #29.
-- Packages in arrival order (seq, t ms), Area.Map and Area.Where only. The Lees, Depth 1 grown
-- from 1 room to 9 (names grow with it, only entered rooms named, no leads), then Depth 2.
return {
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
      },
      rooms = {
        d1 = {
          leaves = {
            "up",
          },
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
    seq = 4550,
    t = 1792318597581,
  },
  {
    data = {
      here = "d1",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4551,
    t = 1792318597582,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
      },
      rooms = {
        d1 = {
          exits = {
            west = "d2",
          },
          leaves = {
            "up",
          },
          unexplored = {
            "north",
            "east",
          },
          x = 0,
          y = 0,
          z = 0,
        },
        d2 = {
          exits = {
            east = "d1",
          },
          unexplored = {
            "north",
          },
          x = -1,
          y = 0,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4564,
    t = 1792318599695,
  },
  {
    data = {
      here = "d2",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4565,
    t = 1792318599696,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
      },
      rooms = {
        d1 = {
          exits = {
            west = "d2",
          },
          leaves = {
            "up",
          },
          unexplored = {
            "north",
            "east",
          },
          x = 0,
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
            south = "d2",
          },
          unexplored = {
            "west",
            "east",
          },
          x = -1,
          y = 1,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4578,
    t = 1792318601694,
  },
  {
    data = {
      here = "d3",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4579,
    t = 1792318601694,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
      },
      rooms = {
        d1 = {
          exits = {
            west = "d2",
          },
          leaves = {
            "up",
          },
          unexplored = {
            "north",
            "east",
          },
          x = 0,
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
            south = "d2",
            west = "d4",
          },
          unexplored = {
            "east",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4591,
    t = 1792318602195,
  },
  {
    data = {
      here = "d4",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4592,
    t = 1792318602196,
  },
  {
    data = {
      here = "d3",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4604,
    t = 1792318602807,
  },
  {
    data = {
      here = "d2",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4616,
    t = 1792318603065,
  },
  {
    data = {
      here = "d3",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4629,
    t = 1792318603528,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
      },
      rooms = {
        d1 = {
          exits = {
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          unexplored = {
            "east",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            south = "d1",
            west = "d3",
          },
          unexplored = {
            "north",
          },
          x = 0,
          y = 1,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4641,
    t = 1792318603764,
  },
  {
    data = {
      here = "d5",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4642,
    t = 1792318603764,
  },
  {
    data = {
      here = "d1",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4655,
    t = 1792318604371,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
        d6 = "the slumped cell",
      },
      rooms = {
        d1 = {
          exits = {
            east = "d6",
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            south = "d1",
            west = "d3",
          },
          unexplored = {
            "north",
          },
          x = 0,
          y = 1,
          z = 0,
        },
        d6 = {
          exits = {
            west = "d1",
          },
          x = 1,
          y = 0,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4667,
    t = 1792318604565,
  },
  {
    data = {
      here = "d6",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4668,
    t = 1792318604566,
  },
  {
    data = {
      here = "d1",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4682,
    t = 1792318605191,
  },
  {
    data = {
      here = "d5",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4694,
    t = 1792318605390,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
        d6 = "the slumped cell",
        d7 = "the brass hall",
      },
      rooms = {
        d1 = {
          exits = {
            east = "d6",
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            north = "d7",
            south = "d1",
            west = "d3",
          },
          x = 0,
          y = 1,
          z = 0,
        },
        d6 = {
          exits = {
            west = "d1",
          },
          x = 1,
          y = 0,
          z = 0,
        },
        d7 = {
          exits = {
            south = "d5",
          },
          unexplored = {
            "north",
          },
          x = 0,
          y = 2,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4706,
    t = 1792318605634,
  },
  {
    data = {
      here = "d7",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4707,
    t = 1792318605634,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
        d6 = "the slumped cell",
        d7 = "the brass hall",
        d8 = "the brass vault",
      },
      rooms = {
        d1 = {
          exits = {
            east = "d6",
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            north = "d7",
            south = "d1",
            west = "d3",
          },
          x = 0,
          y = 1,
          z = 0,
        },
        d6 = {
          exits = {
            west = "d1",
          },
          x = 1,
          y = 0,
          z = 0,
        },
        d7 = {
          exits = {
            north = "d8",
            south = "d5",
          },
          x = 0,
          y = 2,
          z = 0,
        },
        d8 = {
          doors = {
            north = {
              closed = true,
              name = "wax seal",
            },
          },
          exits = {
            south = "d7",
          },
          unexplored = {
            "north",
          },
          x = 0,
          y = 3,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4720,
    t = 1792318606055,
  },
  {
    data = {
      here = "d8",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4721,
    t = 1792318606056,
  },
  {
    data = {
      here = "d7",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4739,
    t = 1792318611676,
  },
  {
    data = {
      here = "d5",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4751,
    t = 1792318611915,
  },
  {
    data = {
      here = "d1",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4764,
    t = 1792318612637,
  },
  {
    data = {
      here = "d5",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4776,
    t = 1792318612941,
  },
  {
    data = {
      here = "d7",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4788,
    t = 1792318613113,
  },
  {
    data = {
      here = "d8",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4802,
    t = 1792318613359,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
        d6 = "the slumped cell",
        d7 = "the brass hall",
        d8 = "the brass vault",
      },
      rooms = {
        d1 = {
          exits = {
            east = "d6",
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            north = "d7",
            south = "d1",
            west = "d3",
          },
          x = 0,
          y = 1,
          z = 0,
        },
        d6 = {
          exits = {
            west = "d1",
          },
          x = 1,
          y = 0,
          z = 0,
        },
        d7 = {
          exits = {
            north = "d8",
            south = "d5",
          },
          x = 0,
          y = 2,
          z = 0,
        },
        d8 = {
          doors = {
            north = {
              closed = false,
              name = "wax seal",
            },
          },
          exits = {
            south = "d7",
          },
          unexplored = {
            "north",
          },
          x = 0,
          y = 3,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4834,
    t = 1792318632388,
  },
  {
    data = {
      area = "the Lees, Depth 1",
      holds = {},
      names = {
        d1 = "the old marks",
        d2 = "the gilded rope",
        d3 = "the wet steps",
        d4 = "the cork store",
        d5 = "the cracked landing",
        d6 = "the slumped cell",
        d7 = "the brass hall",
        d8 = "the brass vault",
        d9 = "the sinking steps",
      },
      rooms = {
        d1 = {
          exits = {
            east = "d6",
            north = "d5",
            west = "d2",
          },
          leaves = {
            "up",
          },
          x = 0,
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
            east = "d5",
            south = "d2",
            west = "d4",
          },
          x = -1,
          y = 1,
          z = 0,
        },
        d4 = {
          exits = {
            east = "d3",
          },
          x = -2,
          y = 1,
          z = 0,
        },
        d5 = {
          exits = {
            north = "d7",
            south = "d1",
            west = "d3",
          },
          x = 0,
          y = 1,
          z = 0,
        },
        d6 = {
          exits = {
            west = "d1",
          },
          x = 1,
          y = 0,
          z = 0,
        },
        d7 = {
          exits = {
            north = "d8",
            south = "d5",
          },
          x = 0,
          y = 2,
          z = 0,
        },
        d8 = {
          doors = {
            north = {
              closed = false,
              name = "wax seal",
            },
          },
          exits = {
            north = "d9",
            south = "d7",
          },
          x = 0,
          y = 3,
          z = 0,
        },
        d9 = {
          doors = {
            south = {
              closed = false,
              name = "wax seal",
            },
          },
          exits = {
            south = "d8",
          },
          leaves = {
            "down",
          },
          x = 0,
          y = 4,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 4863,
    t = 1792318639355,
  },
  {
    data = {
      here = "d9",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4864,
    t = 1792318639356,
  },
  {
    data = {
      area = "the Lees, Depth 2",
      holds = {},
      names = {
        d10 = "the cracked landing",
      },
      rooms = {
        d10 = {
          leaves = {
            "up",
          },
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
    seq = 4880,
    t = 1792318640795,
  },
  {
    data = {
      here = "d10",
      members = {},
    },
    pkg = "Area.Where",
    seq = 4881,
    t = 1792318640795,
  },
}
