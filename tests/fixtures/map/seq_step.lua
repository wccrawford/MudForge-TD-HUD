-- Captured from arrs:4000 (world prism) on 2026-10-06 by tools/mapcap.lua, wayfinder #19.
-- Packages in arrival order (seq, t ms). Steps inside one Area: Char.RoundTime, Room.Info, Area.Where; no Area.Map.
return {
  {
    data = {
      clears_at_ms = 655576706,
      now_ms = 655576440,
    },
    pkg = "Char.RoundTime",
    seq = 231,
    t = 1791288403242,
  },
  {
    data = {
      area = "Stubbing",
      contents = {},
      desc = "Two houses face each other across the ruts, their sills scra...",
      exits = {
        north = 1284,
        south = 1285,
        west = 1278,
      },
      key = "stubbing.sled_way_the_two_rutted_houses",
      name = "Sled Way, the two rutted houses",
      num = 1286,
      terrain = "city",
    },
    pkg = "Room.Info",
    seq = 232,
    t = 1791288403242,
  },
  {
    data = {
      here = "1286",
      members = {},
    },
    pkg = "Area.Where",
    seq = 233,
    t = 1791288403244,
  },
}
