-- SYNTHETIC, hand-written 2026-10-18 for wayfinder #29 (see plane_synthetic_town_rooms).
-- The Lees Depths captured the same day carry names but no room key yet.
-- Area.Map. A Delve copy after entering two Rooms: "stepping into any part explores every
-- part, their cells and their exits"; "the entered part takes the first map number, the
-- others follow ... the Room id is the lowest and fixed". d1-d3 are "the long hall" (room
-- "d1"), entered at d1; d4 "the niche" was entered from d2. "A Delve names only the Rooms
-- the party has entered"; no leads, no Wards, empty holds. d3 east and d2 south are
-- unexplored; d1's stair up is in leaves, as on a Depth.
return {
  area = "the Lees, Depth 3",
  holds = {},
  names = {
    d1 = "the long hall",
    d4 = "the niche",
  },
  rooms = {
    d1 = {
      exits = {
        east = "d2",
      },
      leaves = {
        "up",
      },
      room = "d1",
      x = 0,
      y = 0,
      z = 0,
    },
    d2 = {
      exits = {
        east = "d3",
        north = "d4",
        west = "d1",
      },
      room = "d1",
      unexplored = {
        "south",
      },
      x = 1,
      y = 0,
      z = 0,
    },
    d3 = {
      exits = {
        west = "d2",
      },
      room = "d1",
      unexplored = {
        "east",
      },
      x = 2,
      y = 0,
      z = 0,
    },
    d4 = {
      exits = {
        south = "d2",
      },
      x = 1,
      y = 1,
      z = 0,
    },
  },
}
