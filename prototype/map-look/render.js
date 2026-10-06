// PROTOTYPE — throwaway (wayfinder ticket "What the Map looks like", map #17).
// Three structurally different looks for the Map window, drawn from one Area.Map
// + Area.Where as an HTML string (header, SVG plane, holds, reason). The real
// window will draw this from the Lua lib (ticket "How the Map window redraws");
// this is JS only so the looks can be flipped in a browser and in MudForge.
//
//   MapLook.render(variant, view) -> html
//   view = { hud: 'live'|'unfed'|'severed', map, where: {here, members},
//            level (z shown, or null = the player's), reason: null|'nomap'|'nocells'|'offplane' }
(function (root) {
  var U = 20; // one cell in SVG units; Fit scales the viewBox, so this is only proportion

  var DIRS = {
    north: [0, 1], south: [0, -1], east: [1, 0], west: [-1, 0],
    northeast: [1, 1], northwest: [-1, 1], southeast: [1, -1], southwest: [-1, -1],
  };

  var TERRAIN = {
    inside: '#7d8590', city: '#a371f7', road: '#c2a878', field: '#6cae4f', forest: '#2e8b57',
    water: '#3b82c4', swamp: '#808c2e', cave: '#9a6b4f', hills: '#d29b45',
  };
  var NONE = '#3d444d';
  var YOU = '#ffd33d', GROUP = '#ff7b72', BACK = '#39c5cf', LINE = '#8b949e';

  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function keys(o) { return o ? Object.keys(o) : []; }

  // ---- the model every look reads ------------------------------------------------

  function levels(map) {
    var zs = {};
    keys(map.rooms).forEach(function (id) { zs[map.rooms[id].z] = true; });
    return keys(zs).map(Number).sort(function (a, b) { return a - b; });
  }

  // Level shown: the browsed one, else the player's, else 0, else the lowest (CONTEXT.md).
  function shownLevel(view) {
    var map = view.map, zs = levels(map);
    if (view.level != null && zs.indexOf(view.level) >= 0) return view.level;
    var here = view.where && view.where.here && map.rooms[view.where.here];
    if (here) return here.z;
    return zs.indexOf(0) >= 0 ? 0 : zs[0];
  }

  // Fit frames the whole Plane's x/y bounds (all levels), so the frame doesn't jump between levels.
  function bounds(map) {
    var b = { x0: Infinity, x1: -Infinity, y0: Infinity, y1: -Infinity };
    keys(map.rooms).forEach(function (id) {
      var r = map.rooms[id];
      b.x0 = Math.min(b.x0, r.x); b.x1 = Math.max(b.x1, r.x);
      b.y0 = Math.min(b.y0, r.y); b.y1 = Math.max(b.y1, r.y);
    });
    return b;
  }

  function px(r) { return r.x * U; }
  function py(r) { return -r.y * U; } // north is +y; SVG y grows down

  // Everything one level needs, worked out once: rooms, edges (paired), stubs, marks.
  function scene(view) {
    var map = view.map, z = shownLevel(view), rooms = [], edges = [], stubs = [], seen = {};
    keys(map.rooms).forEach(function (id) {
      var r = map.rooms[id];
      if (r.z !== z) return;
      var doors = r.doors || {}, up = false, down = false, odd = [];
      keys(r.exits).forEach(function (w) {
        var t = map.rooms[r.exits[w]];
        if (!t) return;
        if (t.z !== r.z) { if (t.z > r.z) up = true; else down = true; return; }
        var k = id < r.exits[w] ? id + '|' + r.exits[w] : r.exits[w] + '|' + id;
        var door = doors[w] || null;
        if (seen[k]) { if (door && !seen[k].door) seen[k].door = door; return; }
        seen[k] = { a: r, b: t, word: w, door: door, diag: t.x !== r.x && t.y !== r.y, far: Math.max(Math.abs(t.x - r.x), Math.abs(t.y - r.y)) > 1 };
        edges.push(seen[k]);
      });
      (r.leaves || []).forEach(function (w) {
        if (w === 'up') { up = up || 'leaves'; return; }
        if (w === 'down') { down = down || 'leaves'; return; }
        if (DIRS[w]) stubs.push({ r: r, word: w, kind: 'leaves', door: doors[w] || null });
        else odd.push({ word: w, kind: 'leaves', door: doors[w] || null });
      });
      (r.unexplored || []).forEach(function (w) {
        if (w === 'up') { up = up || 'unexplored'; return; }
        if (w === 'down') { down = down || 'unexplored'; return; }
        if (DIRS[w]) stubs.push({ r: r, word: w, kind: 'unexplored', door: doors[w] || null });
        else odd.push({ word: w, kind: 'unexplored' });
      });
      if (r.back) {
        if (DIRS[r.back]) stubs.push({ r: r, word: r.back, kind: 'back', door: doors[r.back] || null });
        else odd.push({ word: r.back, kind: 'back' });
      }
      rooms.push({ id: id, r: r, up: up, down: down, odd: odd });
    });
    var where = view.where || {}, members = [];
    keys(where.members).forEach(function (name) {
      var t = map.rooms[where.members[name]];
      if (t) members.push({ name: name, id: where.members[name], r: t, here: t.z === z });
    });
    var you = where.here && map.rooms[where.here];
    return {
      z: z, zs: levels(map), b: bounds(map), rooms: rooms, edges: edges, stubs: stubs,
      you: you && you.z === z ? you : null, youId: where.here, youLevel: you ? you.z : null,
      members: members,
    };
  }

  function tip(o) {
    var r = o.r, t = [r.terrain || 'no terrain'];
    if (o.up) t.push(o.up === true ? 'stairs up' : o.up === 'leaves' ? 'up leaves this map' : 'up, unexplored');
    if (o.down) t.push(o.down === true ? 'stairs down' : o.down === 'leaves' ? 'down leaves this map' : 'down, unexplored');
    keys(r.doors).forEach(function (w) { t.push(w + ': ' + r.doors[w].name + (r.doors[w].closed ? ' (closed)' : ' (open)')); });
    o.odd.forEach(function (x) { t.push(x.word + (x.kind === 'leaves' ? ' leaves this map' : x.kind === 'back' ? ' leads back out' : ', unexplored')); });
    if (r.back) t.push(r.back + ' leads back out');
    return t.join('\n');
  }

  // viewBox around the whole Plane plus room for stubs; the cell-size cap rides on max-width/height.
  function frame(s, pad, capPx) {
    var b = s.b, x = b.x0 * U - pad, y = -b.y1 * U - pad;
    var w = (b.x1 - b.x0) * U + 2 * pad, h = (b.y1 - b.y0) * U + 2 * pad;
    return '<svg class="plane" viewBox="' + x + ' ' + y + ' ' + w + ' ' + h + '" preserveAspectRatio="xMidYMid meet" ' +
      'style="max-width:' + (w / U * capPx) + 'px;max-height:' + (h / U * capPx) + 'px">';
  }

  function levelText(s) {
    if (s.zs.length < 2) return '';
    return 'Level ' + (s.zs.indexOf(s.z) + 1) + ' of ' + s.zs.length;
  }

  function reasonText(view) {
    var a = view.map && view.map.area;
    if (view.reason === 'nomap') return 'No map from the server yet. If <code>config map</code> is off, <code>config map on</code> brings it back.';
    if (view.reason === 'nocells') return esc(a || 'This Area') + ' has no map.';
    if (view.reason === 'offplane') return 'You are not on the map of ' + esc(a || 'this Area') + '.';
    return '';
  }

  function holdsList(map) {
    var h = map.holds || {}, out = [];
    if (h.enemies && h.enemies.length) out.push({ k: 'Enemies', v: h.enemies });
    if (h.gather && h.gather.length) out.push({ k: 'Gather', v: h.gather });
    return out;
  }

  function off(w, d) { var v = DIRS[w]; return [v[0] * d, -v[1] * d]; }

  // ===============================================================================
  // A — Tiles: terrain-filled squares with gaps, short bridges between them,
  // terrain also told by a fill pattern; header bar on top, holds as a footer.
  // ===============================================================================

  // Tile-local textures: every tile is drawn inside its own translate(), so a
  // userSpaceOnUse pattern starts at the tile's corner and lines up across tiles.
  // The tile is 12 units and each pattern 6, so every tile shows the same 2x2.
  var INK = 'stroke="#000" stroke-opacity=".38"', INKF = 'fill="#000" fill-opacity=".38"';
  var PAT = {
    city: '<path d="M0 .5h6M0 3.5h6M1.5 .5v3M4.5 3.5v3" fill="none" ' + INK + ' stroke-width=".8"/>',
    road: '<path d="M.5 3h2.4M3.5 3h2" fill="none" ' + INK + ' stroke-width="1.1"/>',
    field: '<circle cx="3" cy="3" r=".95" ' + INKF + '/>',
    forest: '<path d="M3 .8l2.2 3.8H.8z" ' + INKF + '/>',
    water: '<path d="M0 3q1.5-2 3 0t3 0" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width=".9"/>',
    swamp: '<path d="M0 4.5q1.5-1.5 3 0t3 0M1.5 .8v2M4.5 1.2v1.6" fill="none" ' + INK + ' stroke-width=".85"/>',
    cave: '<path d="M1 2.2h1.6M3.6 4.6h1.6M.4 5.4h.8M4.2 1h1" fill="none" ' + INK + ' stroke-width="1.3" stroke-linecap="round"/>',
    hills: '<path d="M.3 4.8q2.7-4.2 5.4 0" fill="none" ' + INK + ' stroke-width=".9"/>',
  };
  // One centred motif per tile instead (variant D), drawn in the same 12-unit tile space.
  var MOTIF = {
    inside: '<rect x="2.5" y="2.5" width="7" height="7" rx="1" fill="none" ' + INK + ' stroke-width="1.1"/>',
    city: '<path d="M3 10V5.5L6 2.5L9 5.5V10z" fill="none" ' + INK + ' stroke-width="1.1"/>',
    road: '<path d="M2 4.5h8M2 7.5h8" fill="none" ' + INK + ' stroke-width="1.1"/>',
    field: '<path d="M3 9l1-3.5M6 9V4.5M9 9l-1-3.5" fill="none" ' + INK + ' stroke-width="1.1" stroke-linecap="round"/>',
    forest: '<path d="M6 2l3.4 5.6H2.6z" ' + INKF + '/><path d="M6 7.6V10" ' + INK + ' stroke-width="1.2"/>',
    water: '<path d="M1.5 4.5q1.5-2 3 0t3 0t3 0M1.5 8q1.5-2 3 0t3 0t3 0" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="1"/>',
    swamp: '<path d="M1.5 8.5q1.5-1.6 3 0t3 0t3 0M4 6.5V3M6 6.5V2.2M8 6.5V3.4" fill="none" ' + INK + ' stroke-width="1"/>',
    cave: '<path d="M2.5 10V6.5a3.5 3.5 0 0 1 7 0V10" fill="none" ' + INK + ' stroke-width="1.2"/>',
    hills: '<path d="M1 9q2.5-5 5 0M5 9q2.5-5 5 0" fill="none" ' + INK + ' stroke-width="1"/>',
  };

  function variantA(view, s, motif) {
    var T = 12, h = T / 2, g = '', EDGE = 2.6;
    var defs = '<defs>' + (motif ? '' : keys(PAT).map(function (t) {
      return '<pattern id="pA-' + t + '" width="6" height="6" patternUnits="userSpaceOnUse">' + PAT[t] + '</pattern>';
    }).join('')) +
      '<marker id="aA" viewBox="0 0 6 6" refX="2" refY="3" markerWidth="6" markerHeight="6" markerUnits="userSpaceOnUse" orient="auto"><path d="M0 0L6 3L0 6z" fill="' + LINE + '"/></marker>' +
      '<marker id="aB" viewBox="0 0 6 6" refX="2" refY="3" markerWidth="6" markerHeight="6" markerUnits="userSpaceOnUse" orient="auto"><path d="M0 0L6 3L0 6z" fill="' + BACK + '"/></marker></defs>';

    s.edges.forEach(function (e) {
      g += '<line x1="' + px(e.a) + '" y1="' + py(e.a) + '" x2="' + px(e.b) + '" y2="' + py(e.b) + '" stroke="' + LINE + '" stroke-width="' + EDGE + '"' + (e.far ? ' stroke-dasharray="3 2"' : '') + '/>';
    });
    s.stubs.forEach(function (st) {
      var o0 = off(st.word, h), o1 = off(st.word, U * 0.6), x = px(st.r), y = py(st.r);
      var col = st.kind === 'back' ? BACK : LINE;
      var dash = st.kind === 'unexplored' ? ' stroke-dasharray="2 1.6"' : '';
      var end = st.kind === 'unexplored' ? '' : ' marker-end="url(#' + (st.kind === 'back' ? 'aB' : 'aA') + ')"';
      g += '<line x1="' + (x + o0[0]) + '" y1="' + (y + o0[1]) + '" x2="' + (x + o1[0]) + '" y2="' + (y + o1[1]) + '" stroke="' + col + '" stroke-width="' + EDGE + '"' + dash + end + '/>';
      if (st.kind === 'unexplored') {
        var q = off(st.word, U * 0.6 + 3);
        g += '<circle cx="' + (x + q[0]) + '" cy="' + (y + q[1]) + '" r="3.4" fill="#0d1117" stroke="#e6edf3" stroke-width="1"/>' +
          '<text x="' + (x + q[0]) + '" y="' + (y + q[1] + 2) + '" font-size="5.4" font-weight="700" text-anchor="middle" fill="#e6edf3">?</text>';
      }
    });
    var badges = '';
    s.rooms.forEach(function (o) {
      var r = o.r, x = px(r) - h, y = py(r) - h, col = TERRAIN[r.terrain] || NONE;
      g += '<g data-id="' + esc(o.id) + '" transform="translate(' + x + ' ' + y + ')"><title>' + esc(tip(o)) + '</title>' +
        '<rect width="' + T + '" height="' + T + '" rx="2" fill="' + col + '"' + (r.terrain ? '' : ' stroke="#6e7681" stroke-width=".8"') + '/>';
      if (motif) g += MOTIF[r.terrain] || '';
      else if (r.terrain === 'inside') g += MOTIF.inside; // a room-in-a-room frame; no texture
      else if (PAT[r.terrain]) g += '<rect width="' + T + '" height="' + T + '" rx="2" fill="url(#pA-' + r.terrain + ')"/>';
      g += '</g>';
      // badges sit on the tile's corners, half outside it, drawn over everything else
      var cx = x + T, sd = 'stroke="#0d1117" stroke-width="1.2" stroke-linejoin="round"';
      function tri(cy, dir, how) {
        var d = 'M' + (cx - 3.6) + ' ' + (cy + 2.6 * dir) + 'L' + cx + ' ' + (cy - 3 * dir) + 'L' + (cx + 3.6) + ' ' + (cy + 2.6 * dir) + 'z';
        if (how === true) return '<path d="' + d + '" fill="#fff" ' + sd + '/>';
        // a stair that leaves this map (a Depth) or isn't explored: hollow, on a dark ground
        return '<path d="' + d + '" fill="#0d1117" stroke="#fff" stroke-width="1.2" stroke-linejoin="round"' + (how === 'unexplored' ? ' stroke-dasharray="1.6 1"' : '') + '/>';
      }
      if (o.up) badges += tri(y + 1.5, 1, o.up);
      if (o.down) badges += tri(y + T - 1.5, -1, o.down);
      if (o.odd.length) {
        var bk = o.odd.some(function (q) { return q.kind === 'back'; });
        badges += '<g><title>' + esc(o.odd.map(function (q) { return q.word; }).join(', ')) + '</title><circle cx="' + x + '" cy="' + y + '" r="3.6" fill="' + (bk ? BACK : '#fff') + '" ' + sd + '/>' +
          '<path d="M' + (x - 1.5) + ' ' + (y + 1.5) + 'L' + (x + 1.6) + ' ' + (y - 1.6) + 'M' + (x - .6) + ' ' + (y - 1.6) + 'H' + (x + 1.6) + 'V' + (y + .6) + '" fill="none" stroke="#0d1117" stroke-width="1"/></g>';
      }
    });
    // doors: a bar across the line (closed = solid across, open = two jambs)
    s.edges.concat(s.stubs).forEach(function (e) {
      if (!e.door) return;
      var a = e.a || e.r, v = DIRS[e.word] || [Math.sign(e.b.x - a.x), Math.sign(e.b.y - a.y)];
      var mx = px(a) + v[0] * U / 2, my = py(a) - v[1] * U / 2, n = Math.hypot(v[0], v[1]), nx = -v[1] / n, ny = -v[0] / n;
      var L = 4.8;
      if (e.door.closed) g += '<line x1="' + (mx - nx * L) + '" y1="' + (my - ny * L) + '" x2="' + (mx + nx * L) + '" y2="' + (my + ny * L) + '" stroke="#f0883e" stroke-width="3"><title>' + esc(e.door.name) + ' (closed)</title></line>';
      else g += '<g stroke="#f0883e" stroke-width="2.2"><title>' + esc(e.door.name) + ' (open)</title><line x1="' + (mx - nx * L) + '" y1="' + (my - ny * L) + '" x2="' + (mx - nx * 2.2) + '" y2="' + (my - ny * 2.2) + '"/><line x1="' + (mx + nx * 2.2) + '" y1="' + (my + ny * 2.2) + '" x2="' + (mx + nx * L) + '" y2="' + (my + ny * L) + '"/></g>';
    });
    s.members.forEach(function (m, i) {
      if (!m.here) return;
      var x = px(m.r) - h + i * 6, y = py(m.r) + h;
      g += '<g><title>' + esc(m.name) + '</title><circle cx="' + x + '" cy="' + y + '" r="4" fill="' + GROUP + '" stroke="#0d1117" stroke-width="1.2"/>' +
        '<text x="' + x + '" y="' + (y + 1.9) + '" font-size="5.4" text-anchor="middle" fill="#0d1117" font-weight="700">' + esc(m.name[0]) + '</text></g>';
    });
    if (s.you) g += '<rect class="you" x="' + (px(s.you) - h - 2.6) + '" y="' + (py(s.you) - h - 2.6) + '" width="' + (T + 5.2) + '" height="' + (T + 5.2) + '" rx="3.5" fill="none" stroke="' + YOU + '" stroke-width="2.4"><title>You</title></rect>' +
      '<circle cx="' + px(s.you) + '" cy="' + py(s.you) + '" r="2.8" fill="' + YOU + '" stroke="#0d1117" stroke-width="1.2"/>';
    g += badges; // over the you ring, so it never hides a mark

    var lv = levelText(s), holds = holdsList(view.map), away = awayNote(s);
    return '<div class="A">' +
      '<div class="A-head"><div class="A-area">' + esc(view.map.area) + '</div>' +
      (view.map.region ? '<div class="A-region">' + esc(view.map.region) + '</div>' : '') +
      (lv ? '<div class="A-level">' + lv + '</div>' : '') + '</div>' +
      '<div class="A-body">' + frame(s, U * 0.9, 34) + defs + g + '</svg></div>' +
      (away ? '<div class="A-away">' + away + '</div>' : '') +
      (holds.length ? '<div class="A-holds">' + holds.map(function (x) { return '<div><b>' + x.k + '</b> ' + x.v.map(esc).join(', ') + '</div>'; }).join('') + '</div>' : '') +
      '</div>';
  }

  // Who is drawn on another level than the one shown (you while Browsing, members).
  function awayNote(s) {
    var t = [];
    if (s.youLevel != null && s.youLevel !== s.z) t.push('You: level ' + (s.zs.indexOf(s.youLevel) + 1));
    s.members.forEach(function (m) { if (!m.here) t.push(esc(m.name) + ': level ' + (s.zs.indexOf(m.r.z) + 1)); });
    return t.join(' · ');
  }

  // ===============================================================================
  // B — Nodes and lines: a transit diagram. Small nodes, terrain by colour AND
  // node shape, thick lines, stubs fade out; header is an overlay in the map's
  // corner, holds a side column (like the text verb's side column, not its glyphs).
  // ===============================================================================

  function shapeB(t, x, y, col) {
    var r = 4.2, p = ' fill="' + col + '" stroke="#0d1117" stroke-width="1.2"';
    switch (t) {
      case 'inside': case 'city': return '<rect x="' + (x - r) + '" y="' + (y - r) + '" width="' + 2 * r + '" height="' + 2 * r + '"' + p + '/>';
      case 'forest': case 'hills': return '<path d="M' + x + ' ' + (y - r - 1) + 'L' + (x + r + 1) + ' ' + (y + r) + 'H' + (x - r - 1) + 'z"' + p + '/>';
      case 'water': case 'swamp': return '<path d="M' + x + ' ' + (y - r - 1) + 'L' + (x + r + 1) + ' ' + y + 'L' + x + ' ' + (y + r + 1) + 'L' + (x - r - 1) + ' ' + y + 'z"' + p + '/>';
      case 'road': return '<rect x="' + (x - r - 1) + '" y="' + (y - r + 1.5) + '" width="' + (2 * r + 2) + '" height="' + (2 * r - 3) + '" rx="1.5"' + p + '/>';
      case 'cave': return '<path d="M' + (x - r) + ' ' + (y + r) + 'V' + y + 'a' + r + ' ' + r + ' 0 0 1 ' + 2 * r + ' 0V' + (y + r) + 'z"' + p + '/>';
      case undefined: return '<circle cx="' + x + '" cy="' + y + '" r="' + r + '" fill="#0d1117" stroke="#8b949e" stroke-width="1.2"/>';
      default: return '<circle cx="' + x + '" cy="' + y + '" r="' + r + '"' + p + '/>';
    }
  }

  function variantB(view, s) {
    var g = '', defs = '<defs><linearGradient id="fB" gradientUnits="objectBoundingBox"><stop offset="0" stop-color="' + LINE + '"/><stop offset="1" stop-color="' + LINE + '" stop-opacity="0"/></linearGradient></defs>';
    s.edges.forEach(function (e) {
      g += '<line x1="' + px(e.a) + '" y1="' + py(e.a) + '" x2="' + px(e.b) + '" y2="' + py(e.b) + '" stroke="#57606a" stroke-width="3" stroke-linecap="round"' + (e.far ? ' stroke-dasharray="3 3"' : '') + '/>';
    });
    s.stubs.forEach(function (st) {
      var x = px(st.r), y = py(st.r), o = off(st.word, U * 0.75);
      if (st.kind === 'unexplored') {
        g += '<line x1="' + x + '" y1="' + y + '" x2="' + (x + o[0]) + '" y2="' + (y + o[1]) + '" stroke="#57606a" stroke-width="2" stroke-dasharray="2 2.5"/>' +
          '<text x="' + (x + o[0]) + '" y="' + (y + o[1] + 2.6) + '" font-size="7.5" text-anchor="middle" fill="#8b949e" font-weight="700">?</text>';
      } else if (st.kind === 'back') {
        g += '<line x1="' + x + '" y1="' + y + '" x2="' + (x + o[0]) + '" y2="' + (y + o[1]) + '" stroke="' + BACK + '" stroke-width="3" stroke-linecap="round"/>' +
          '<circle cx="' + (x + o[0]) + '" cy="' + (y + o[1]) + '" r="2.4" fill="' + BACK + '"/>';
      } else {
        // a line that runs off and fades: the way goes on, the map doesn't
        var d = off(st.word, 1), sx = x + o[0], sy = y + o[1];
        g += '<path d="M' + x + ' ' + y + 'L' + sx + ' ' + sy + '" stroke="#57606a" stroke-width="3" stroke-linecap="butt"/>' +
          '<path d="M' + (sx + d[1] * 3) + ' ' + (sy - d[0] * 3) + 'L' + (sx + d[0] * 3) + ' ' + (sy + d[1] * 3) + 'L' + (sx - d[1] * 3) + ' ' + (sy + d[0] * 3) + '" fill="none" stroke="#8b949e" stroke-width="1.4"/>';
      }
    });
    s.edges.concat(s.stubs).forEach(function (e) {
      if (!e.door) return;
      var a = e.a || e.r, v = DIRS[e.word] || [Math.sign(e.b.x - a.x), Math.sign(e.b.y - a.y)];
      var mx = px(a) + v[0] * U / 2, my = py(a) - v[1] * U / 2;
      g += '<g><title>' + esc(e.door.name) + (e.door.closed ? ' (closed)' : ' (open)') + '</title>' +
        '<rect x="' + (mx - 3.4) + '" y="' + (my - 3.4) + '" width="6.8" height="6.8" transform="rotate(45 ' + mx + ' ' + my + ')" fill="' + (e.door.closed ? '#f0883e' : '#0d1117') + '" stroke="#f0883e" stroke-width="1.3"/></g>';
    });
    s.rooms.forEach(function (o) {
      var r = o.r, x = px(r), y = py(r);
      g += '<g data-id="' + esc(o.id) + '"><title>' + esc(tip(o)) + '</title>' + shapeB(r.terrain, x, y, TERRAIN[r.terrain] || NONE);
      var mark = (o.up ? '▲' : '') + (o.down ? '▼' : '');
      if (mark) g += '<text x="' + (x + 5.5) + '" y="' + (y - 4) + '" font-size="5.5" fill="#e6edf3"' + ((o.up && o.up !== true) || (o.down && o.down !== true) ? ' fill-opacity=".55"' : '') + '>' + mark + '</text>';
      if (o.odd.length) g += '<text x="' + (x - 5.5) + '" y="' + (y - 4) + '" font-size="6" text-anchor="end" fill="' + (o.odd.some(function (q) { return q.kind === 'back'; }) ? BACK : '#e6edf3') + '">↗</text>';
      g += '</g>';
    });
    s.members.forEach(function (m, i) {
      if (!m.here) return;
      var x = px(m.r), y = py(m.r) + 9 + i * 6;
      g += '<text x="' + x + '" y="' + y + '" font-size="5.5" text-anchor="middle" fill="' + GROUP + '" stroke="#0d1117" stroke-width="1.6" paint-order="stroke" font-weight="600">' + esc(m.name) + '</text>';
      g += '<circle cx="' + x + '" cy="' + py(m.r) + '" r="6.6" fill="none" stroke="' + GROUP + '" stroke-width="1.3"/>';
    });
    if (s.you) g += '<circle cx="' + px(s.you) + '" cy="' + py(s.you) + '" r="8.4" fill="' + YOU + '" fill-opacity=".18" stroke="' + YOU + '" stroke-width="2"><title>You</title></circle>';

    var lv = levelText(s), holds = holdsList(view.map), away = awayNote(s);
    return '<div class="B">' +
      '<div class="B-map">' + frame(s, U * 0.95, 30) + defs + g + '</svg>' +
      '<div class="B-tag"><b>' + esc(view.map.area) + '</b>' + (view.map.region ? '<span>' + esc(view.map.region) + '</span>' : '') +
      (lv ? '<span class="B-lv">' + lv + '</span>' : '') + (away ? '<span class="B-away">' + away + '</span>' : '') + '</div></div>' +
      (holds.length ? '<div class="B-side">' + holds.map(function (x) { return '<div class="B-k">' + x.k + '</div>' + x.v.map(function (n) { return '<div>' + esc(n) + '</div>'; }).join(''); }).join('') + '</div>' : '') +
      '</div>';
  }

  // ===============================================================================
  // C — Floor plan: rooms are walled squares that nearly touch, an exit is a gap
  // in the wall, a diagonal is a narrow passage across the corner. Terrain is a
  // flat floor tint plus a glyph; header is a title bar with level steps, holds
  // a single summary line.
  // ===============================================================================

  var GLYPH = { inside: '▫', city: '#', road: '=', field: '"', forest: '♣', water: '≈', swamp: '⸗', cave: '∩', hills: '⌒' };

  function variantC(view, s) {
    var S = 17, h = S / 2, gap = 6, g = '', walls = '', marks = '';
    var open = {}; // room id -> set of sides opened: n e s w
    function openSide(id, w) { (open[id] = open[id] || {})[w] = true; }
    var SIDE = { north: 'n', south: 's', east: 'e', west: 'w' };
    var byRoom = {};
    s.rooms.forEach(function (o) { byRoom[o.r.x + ',' + o.r.y] = o; });
    // passages first, so floors sit over them
    s.edges.forEach(function (e) {
      var ida = idOf(s, e.a), idb = idOf(s, e.b);
      if (!e.diag && !e.far) {
        var v = [e.b.x - e.a.x, e.b.y - e.a.y], sa = v[0] > 0 ? 'e' : v[0] < 0 ? 'w' : v[1] > 0 ? 'n' : 's';
        var sb = { n: 's', s: 'n', e: 'w', w: 'e' }[sa];
        openSide(ida, sa); openSide(idb, sb);
        var x1 = px(e.a), y1 = py(e.a), x2 = px(e.b), y2 = py(e.b);
        g += '<line x1="' + x1 + '" y1="' + y1 + '" x2="' + x2 + '" y2="' + y2 + '" stroke="#30363d" stroke-width="' + gap + '"/>';
      } else {
        g += '<line x1="' + px(e.a) + '" y1="' + py(e.a) + '" x2="' + px(e.b) + '" y2="' + py(e.b) + '" stroke="#30363d" stroke-width="3.2"' + (e.far ? ' stroke-dasharray="3 2"' : '') + '/>' +
          '<line x1="' + px(e.a) + '" y1="' + py(e.a) + '" x2="' + px(e.b) + '" y2="' + py(e.b) + '" stroke="#6e7681" stroke-width=".6" stroke-dasharray="1 1.4"/>';
      }
    });
    s.stubs.forEach(function (st) {
      var x = px(st.r), y = py(st.r), o = off(st.word, U * 0.8), id = idOf(s, st.r);
      if (SIDE[st.word]) openSide(id, SIDE[st.word]);
      var col = st.kind === 'back' ? BACK : '#30363d';
      if (st.kind === 'unexplored') {
        g += '<line x1="' + x + '" y1="' + y + '" x2="' + (x + o[0]) + '" y2="' + (y + o[1]) + '" stroke="#30363d" stroke-width="' + (SIDE[st.word] ? gap : 3.2) + '"/>';
        marks += '<text x="' + (x + o[0]) + '" y="' + (y + o[1] + 2.4) + '" font-size="7" text-anchor="middle" fill="#8b949e">…</text>';
      } else {
        g += '<line x1="' + x + '" y1="' + y + '" x2="' + (x + o[0]) + '" y2="' + (y + o[1]) + '" stroke="' + col + '" stroke-width="' + (SIDE[st.word] ? gap : 3.2) + '"/>';
        var d = off(st.word, 1), ex = x + o[0], ey = y + o[1];
        marks += '<path d="M' + (ex - d[0] * 3 + d[1] * 2.6) + ' ' + (ey - d[1] * 3 - d[0] * 2.6) + 'L' + ex + ' ' + ey + 'L' + (ex - d[0] * 3 - d[1] * 2.6) + ' ' + (ey - d[1] * 3 + d[0] * 2.6) + '" fill="none" stroke="' + (st.kind === 'back' ? BACK : '#8b949e') + '" stroke-width="1.3"/>';
      }
    });
    s.rooms.forEach(function (o) {
      var r = o.r, x = px(r) - h, y = py(r) - h, col = TERRAIN[r.terrain] || NONE, sides = open[o.id] || {};
      g += '<g data-id="' + esc(o.id) + '"><title>' + esc(tip(o)) + '</title>' +
        '<rect x="' + x + '" y="' + y + '" width="' + S + '" height="' + S + '" fill="#0d1117"/>' +
        '<rect x="' + x + '" y="' + y + '" width="' + S + '" height="' + S + '" fill="' + col + '" fill-opacity="' + (r.terrain ? '.55' : '.2') + '"/>' +
        '<text x="' + (x + 2.2) + '" y="' + (y + 6.6) + '" font-size="6" fill="#e6edf3" fill-opacity=".8">' + (GLYPH[r.terrain] || '') + '</text></g>';
      // four walls, each with a doorway gap when that side is open
      var segs = { n: [x, y, x + S, y], s: [x, y + S, x + S, y + S], w: [x, y, x, y + S], e: [x + S, y, x + S, y + S] };
      keys(segs).forEach(function (k) {
        var q = segs[k];
        if (!sides[k]) { walls += '<line x1="' + q[0] + '" y1="' + q[1] + '" x2="' + q[2] + '" y2="' + q[3] + '"/>'; return; }
        var mx = (q[0] + q[2]) / 2, my = (q[1] + q[3]) / 2, hz = q[1] === q[3], a = gap / 2;
        walls += hz ? '<line x1="' + q[0] + '" y1="' + q[1] + '" x2="' + (mx - a) + '" y2="' + my + '"/><line x1="' + (mx + a) + '" y1="' + q[1] + '" x2="' + q[2] + '" y2="' + my + '"/>'
          : '<line x1="' + q[0] + '" y1="' + q[1] + '" x2="' + mx + '" y2="' + (my - a) + '"/><line x1="' + q[0] + '" y1="' + (my + a) + '" x2="' + mx + '" y2="' + q[3] + '"/>';
      });
      if (o.up) marks += '<text x="' + (x + S - 2) + '" y="' + (y + 6.4) + '" font-size="6.5" text-anchor="end" fill="#e6edf3"' + (o.up !== true ? ' fill-opacity=".5"' : '') + '>↑</text>';
      if (o.down) marks += '<text x="' + (x + S - 2) + '" y="' + (y + S - 2) + '" font-size="6.5" text-anchor="end" fill="#e6edf3"' + (o.down !== true ? ' fill-opacity=".5"' : '') + '>↓</text>';
      if (o.odd.length) marks += '<text x="' + (x + 2) + '" y="' + (y + S - 2.2) + '" font-size="6" fill="' + (o.odd.some(function (q) { return q.kind === 'back'; }) ? BACK : '#e6edf3') + '"><title>' + esc(o.odd.map(function (q) { return q.word; }).join(', ')) + '</title>⇱</text>';
    });
    // doors sit in the doorway: closed = a leaf filling the gap, open = the leaf swung aside
    s.edges.concat(s.stubs).forEach(function (e) {
      if (!e.door) return;
      var a = e.a || e.r, v = DIRS[e.word] || [Math.sign(e.b.x - a.x), Math.sign(e.b.y - a.y)];
      var mx = px(a) + v[0] * h, my = py(a) - v[1] * h, hz = v[1] !== 0, L = gap / 2 + .6;
      var tipT = '<title>' + esc(e.door.name) + (e.door.closed ? ' (closed)' : ' (open)') + '</title>';
      if (e.door.closed) marks += '<line x1="' + (hz ? mx - L : mx) + '" y1="' + (hz ? my : my - L) + '" x2="' + (hz ? mx + L : mx) + '" y2="' + (hz ? my : my + L) + '" stroke="#f0883e" stroke-width="2.6">' + tipT + '</line>';
      else marks += '<line x1="' + (hz ? mx - L : mx) + '" y1="' + (hz ? my : my - L) + '" x2="' + (hz ? mx - L : mx + v[0] * L * 1.6) + '" y2="' + (hz ? my - v[1] * L * 1.6 : my - L) + '" stroke="#f0883e" stroke-width="1.4">' + tipT + '</line>';
    });
    s.members.forEach(function (m, i) {
      if (!m.here) return;
      var x = px(m.r) - h + 4 + i * 5, y = py(m.r) + h - 4;
      marks += '<g><title>' + esc(m.name) + '</title><rect x="' + (x - 3) + '" y="' + (y - 3) + '" width="6" height="6" rx="1" fill="' + GROUP + '"/><text x="' + x + '" y="' + (y + 1.8) + '" font-size="4.8" text-anchor="middle" fill="#0d1117" font-weight="700">' + esc(m.name[0]) + '</text></g>';
    });
    if (s.you) marks += '<g><title>You</title><circle cx="' + px(s.you) + '" cy="' + py(s.you) + '" r="4.6" fill="' + YOU + '" stroke="#0d1117" stroke-width="1.4"/><circle cx="' + px(s.you) + '" cy="' + py(s.you) + '" r="1.5" fill="#0d1117"/></g>';

    var lv = levelText(s), holds = holdsList(view.map), away = awayNote(s);
    var steps = s.zs.length > 1 ? '<span class="C-steps">' + s.zs.slice().reverse().map(function (z) {
      return '<i class="' + (z === s.z ? 'on' : '') + (z === s.youLevel ? ' you' : '') + '" title="Level ' + (s.zs.indexOf(z) + 1) + '"></i>';
    }).join('') + '</span>' : '';
    return '<div class="C">' +
      '<div class="C-bar"><span class="C-area">' + esc(view.map.area) + '</span>' + (view.map.region ? '<span class="C-region">, ' + esc(view.map.region) + '</span>' : '') +
      (lv ? '<span class="C-lv">' + steps + lv + '</span>' : '') + '</div>' +
      '<div class="C-body">' + frame(s, U * 0.95, 32) + g + '<g stroke="#c9d1d9" stroke-width="1.1" stroke-linecap="square">' + walls + '</g>' + marks + '</svg></div>' +
      (away ? '<div class="C-foot">' + away + '</div>' : '') +
      (holds.length ? '<div class="C-foot" title="' + esc(holds.map(function (x) { return x.k + ': ' + x.v.join(', '); }).join('\n')) + '">' +
        holds.map(function (x) { return x.k + ' ' + x.v.length; }).join(' · ') + ': ' + esc(holds.map(function (x) { return x.v.join(', '); }).join('; ')) + '</div>' : '') +
      '</div>';
  }

  function idOf(s, r) { for (var i = 0; i < s.rooms.length; i++) if (s.rooms[i].r === r) return s.rooms[i].id; }

  var CSS = [
    '.mapwin{display:flex;flex-direction:column;height:100%;min-height:0}',
    '.mapwin[data-state="unfed"],.mapwin[data-state="severed"]{opacity:.45}',
    '.plane{width:100%;height:100%;display:block;margin:auto}',
    '.reason{margin:auto;padding:1em;text-align:center;color:#8b949e;max-width:22em}',
    '.reason code{color:#c9d1d9}',
    '.unfed{margin:auto;color:#6e7681}',
    // A
    '.A{display:flex;flex-direction:column;height:100%;min-height:0;gap:4px}',
    '.A-head{display:flex;align-items:baseline;gap:.6em;border-bottom:1px solid #30363d;padding:0 2px 3px;white-space:nowrap;overflow:hidden}',
    '.A-area{font-weight:600;color:#e6edf3}.A-region{color:#8b949e;font-size:.92em}.A-level{margin-left:auto;color:#8b949e;font-size:.92em}',
    '.A-body{flex:1;min-height:0;display:flex}',
    '.A-away{font-size:.85em;color:#8b949e;text-align:center}',
    '.A-holds{border-top:1px solid #30363d;padding-top:3px;font-size:.88em;color:#8b949e}.A-holds b{color:#c9d1d9;font-weight:600}',
    // B
    '.B{display:flex;height:100%;min-height:0;gap:6px}',
    '.B-map{position:relative;flex:1;min-width:0;display:flex}',
    '.B-tag{position:absolute;left:0;top:0;display:flex;flex-direction:column;background:rgba(13,17,23,.78);padding:2px 6px 3px;border-radius:4px;font-size:.92em;pointer-events:none}',
    '.B-tag b{color:#e6edf3}.B-tag span{color:#8b949e;font-size:.92em}.B-lv{color:#ffd33d!important}.B-away{color:#ff7b72!important}',
    '.B-side{width:8.5em;flex:none;border-left:1px solid #30363d;padding-left:6px;font-size:.86em;color:#c9d1d9;overflow:auto}',
    '.B-k{color:#8b949e;text-transform:uppercase;letter-spacing:.06em;font-size:.85em;margin-top:4px}',
    // C
    '.C{display:flex;flex-direction:column;height:100%;min-height:0}',
    '.C-bar{display:flex;align-items:center;background:#161b22;border:1px solid #30363d;border-radius:4px;padding:2px 6px;white-space:nowrap;overflow:hidden}',
    '.C-area{color:#e6edf3;font-weight:600}.C-region{color:#8b949e}',
    '.C-lv{margin-left:auto;display:flex;align-items:center;gap:5px;color:#8b949e;font-size:.9em}',
    '.C-steps{display:inline-flex;flex-direction:column;gap:1px}.C-steps i{display:block;width:12px;height:3px;background:#30363d}.C-steps i.on{background:#c9d1d9}.C-steps i.you{outline:1px solid #ffd33d}',
    '.C-body{flex:1;min-height:0;display:flex;padding:4px 0}',
    '.C-foot{font-size:.86em;color:#8b949e;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}',
  ].join('\n');

  function render(variant, view) {
    var body;
    if (view.hud === 'unfed' || !view.map && !view.reason) body = '<div class="unfed">Map</div>';
    else if (view.reason && view.hud === 'live') body = '<div class="reason">' + reasonText(view) + '</div>';
    else if (view.reason) body = '<div class="unfed">Map</div>';
    else {
      var s = scene(view);
      body = variant === 'B' ? variantB(view, s) : variant === 'C' ? variantC(view, s) : variantA(view, s, variant === 'D');
    }
    return '<div class="mapwin" data-state="' + (view.hud || 'live') + '">' + body + '</div>';
  }

  root.MapLook = { render: render, CSS: CSS, scene: scene, levels: levels, shownLevel: shownLevel,
    NAMES: { A: 'Tiles, texture', D: 'Tiles, one motif', B: 'Nodes and lines', C: 'Floor plan' } };
})(typeof window !== 'undefined' ? window : globalThis);
