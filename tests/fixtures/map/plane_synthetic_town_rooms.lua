-- SYNTHETIC, hand-written 2026-10-18 for wayfinder #29: no World on arrs:4000 declares
-- Rooms or Wards yet. Shaped from TextDungeonC docs/map-client-handoff.md, "Rooms, names
-- and Wards" (server 0.20.0); each case cites the line it stands for.
-- Area.Map. A Settlement in three Wards:
--   412-414  "the avenue", a 1x3 Room (room "412"): a Room is a rectangle of whole Locations
--   420-423  "the market square", a 2x2 Room whose id is NOT its lowest part (room "422"):
--            "The id is opaque: the map id of one of the Room's parts ... Do not parse it."
--            Exits run between its parts; none is drawn as a line ("no lines between its cells").
--   430-432  "the slant", a street's straight diagonal run (room "430"): its parts "do not
--            fill their bounding box ... Draw it as one band along the diagonal".
--   440      "the Hose Post", a leaf shop, its own Room (no room key): "A leaf's cell
--            carries the Ward of the street it opens off"; found "through names".
--   441/442  single-cell Rooms on two levels, a stair between them.
--   wards.rookery has no cells: "a dangerous Ward ... on the Settlement's map it is a row
--            in wards with no cells, reached through the door that names it" (432 south).
--   leads:   a Building by door noun (414 exchange), the gate to the next Area (414 north),
--            the dangerous Ward's Wilds (432 south).
return {
  area = "Brassmarket",
  holds = {},
  names = {
    ["412"] = "the avenue",
    ["422"] = "the market square",
    ["430"] = "the slant",
    ["440"] = "the Hose Post",
    ["441"] = "the Sump Steps",
    ["442"] = "the cistern",
  },
  region = "the Saffron Fall",
  rooms = {
    ["412"] = {
      exits = {
        east = "420",
        north = "413",
        southwest = "430",
      },
      room = "412",
      terrain = "city",
      ward = "drove_end",
      x = 3,
      y = 2,
      z = 0,
    },
    ["413"] = {
      doors = {
        east = {
          closed = false,
          name = "gate",
        },
      },
      exits = {
        east = "422",
        north = "414",
        south = "412",
      },
      room = "412",
      terrain = "city",
      ward = "drove_end",
      x = 3,
      y = 3,
      z = 0,
    },
    ["414"] = {
      exits = {
        south = "413",
      },
      leads = {
        exchange = "the Brass Exchange",
        north = "the Green Road",
      },
      leaves = {
        "exchange",
        "north",
      },
      room = "412",
      terrain = "city",
      ward = "drove_end",
      x = 3,
      y = 4,
      z = 0,
    },
    ["420"] = {
      exits = {
        east = "421",
        north = "422",
        west = "412",
      },
      room = "422",
      terrain = "city",
      ward = "drove_end",
      x = 4,
      y = 2,
      z = 0,
    },
    ["421"] = {
      exits = {
        north = "423",
        west = "420",
      },
      room = "422",
      terrain = "city",
      ward = "drove_end",
      x = 5,
      y = 2,
      z = 0,
    },
    ["422"] = {
      doors = {
        west = {
          closed = false,
          name = "gate",
        },
      },
      exits = {
        east = "423",
        south = "420",
        west = "413",
      },
      room = "422",
      terrain = "city",
      ward = "drove_end",
      x = 4,
      y = 3,
      z = 0,
    },
    ["423"] = {
      exits = {
        east = "440",
        south = "421",
        west = "422",
      },
      room = "422",
      terrain = "city",
      ward = "drove_end",
      x = 5,
      y = 3,
      z = 0,
    },
    ["430"] = {
      exits = {
        northeast = "412",
        southwest = "431",
      },
      room = "430",
      terrain = "city",
      ward = "sumps",
      x = 2,
      y = 1,
      z = 0,
    },
    ["431"] = {
      exits = {
        northeast = "430",
        southwest = "432",
      },
      room = "430",
      terrain = "city",
      ward = "sumps",
      x = 1,
      y = 0,
      z = 0,
    },
    ["432"] = {
      exits = {
        northeast = "431",
        west = "441",
      },
      leads = {
        south = "the Rookery",
      },
      leaves = {
        "south",
      },
      room = "430",
      terrain = "city",
      ward = "sumps",
      x = 0,
      y = -1,
      z = 0,
    },
    ["440"] = {
      exits = {
        west = "423",
      },
      terrain = "inside",
      ward = "drove_end",
      x = 6,
      y = 3,
      z = 0,
    },
    ["441"] = {
      exits = {
        down = "442",
        east = "432",
      },
      terrain = "city",
      ward = "sumps",
      x = -1,
      y = -1,
      z = 0,
    },
    ["442"] = {
      exits = {
        up = "441",
      },
      terrain = "cave",
      ward = "sumps",
      x = -1,
      y = -1,
      z = -1,
    },
  },
  wards = {
    drove_end = "Drove End",
    rookery = "the Rookery",
    sumps = "the Sumps",
  },
}
