-- Captured from arrs:4000 (world prism) on 2026-10-18 by tools/mapcap.lua, wayfinder #29.
-- Area.Map. A 1-wide road, 20 cells, 6 distinct names; leads on six cells, one per Area it joins.
return {
  area = "the Green Road",
  holds = {},
  names = {
    ["381"] = "the Green Road",
    ["382"] = "the Plank Bridge",
    ["383"] = "Bell Lane",
    ["384"] = "Bell Lane",
    ["385"] = "Bell Lane",
    ["386"] = "the Fringe Walk",
    ["387"] = "the Fringe Walk",
    ["388"] = "the Fringe Walk",
    ["389"] = "the Fringe Walk",
    ["390"] = "the Fringe Walk",
    ["391"] = "the Treeline",
    ["392"] = "the Green Road",
    ["393"] = "the Treeline",
    ["394"] = "the Green Road",
    ["395"] = "the Reed Causeway",
    ["396"] = "the Reed Causeway",
    ["397"] = "the Reed Causeway",
    ["398"] = "the Reed Causeway",
    ["399"] = "the Reed Causeway",
    ["400"] = "the Plank Bridge",
  },
  region = "the Saffron Fall",
  rooms = {
    ["381"] = {
      exits = {
        north = "392",
      },
      leads = {
        south = "Gildhythe",
      },
      leaves = {
        "south",
      },
      terrain = "road",
      x = 0,
      y = 0,
      z = 0,
    },
    ["382"] = {
      exits = {
        north = "383",
        south = "400",
      },
      terrain = "road",
      x = 0,
      y = 9,
      z = 0,
    },
    ["383"] = {
      exits = {
        north = "384",
        south = "382",
      },
      terrain = "road",
      x = 0,
      y = 10,
      z = 0,
    },
    ["384"] = {
      exits = {
        north = "385",
        south = "383",
      },
      leads = {
        west = "the Bellwater",
      },
      leaves = {
        "west",
      },
      terrain = "road",
      x = 0,
      y = 11,
      z = 0,
    },
    ["385"] = {
      exits = {
        north = "386",
        south = "384",
      },
      terrain = "road",
      x = 0,
      y = 12,
      z = 0,
    },
    ["386"] = {
      exits = {
        north = "387",
        south = "385",
      },
      terrain = "road",
      x = 0,
      y = 13,
      z = 0,
    },
    ["387"] = {
      exits = {
        north = "388",
        south = "386",
      },
      terrain = "road",
      x = 0,
      y = 14,
      z = 0,
    },
    ["388"] = {
      exits = {
        north = "389",
        south = "387",
      },
      leads = {
        east = "the Ochre Fringe",
      },
      leaves = {
        "east",
      },
      terrain = "road",
      x = 0,
      y = 15,
      z = 0,
    },
    ["389"] = {
      exits = {
        north = "390",
        south = "388",
      },
      terrain = "road",
      x = 0,
      y = 16,
      z = 0,
    },
    ["390"] = {
      exits = {
        north = "391",
        south = "389",
      },
      terrain = "road",
      x = 0,
      y = 17,
      z = 0,
    },
    ["391"] = {
      exits = {
        north = "393",
        south = "390",
      },
      terrain = "road",
      x = 0,
      y = 18,
      z = 0,
    },
    ["392"] = {
      exits = {
        north = "394",
        south = "381",
      },
      leads = {
        west = "the Tenter Waste",
      },
      leaves = {
        "west",
      },
      terrain = "road",
      x = 0,
      y = 1,
      z = 0,
    },
    ["393"] = {
      exits = {
        south = "391",
      },
      leads = {
        north = "Stubbing",
      },
      leaves = {
        "north",
      },
      terrain = "road",
      x = 0,
      y = 19,
      z = 0,
    },
    ["394"] = {
      exits = {
        north = "395",
        south = "392",
      },
      terrain = "road",
      x = 0,
      y = 2,
      z = 0,
    },
    ["395"] = {
      exits = {
        north = "396",
        south = "394",
      },
      terrain = "road",
      x = 0,
      y = 3,
      z = 0,
    },
    ["396"] = {
      exits = {
        north = "397",
        south = "395",
      },
      terrain = "road",
      x = 0,
      y = 4,
      z = 0,
    },
    ["397"] = {
      exits = {
        north = "398",
        south = "396",
      },
      leads = {
        east = "the Stalk Beds",
      },
      leaves = {
        "east",
      },
      terrain = "road",
      x = 0,
      y = 5,
      z = 0,
    },
    ["398"] = {
      exits = {
        north = "399",
        south = "397",
      },
      terrain = "road",
      x = 0,
      y = 6,
      z = 0,
    },
    ["399"] = {
      exits = {
        north = "400",
        south = "398",
      },
      terrain = "road",
      x = 0,
      y = 7,
      z = 0,
    },
    ["400"] = {
      exits = {
        north = "382",
        south = "399",
      },
      terrain = "road",
      x = 0,
      y = 8,
      z = 0,
    },
  },
}
