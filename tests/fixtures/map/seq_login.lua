-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). Log in: the full push, then a second Room.Info/Area.Map/Area.Where from the look.
return {
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
    seq = 98,
    t = 1791288328162,
  },
  {
    data = {
      effects = {},
      now_ms = 655501411,
    },
    pkg = "Char.Effects",
    seq = 99,
    t = 1791288328163,
  },
  {
    data = {
      slots = {
        {
          instance = 14585708937216,
          item = "a good skink rawhide cap",
          slot = "Head",
        },
        {
          instance = 14590003904512,
          item = "a fine skink rawhide cuirass",
          slot = "Body",
        },
        {
          instance = 14602888806400,
          item = "superb lamprey rawhide greaves",
          slot = "Legs",
        },
        {
          instance = 14594298871808,
          item = "fine skink rawhide boots",
          slot = "Feet",
        },
        {
          instance = 14598593839104,
          item = "good skink rawhide gauntlets",
          slot = "Hands",
        },
        {
          instance = 14542759264256,
          item = "a gildwood long blade",
          slot = "Hand 1",
        },
        {
          instance = 14538464296960,
          item = "a flaying knife",
          slot = "Hand 2",
        },
        {
          instance = nil,
          item = nil,
          slot = "Waist 1",
        },
        {
          instance = nil,
          item = nil,
          slot = "Waist 2",
        },
        {
          instance = nil,
          item = nil,
          slot = "Waist 3",
        },
        {
          instance = nil,
          item = nil,
          slot = "Waist 4",
        },
        {
          instance = 14572824035328,
          item = "a padded bottler's satchel",
          slot = "Shoulder 1",
        },
        {
          instance = 14547054231552,
          item = "a long case",
          slot = "Shoulder 2",
        },
        {
          instance = nil,
          item = nil,
          slot = "Back",
        },
        {
          instance = nil,
          item = nil,
          slot = "Neck",
        },
        {
          instance = nil,
          item = nil,
          slot = "Finger 1",
        },
        {
          instance = nil,
          item = nil,
          slot = "Finger 2",
        },
        {
          instance = nil,
          item = nil,
          slot = "Ear 1",
        },
        {
          instance = nil,
          item = nil,
          slot = "Ear 2",
        },
      },
    },
    pkg = "Char.Items",
    seq = 100,
    t = 1791288328163,
  },
  {
    data = {
      clears_at_ms = 0,
      now_ms = 655501411,
    },
    pkg = "Char.RoundTime",
    seq = 101,
    t = 1791288328163,
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
    seq = 102,
    t = 1791288328164,
  },
  {
    data = {},
    pkg = "Char.Group",
    seq = 103,
    t = 1791288328180,
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
    seq = 104,
    t = 1791288328180,
  },
  {
    data = {
      here = "1285",
      members = {},
    },
    pkg = "Area.Where",
    seq = 105,
    t = 1791288328180,
  },
  {
    data = {
      client = "MudForge",
      minClientVersion = "1.2.2490",
      name = "TextDungeon HUD",
      sha256 = "c24aa2943df27ba7ca9ed14cae71052111cc9eea45e7d7385fd10a075b7e1433",
      url = "https://arrs.shire-justice.ts.net:4443/client-packages/textdungeon-hud-0.3.1.mfp",
      version = "0.3.1",
    },
    pkg = "Client.Package",
    seq = 106,
    t = 1791288328180,
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
    seq = 121,
    t = 1791288328190,
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
    seq = 122,
    t = 1791288328190,
  },
  {
    data = {
      here = "1285",
      members = {},
    },
    pkg = "Area.Where",
    seq = 123,
    t = 1791288328190,
  },
}
