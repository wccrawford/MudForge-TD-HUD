-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Area.Map. Town, two levels (z 0 and 1).
return {
  area = "Gildhythe",
  holds = {},
  region = "the Saffron Fall",
  rooms = {
    ["217"] = {
      exits = {
        dyehouse = "222",
        north = "219",
        south = "249",
      },
      terrain = "city",
      x = 0,
      y = 2,
      z = 0,
    },
    ["218"] = {
      exits = {
        north = "220",
        south = "221",
        tanyard = "253",
      },
      terrain = "city",
      x = -1,
      y = 5,
      z = 0,
    },
    ["219"] = {
      exits = {
        northwest = "221",
        south = "217",
      },
      leaves = {
        "walkyard",
      },
      terrain = "city",
      x = 0,
      y = 3,
      z = 0,
    },
    ["220"] = {
      exits = {
        south = "218",
        up = "255",
      },
      leaves = {
        "north",
      },
      terrain = "city",
      x = -1,
      y = 6,
      z = 0,
    },
    ["221"] = {
      exits = {
        north = "218",
        southeast = "219",
      },
      terrain = "city",
      x = -1,
      y = 4,
      z = 0,
    },
    ["222"] = {
      exits = {
        out = "217",
      },
      terrain = "inside",
      x = 1,
      y = 2,
      z = 0,
    },
    ["223"] = {
      exits = {
        east = "226",
        glasshouse = "228",
        west = "227",
      },
      terrain = "city",
      x = 5,
      y = 0,
      z = 0,
    },
    ["224"] = {
      exits = {
        grindery = "230",
        southeast = "227",
        west = "225",
      },
      terrain = "city",
      x = 3,
      y = 1,
      z = 0,
    },
    ["225"] = {
      exits = {
        east = "224",
        smithy = "242",
        west = "248",
      },
      terrain = "city",
      x = 2,
      y = 1,
      z = 0,
    },
    ["226"] = {
      exits = {
        west = "223",
      },
      leaves = {
        "east",
      },
      terrain = "city",
      x = 6,
      y = 0,
      z = 0,
    },
    ["227"] = {
      exits = {
        east = "223",
        northwest = "224",
      },
      terrain = "city",
      x = 4,
      y = 0,
      z = 0,
    },
    ["228"] = {
      exits = {
        out = "223",
        up = "229",
      },
      terrain = "inside",
      x = 5,
      y = 1,
      z = 0,
    },
    ["229"] = {
      exits = {
        down = "228",
      },
      terrain = "inside",
      x = 5,
      y = 1,
      z = 1,
    },
    ["230"] = {
      exits = {
        out = "224",
      },
      terrain = "inside",
      x = 3,
      y = 0,
      z = 0,
    },
    ["231"] = {
      exits = {
        out = "235",
        up = "232",
      },
      terrain = "inside",
      x = 2,
      y = -4,
      z = 0,
    },
    ["232"] = {
      exits = {
        down = "231",
      },
      terrain = "inside",
      x = 2,
      y = -4,
      z = 1,
    },
    ["233"] = {
      exits = {
        north = "234",
        southeast = "237",
        storehouse = "246",
      },
      terrain = "city",
      x = 0,
      y = -2,
      z = 0,
    },
    ["234"] = {
      exits = {
        north = "247",
        south = "233",
        stillhouse = "243",
      },
      terrain = "city",
      x = 0,
      y = -1,
      z = 0,
    },
    ["235"] = {
      exits = {
        inn = "231",
        north = "237",
        south = "236",
      },
      terrain = "city",
      x = 1,
      y = -4,
      z = 0,
    },
    ["236"] = {
      exits = {
        north = "235",
      },
      leaves = {
        "south",
      },
      terrain = "city",
      x = 1,
      y = -5,
      z = 0,
    },
    ["237"] = {
      exits = {
        northwest = "233",
        south = "235",
        west = "245",
      },
      terrain = "city",
      x = 1,
      y = -3,
      z = 0,
    },
    ["238"] = {
      exits = {
        out = "252",
        up = "239",
      },
      terrain = "inside",
      x = -2,
      y = 0,
      z = 0,
    },
    ["239"] = {
      exits = {
        down = "238",
      },
      terrain = "inside",
      x = -2,
      y = 0,
      z = 1,
    },
    ["240"] = {
      exits = {
        east = "241",
      },
      leaves = {
        "bandhouse",
      },
      terrain = "city",
      x = -3,
      y = 1,
      z = 0,
    },
    ["241"] = {
      exits = {
        east = "250",
        west = "240",
      },
      terrain = "city",
      x = -2,
      y = 1,
      z = 0,
    },
    ["242"] = {
      exits = {
        out = "225",
      },
      terrain = "inside",
      x = 2,
      y = 2,
      z = 0,
    },
    ["243"] = {
      exits = {
        out = "234",
      },
      terrain = "inside",
      x = 1,
      y = -1,
      z = 0,
    },
    ["244"] = {
      exits = {
        east = "245",
      },
      terrain = "city",
      x = -1,
      y = -3,
      z = 0,
    },
    ["245"] = {
      exits = {
        east = "237",
        west = "244",
      },
      terrain = "city",
      x = 0,
      y = -3,
      z = 0,
    },
    ["246"] = {
      exits = {
        out = "233",
      },
      terrain = "inside",
      x = -1,
      y = -2,
      z = 0,
    },
    ["247"] = {
      exits = {
        east = "251",
        north = "249",
        northeast = "248",
        northwest = "250",
        south = "234",
        west = "252",
      },
      leaves = {
        "vault",
      },
      terrain = "city",
      x = 0,
      y = 0,
      z = 0,
    },
    ["248"] = {
      exits = {
        east = "225",
        south = "251",
        southwest = "247",
        west = "249",
      },
      terrain = "city",
      x = 1,
      y = 1,
      z = 0,
    },
    ["249"] = {
      exits = {
        east = "248",
        north = "217",
        south = "247",
        southeast = "251",
        southwest = "252",
        west = "250",
      },
      terrain = "city",
      x = 0,
      y = 1,
      z = 0,
    },
    ["250"] = {
      exits = {
        east = "249",
        south = "252",
        southeast = "247",
        west = "241",
      },
      terrain = "city",
      x = -1,
      y = 1,
      z = 0,
    },
    ["251"] = {
      exits = {
        north = "248",
        northwest = "249",
        west = "247",
      },
      terrain = "city",
      x = 1,
      y = 0,
      z = 0,
    },
    ["252"] = {
      exits = {
        east = "247",
        merehouse = "238",
        north = "250",
        northeast = "249",
      },
      terrain = "city",
      x = -1,
      y = 0,
      z = 0,
    },
    ["253"] = {
      exits = {
        out = "218",
      },
      terrain = "inside",
      x = 0,
      y = 5,
      z = 0,
    },
    ["255"] = {
      exits = {
        down = "220",
      },
      terrain = "inside",
      x = -1,
      y = 6,
      z = 1,
    },
  },
}
