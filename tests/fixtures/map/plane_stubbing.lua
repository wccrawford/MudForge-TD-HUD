-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Area.Map. Town, two levels (z 0 and 1), leaves, no doors in the package.
return {
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
}
