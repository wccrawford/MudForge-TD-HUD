# PROTOTYPE: Rooms, Ward shading and labels (wayfinder #31)

Throwaway. Three variants of look A "Tiles" with Rooms, names, Wards and Leads, at the
fixed 34 px zoom of Following, drawn from the fixtures (synthetic where no World sends
the keys yet). `rooms.lua` is a copy of lib/map.lua's drawing with the variants;
lib/map.lua keeps the state. Each preview window is a real page: drag, wheel, -/+, centre.

    luajit prototype/map-rooms/gen.lua && python -m http.server 8031
    # http://localhost:8031/prototype/map-rooms/preview.html?variant=A  (A|B|C, or the bar / arrow keys)

Each plane's notes say what was labelled, what was dropped, and, on a plane with no
room/ward, whether its drawing is v0.6.0's (lib/map.lua) apart from tooltips.
