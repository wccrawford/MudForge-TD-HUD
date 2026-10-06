-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). config map off sends nothing; config map on re-sends Area.Map and Area.Where.
return {
  {
    data = {
      clears_at_ms = 655991661,
      now_ms = 655991395,
    },
    pkg = "Char.RoundTime",
    seq = 2755,
    t = 1791288818611,
  },
  {
    data = {
      area = "the Mere Road",
      contents = {},
      desc = "The Bottle Shallows open off the road here, knee-deep water ...",
      exits = {
        east = 504,
        north = 405,
        south = 422,
      },
      key = "mereroad.2",
      name = "the Mere Road",
      num = 416,
      terrain = "road",
    },
    pkg = "Room.Info",
    seq = 2756,
    t = 1791288818611,
  },
  {
    data = {
      area = "the Mere Road",
      holds = {},
      region = "the Saffron Fall",
      rooms = {
        ["405"] = {
          exits = {
            south = "416",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = 0,
          y = 0,
          z = 0,
        },
        ["406"] = {
          exits = {
            northeast = "428",
            southwest = "407",
          },
          terrain = "road",
          x = -6,
          y = -9,
          z = 0,
        },
        ["407"] = {
          exits = {
            northeast = "406",
            west = "408",
          },
          terrain = "road",
          x = -7,
          y = -10,
          z = 0,
        },
        ["408"] = {
          exits = {
            east = "407",
            west = "409",
          },
          terrain = "road",
          x = -8,
          y = -10,
          z = 0,
        },
        ["409"] = {
          exits = {
            east = "408",
            west = "410",
          },
          leaves = {
            "south",
          },
          terrain = "road",
          x = -9,
          y = -10,
          z = 0,
        },
        ["410"] = {
          exits = {
            east = "409",
            west = "411",
          },
          terrain = "road",
          x = -10,
          y = -10,
          z = 0,
        },
        ["411"] = {
          exits = {
            east = "410",
            west = "412",
          },
          terrain = "road",
          x = -11,
          y = -10,
          z = 0,
        },
        ["412"] = {
          exits = {
            east = "411",
            west = "413",
          },
          terrain = "road",
          x = -12,
          y = -10,
          z = 0,
        },
        ["413"] = {
          exits = {
            east = "412",
            west = "414",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = -13,
          y = -10,
          z = 0,
        },
        ["414"] = {
          exits = {
            east = "413",
            west = "415",
          },
          terrain = "road",
          x = -14,
          y = -10,
          z = 0,
        },
        ["415"] = {
          exits = {
            east = "414",
            northwest = "417",
          },
          terrain = "road",
          x = -15,
          y = -10,
          z = 0,
        },
        ["416"] = {
          exits = {
            north = "405",
            south = "422",
          },
          leaves = {
            "east",
          },
          terrain = "road",
          x = 0,
          y = -1,
          z = 0,
        },
        ["417"] = {
          exits = {
            northwest = "418",
            southeast = "415",
          },
          terrain = "road",
          x = -16,
          y = -9,
          z = 0,
        },
        ["418"] = {
          exits = {
            northwest = "419",
            southeast = "417",
          },
          terrain = "road",
          x = -17,
          y = -8,
          z = 0,
        },
        ["419"] = {
          exits = {
            northwest = "420",
            southeast = "418",
          },
          leaves = {
            "west",
          },
          terrain = "road",
          x = -18,
          y = -7,
          z = 0,
        },
        ["420"] = {
          exits = {
            northwest = "421",
            southeast = "419",
          },
          terrain = "road",
          x = -19,
          y = -6,
          z = 0,
        },
        ["421"] = {
          exits = {
            southeast = "420",
          },
          terrain = "road",
          x = -20,
          y = -5,
          z = 0,
        },
        ["422"] = {
          exits = {
            north = "416",
            south = "423",
          },
          terrain = "road",
          x = 0,
          y = -2,
          z = 0,
        },
        ["423"] = {
          exits = {
            north = "422",
            southwest = "424",
          },
          terrain = "road",
          x = 0,
          y = -3,
          z = 0,
        },
        ["424"] = {
          exits = {
            northeast = "423",
            southwest = "425",
          },
          terrain = "road",
          x = -1,
          y = -4,
          z = 0,
        },
        ["425"] = {
          exits = {
            northeast = "424",
            southwest = "426",
          },
          terrain = "road",
          x = -2,
          y = -5,
          z = 0,
        },
        ["426"] = {
          exits = {
            northeast = "425",
            southwest = "427",
          },
          terrain = "road",
          x = -3,
          y = -6,
          z = 0,
        },
        ["427"] = {
          exits = {
            northeast = "426",
            southwest = "428",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = -4,
          y = -7,
          z = 0,
        },
        ["428"] = {
          exits = {
            northeast = "427",
            southwest = "406",
          },
          terrain = "road",
          x = -5,
          y = -8,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 2757,
    t = 1791288818613,
  },
  {
    data = {
      here = "416",
      members = {},
    },
    pkg = "Area.Where",
    seq = 2758,
    t = 1791288818613,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655992172,
    },
    pkg = "Char.RoundTime",
    seq = 2759,
    t = 1791288819385,
  },
  {
    data = {
      condition = {
        cur = 339,
        max = 339,
        name = "Unhurt",
        of = 5,
        tier = 1,
      },
      encumbrance = 72,
      focus = {
        cur = 99,
        max = 100,
        name = "sharp",
        of = 5,
        tier = 1,
      },
      footing = {
        cur = 100,
        max = 100,
        name = "steady",
        of = 5,
        tier = 1,
      },
      hp = 339,
      mana = 99,
      maxhp = 339,
      maxmana = 100,
      standing = {
        name = "low Apprentice",
        of = 5,
        tier = 4,
      },
    },
    pkg = "Char.Vitals",
    seq = 2760,
    t = 1791288820385,
  },
  {
    data = {
      condition = {
        cur = 339,
        max = 339,
        name = "Unhurt",
        of = 5,
        tier = 1,
      },
      encumbrance = 72,
      focus = {
        cur = 100,
        max = 100,
        name = "sharp",
        of = 5,
        tier = 1,
      },
      footing = {
        cur = 100,
        max = 100,
        name = "steady",
        of = 5,
        tier = 1,
      },
      hp = 339,
      mana = 100,
      maxhp = 339,
      maxmana = 100,
      standing = {
        name = "low Apprentice",
        of = 5,
        tier = 4,
      },
    },
    pkg = "Char.Vitals",
    seq = 2761,
    t = 1791288824385,
  },
  {
    data = {
      area = "the Mere Road",
      holds = {},
      region = "the Saffron Fall",
      rooms = {
        ["405"] = {
          exits = {
            south = "416",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = 0,
          y = 0,
          z = 0,
        },
        ["406"] = {
          exits = {
            northeast = "428",
            southwest = "407",
          },
          terrain = "road",
          x = -6,
          y = -9,
          z = 0,
        },
        ["407"] = {
          exits = {
            northeast = "406",
            west = "408",
          },
          terrain = "road",
          x = -7,
          y = -10,
          z = 0,
        },
        ["408"] = {
          exits = {
            east = "407",
            west = "409",
          },
          terrain = "road",
          x = -8,
          y = -10,
          z = 0,
        },
        ["409"] = {
          exits = {
            east = "408",
            west = "410",
          },
          leaves = {
            "south",
          },
          terrain = "road",
          x = -9,
          y = -10,
          z = 0,
        },
        ["410"] = {
          exits = {
            east = "409",
            west = "411",
          },
          terrain = "road",
          x = -10,
          y = -10,
          z = 0,
        },
        ["411"] = {
          exits = {
            east = "410",
            west = "412",
          },
          terrain = "road",
          x = -11,
          y = -10,
          z = 0,
        },
        ["412"] = {
          exits = {
            east = "411",
            west = "413",
          },
          terrain = "road",
          x = -12,
          y = -10,
          z = 0,
        },
        ["413"] = {
          exits = {
            east = "412",
            west = "414",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = -13,
          y = -10,
          z = 0,
        },
        ["414"] = {
          exits = {
            east = "413",
            west = "415",
          },
          terrain = "road",
          x = -14,
          y = -10,
          z = 0,
        },
        ["415"] = {
          exits = {
            east = "414",
            northwest = "417",
          },
          terrain = "road",
          x = -15,
          y = -10,
          z = 0,
        },
        ["416"] = {
          exits = {
            north = "405",
            south = "422",
          },
          leaves = {
            "east",
          },
          terrain = "road",
          x = 0,
          y = -1,
          z = 0,
        },
        ["417"] = {
          exits = {
            northwest = "418",
            southeast = "415",
          },
          terrain = "road",
          x = -16,
          y = -9,
          z = 0,
        },
        ["418"] = {
          exits = {
            northwest = "419",
            southeast = "417",
          },
          terrain = "road",
          x = -17,
          y = -8,
          z = 0,
        },
        ["419"] = {
          exits = {
            northwest = "420",
            southeast = "418",
          },
          leaves = {
            "west",
          },
          terrain = "road",
          x = -18,
          y = -7,
          z = 0,
        },
        ["420"] = {
          exits = {
            northwest = "421",
            southeast = "419",
          },
          terrain = "road",
          x = -19,
          y = -6,
          z = 0,
        },
        ["421"] = {
          exits = {
            southeast = "420",
          },
          terrain = "road",
          x = -20,
          y = -5,
          z = 0,
        },
        ["422"] = {
          exits = {
            north = "416",
            south = "423",
          },
          terrain = "road",
          x = 0,
          y = -2,
          z = 0,
        },
        ["423"] = {
          exits = {
            north = "422",
            southwest = "424",
          },
          terrain = "road",
          x = 0,
          y = -3,
          z = 0,
        },
        ["424"] = {
          exits = {
            northeast = "423",
            southwest = "425",
          },
          terrain = "road",
          x = -1,
          y = -4,
          z = 0,
        },
        ["425"] = {
          exits = {
            northeast = "424",
            southwest = "426",
          },
          terrain = "road",
          x = -2,
          y = -5,
          z = 0,
        },
        ["426"] = {
          exits = {
            northeast = "425",
            southwest = "427",
          },
          terrain = "road",
          x = -3,
          y = -6,
          z = 0,
        },
        ["427"] = {
          exits = {
            northeast = "426",
            southwest = "428",
          },
          leaves = {
            "north",
          },
          terrain = "road",
          x = -4,
          y = -7,
          z = 0,
        },
        ["428"] = {
          exits = {
            northeast = "427",
            southwest = "406",
          },
          terrain = "road",
          x = -5,
          y = -8,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 2770,
    t = 1791288839978,
  },
  {
    data = {
      here = "416",
      members = {},
    },
    pkg = "Area.Where",
    seq = 2771,
    t = 1791288839978,
  },
  {
    data = {
      clears_at_ms = 656068777,
      now_ms = 656068511,
    },
    pkg = "Char.RoundTime",
    seq = 2791,
    t = 1791288895769,
  },
  {
    data = {
      area = "the Mere Road",
      contents = {},
      desc = "The Gilt Mere lies flat and gold past the landing, and the r...",
      exits = {
        north = 236,
        south = 416,
      },
      key = "mereroad.1",
      name = "the Mere Road",
      num = 405,
      terrain = "road",
    },
    pkg = "Room.Info",
    seq = 2792,
    t = 1791288895769,
  },
  {
    data = {
      here = "405",
      members = {},
    },
    pkg = "Area.Where",
    seq = 2793,
    t = 1791288895771,
  },
}
