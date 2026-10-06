-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). Green Road into Stubbing: Room.Info, Area.Map, Area.Where in one burst.
return {
  {
    data = {
      clears_at_ms = 655559260,
      now_ms = 655558994,
    },
    pkg = "Char.RoundTime",
    seq = 198,
    t = 1791288385786,
  },
  {
    data = {
      area = "the Green Road",
      contents = {},
      desc = "The track runs on under the treeline, cut back to the width ...",
      exits = {
        north = 1285,
        south = 391,
      },
      key = "greenroad.20",
      name = "the Treeline",
      num = 393,
      terrain = "road",
    },
    pkg = "Room.Info",
    seq = 199,
    t = 1791288385786,
  },
  {
    data = {
      area = "the Green Road",
      holds = {},
      region = "the Saffron Fall",
      rooms = {
        ["381"] = {
          exits = {
            north = "392",
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
    },
    pkg = "Area.Map",
    seq = 200,
    t = 1791288385787,
  },
  {
    data = {
      here = "393",
      members = {},
    },
    pkg = "Area.Where",
    seq = 201,
    t = 1791288385787,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655559606,
    },
    pkg = "Char.RoundTime",
    seq = 202,
    t = 1791288386395,
  },
  {
    data = {
      clears_at_ms = 655576324,
      now_ms = 655576058,
    },
    pkg = "Char.RoundTime",
    seq = 216,
    t = 1791288402853,
  },
  {
    data = {
      area = "Stubbing",
      contents = {
        "the gate bar",
      },
      desc = "The stockade closes in here on both sides, driven posts gone...",
      exits = {
        north = 1286,
        south = 393,
      },
      key = "stubbing.sled_way_the_green_gate",
      name = "Sled Way, the Green Gate",
      num = 1285,
      terrain = "city",
    },
    pkg = "Room.Info",
    seq = 217,
    t = 1791288402853,
  },
  {
    data = {
      area = "Stubbing",
      holds = {},
      region = "the Overgrowth",
      rooms = {
        ["1248"] = {
          exits = {
            out = "1261",
          },
          terrain = "inside",
          x = -5,
          y = 0,
          z = 0,
        },
        ["1249"] = {
          exits = {
            east = "1253",
            north = "1251",
            northeast = "1250",
            northwest = "1252",
            south = "1284",
            west = "1254",
          },
          terrain = "city",
          x = 0,
          y = 0,
          z = 0,
        },
        ["1250"] = {
          exits = {
            north = "1273",
            south = "1253",
            southwest = "1249",
            west = "1251",
          },
          terrain = "city",
          x = 1,
          y = 1,
          z = 0,
        },
        ["1251"] = {
          exits = {
            east = "1250",
            south = "1249",
            southeast = "1253",
            southwest = "1254",
            west = "1252",
          },
          terrain = "city",
          x = 0,
          y = 1,
          z = 0,
        },
        ["1252"] = {
          exits = {
            east = "1251",
            linehouse = "1266",
            north = "1269",
            south = "1254",
            southeast = "1249",
          },
          terrain = "city",
          x = -1,
          y = 1,
          z = 0,
        },
        ["1253"] = {
          exits = {
            east = "1256",
            north = "1250",
            northwest = "1251",
            south = "1283",
            west = "1249",
          },
          terrain = "city",
          x = 1,
          y = 0,
          z = 0,
        },
        ["1254"] = {
          exits = {
            east = "1249",
            north = "1252",
            northeast = "1251",
            west = "1262",
          },
          terrain = "city",
          x = -1,
          y = 0,
          z = 0,
        },
        ["1255"] = {
          exits = {
            glassworks = "1260",
            southeast = "1257",
            west = "1256",
          },
          terrain = "city",
          x = 3,
          y = 0,
          z = 0,
        },
        ["1256"] = {
          exits = {
            east = "1255",
            smithy = "1287",
            west = "1253",
          },
          terrain = "city",
          x = 2,
          y = 0,
          z = 0,
        },
        ["1257"] = {
          exits = {
            east = "1258",
            northwest = "1255",
          },
          terrain = "city",
          x = 4,
          y = -1,
          z = 0,
        },
        ["1258"] = {
          exits = {
            west = "1257",
          },
          leaves = {
            "east",
          },
          terrain = "city",
          x = 5,
          y = -1,
          z = 0,
        },
        ["1259"] = {
          exits = {
            down = "1275",
          },
          terrain = "inside",
          x = 2,
          y = 6,
          z = 1,
        },
        ["1260"] = {
          exits = {
            out = "1255",
          },
          terrain = "inside",
          x = 3,
          y = -1,
          z = 0,
        },
        ["1261"] = {
          exits = {
            barkhouse = "1248",
            east = "1265",
            west = "1264",
          },
          terrain = "city",
          x = -5,
          y = 1,
          z = 0,
        },
        ["1262"] = {
          exits = {
            east = "1254",
            stillroom = "1289",
            west = "1263",
          },
          terrain = "city",
          x = -2,
          y = 0,
          z = 0,
        },
        ["1263"] = {
          exits = {
            east = "1262",
            northwest = "1265",
            vathouse = "1290",
          },
          terrain = "city",
          x = -3,
          y = 0,
          z = 0,
        },
        ["1264"] = {
          exits = {
            east = "1261",
          },
          leaves = {
            "west",
          },
          terrain = "city",
          x = -6,
          y = 1,
          z = 0,
        },
        ["1265"] = {
          exits = {
            southeast = "1263",
            west = "1261",
          },
          terrain = "city",
          x = -4,
          y = 1,
          z = 0,
        },
        ["1266"] = {
          exits = {
            out = "1252",
            up = "1267",
          },
          terrain = "inside",
          x = -2,
          y = 1,
          z = 0,
        },
        ["1267"] = {
          exits = {
            down = "1266",
          },
          terrain = "inside",
          x = -2,
          y = 1,
          z = 1,
        },
        ["1268"] = {
          exits = {
            lodginghouse = "1270",
            south = "1269",
          },
          terrain = "city",
          x = -1,
          y = 3,
          z = 0,
        },
        ["1269"] = {
          exits = {
            north = "1268",
            south = "1252",
          },
          terrain = "city",
          x = -1,
          y = 2,
          z = 0,
        },
        ["1270"] = {
          exits = {
            out = "1268",
            up = "1271",
          },
          terrain = "inside",
          x = -2,
          y = 3,
          z = 0,
        },
        ["1271"] = {
          exits = {
            down = "1270",
          },
          terrain = "inside",
          x = -2,
          y = 3,
          z = 1,
        },
        ["1272"] = {
          exits = {
            north = "1275",
            south = "1276",
          },
          leaves = {
            "fellingring",
          },
          terrain = "city",
          x = 2,
          y = 5,
          z = 0,
        },
        ["1273"] = {
          exits = {
            north = "1274",
            sawpit = "1282",
            south = "1250",
          },
          terrain = "city",
          x = 1,
          y = 2,
          z = 0,
        },
        ["1274"] = {
          exits = {
            northeast = "1276",
            south = "1273",
            staveshed = "1288",
          },
          terrain = "city",
          x = 1,
          y = 3,
          z = 0,
        },
        ["1275"] = {
          exits = {
            south = "1272",
            up = "1259",
          },
          leaves = {
            "north",
          },
          terrain = "city",
          x = 2,
          y = 6,
          z = 0,
        },
        ["1276"] = {
          exits = {
            east = "1280",
            north = "1272",
            southwest = "1274",
          },
          terrain = "city",
          x = 2,
          y = 4,
          z = 0,
        },
        ["1277"] = {
          exits = {
            out = "1284",
          },
          terrain = "inside",
          x = -1,
          y = -1,
          z = 0,
        },
        ["1278"] = {
          exits = {
            east = "1286",
            west = "1279",
          },
          terrain = "city",
          x = -1,
          y = -2,
          z = 0,
        },
        ["1279"] = {
          exits = {
            east = "1278",
          },
          terrain = "city",
          x = -2,
          y = -2,
          z = 0,
        },
        ["1280"] = {
          exits = {
            east = "1281",
            west = "1276",
          },
          terrain = "city",
          x = 3,
          y = 4,
          z = 0,
        },
        ["1281"] = {
          exits = {
            west = "1280",
          },
          terrain = "city",
          x = 4,
          y = 4,
          z = 0,
        },
        ["1282"] = {
          exits = {
            out = "1273",
          },
          terrain = "inside",
          x = 2,
          y = 2,
          z = 0,
        },
        ["1283"] = {
          exits = {
            north = "1253",
          },
          leaves = {
            "canopyloft",
          },
          terrain = "city",
          x = 1,
          y = -1,
          z = 0,
        },
        ["1284"] = {
          exits = {
            markethall = "1277",
            north = "1249",
            south = "1286",
          },
          terrain = "city",
          x = 0,
          y = -1,
          z = 0,
        },
        ["1285"] = {
          exits = {
            north = "1286",
          },
          leaves = {
            "south",
          },
          terrain = "city",
          x = 0,
          y = -3,
          z = 0,
        },
        ["1286"] = {
          exits = {
            north = "1284",
            south = "1285",
            west = "1278",
          },
          terrain = "city",
          x = 0,
          y = -2,
          z = 0,
        },
        ["1287"] = {
          exits = {
            out = "1256",
          },
          terrain = "inside",
          x = 2,
          y = 1,
          z = 0,
        },
        ["1288"] = {
          exits = {
            out = "1274",
          },
          terrain = "inside",
          x = 2,
          y = 3,
          z = 0,
        },
        ["1289"] = {
          exits = {
            out = "1262",
          },
          terrain = "inside",
          x = -2,
          y = -1,
          z = 0,
        },
        ["1290"] = {
          exits = {
            out = "1263",
          },
          terrain = "inside",
          x = -3,
          y = -1,
          z = 0,
        },
      },
    },
    pkg = "Area.Map",
    seq = 218,
    t = 1791288402854,
  },
  {
    data = {
      here = "1285",
      members = {},
    },
    pkg = "Area.Where",
    seq = 219,
    t = 1791288402854,
  },
}
