-- SYNTHETIC, hand-written 2026-10-18 for wayfinder #29 (see plane_synthetic_town_rooms).
-- Area.Map. The Rookery, the dangerous Ward of Brassmarket as its own Wilds Area: "A
-- dangerous Ward is its own Wilds Area with its own map, every cell of which carries that
-- Ward". One 2x1 Room (room "601"), two single-cell Rooms, and a lead back to the Settlement.
return {
  area = "the Rookery",
  holds = {
    enemies = {
      "gutter rook",
    },
  },
  names = {
    ["601"] = "the roost yard",
    ["603"] = "the tar lane",
    ["604"] = "the tumbled loft",
  },
  region = "the Saffron Fall",
  rooms = {
    ["601"] = {
      exits = {
        east = "602",
        south = "603",
      },
      leads = {
        north = "Brassmarket",
      },
      leaves = {
        "north",
      },
      room = "601",
      terrain = "city",
      ward = "rookery",
      x = 0,
      y = 0,
      z = 0,
    },
    ["602"] = {
      exits = {
        west = "601",
      },
      room = "601",
      terrain = "city",
      ward = "rookery",
      x = 1,
      y = 0,
      z = 0,
    },
    ["603"] = {
      exits = {
        north = "601",
        southeast = "604",
      },
      terrain = "road",
      ward = "rookery",
      x = 0,
      y = -1,
      z = 0,
    },
    ["604"] = {
      exits = {
        northwest = "603",
      },
      terrain = "inside",
      ward = "rookery",
      x = 1,
      y = -2,
      z = 0,
    },
  },
  wards = {
    rookery = "the Rookery",
  },
}
