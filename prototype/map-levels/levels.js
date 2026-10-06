// PROTOTYPE — throwaway (wayfinder ticket "How the player steps between levels", map #17).
// Four level controls on look A "Tiles" (../map-look/render.js). Each control is
// plain HTML/SVG whose clickable parts carry data-mud-action="level" and
// data-mud-data="<z>" or "mine", so a click goes to Lua exactly as the real window's
// would. Lua owns Browsing; this file only draws.
//
//   LevelCtl.view(variant, view) -> view with levelHtml / awayHtml / sideHtml / stairClick
(function (root) {
  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function act(z) { return ' data-mud-action="level" data-mud-data="' + z + '"'; }
  function n(s, z) { return s.zs.indexOf(z) + 1; }
  function browsing(s) { return s.youLevel != null && s.youLevel !== s.z; }
  // who stands on level z: you (yellow) and members (coral)
  function dots(s, z) {
    var d = '';
    if (s.youLevel === z) d += '<i class="L-dy" title="You"></i>';
    s.members.forEach(function (m) { if (m.r.z === z) d += '<i class="L-dm" title="' + esc(m.name) + '"></i>'; });
    return d;
  }
  // members on another level than the one shown; you too, while Browsing
  function away(s, withBack) {
    var t = [];
    if (browsing(s)) t.push('You: level ' + n(s, s.youLevel) + (withBack ? ' <button class="L-back"' + act('mine') + '>back to you</button>' : ''));
    s.members.forEach(function (m) { if (!m.here) t.push(esc(m.name) + ': level ' + n(s, m.r.z)); });
    return t.join(' · ');
  }

  var V = {
    // A — Stepper: ▼ Level n of m ▲ at the right of the header bar.
    A: function (v) {
      v.levelHtml = function (s) {
        if (s.zs.length < 2) return '';
        var i = s.zs.indexOf(s.z), lo = s.zs[i - 1], hi = s.zs[i + 1];
        return '<span class="L-step">' +
          '<button title="Level below"' + (lo == null ? ' disabled' : act(lo)) + '>▼</button>' +
          '<span class="' + (browsing(s) ? 'L-br' : '') + '">Level ' + (i + 1) + ' of ' + s.zs.length + '</span>' +
          '<button title="Level above"' + (hi == null ? ' disabled' : act(hi)) + '>▲</button></span>';
      };
      v.awayHtml = function (s) { return away(s, true); };
      return v;
    },
    // B — Chips: one numbered chip per level in the header; the shown one filled,
    // yellow/coral dots for who is on each.
    B: function (v) {
      v.levelHtml = function (s) {
        if (s.zs.length < 2) return '';
        return '<span class="L-chips">' + s.zs.map(function (z) {
          return '<button class="' + (z === s.z ? 'on' : '') + '" title="Level ' + n(s, z) + '"' + act(z) + '>' + n(s, z) + dots(s, z) + '</button>';
        }).join('') + '</span>';
      };
      v.awayHtml = function (s) { return away(s, false); };
      return v;
    },
    // C — Ladder: a strip down the plane's right edge, highest level on top.
    // The header keeps its "Level n of m" text.
    C: function (v) {
      v.sideHtml = function (s) {
        if (s.zs.length < 2) return '';
        return '<div class="L-ladder">' + s.zs.slice().reverse().map(function (z) {
          return '<button class="' + (z === s.z ? 'on' : '') + '" title="Level ' + n(s, z) + '"' + act(z) + '>' + n(s, z) + '<span>' + dots(s, z) + '</span></button>';
        }).join('') + '</div>';
      };
      v.awayHtml = function (s) { return away(s, false); };
      return v;
    },
    // D — Stairs: no buttons. Click a white up/down mark on the plane to show the
    // level it leads to; while Browsing the header offers the way back.
    D: function (v) {
      v.stairClick = true;
      v.levelHtml = function (s) {
        if (s.zs.length < 2) return '';
        return '<span class="' + (browsing(s) ? 'L-br' : '') + '">Level ' + n(s, s.z) + ' of ' + s.zs.length + '</span>' +
          (browsing(s) ? ' <button class="L-back"' + act('mine') + '>↩ yours</button>' : '');
      };
      return v;
    },
  };

  var CSS = [
    '.L-step{display:inline-flex;align-items:center;gap:4px}',
    '.L-step button,.L-chips button,.L-ladder button,.L-back{background:#161b22;color:#c9d1d9;border:1px solid #30363d;border-radius:3px;font:inherit;cursor:pointer;line-height:1.2}',
    '.L-step button{padding:0 5px;font-size:.85em}',
    '.L-step button:disabled{opacity:.3;cursor:default}',
    '.L-step button:not(:disabled):hover,.L-chips button:hover,.L-ladder button:hover,.L-back:hover{border-color:#8b949e;color:#fff}',
    '.L-br{color:#39c5cf}',
    '.L-chips{display:inline-flex;gap:3px;align-items:center}',
    '.L-chips button{position:relative;min-width:1.7em;padding:0 4px}',
    '.L-chips button.on,.L-ladder button.on{background:#c9d1d9;color:#0d1117;border-color:#c9d1d9;font-weight:600}',
    '.L-dy,.L-dm{display:inline-block;width:5px;height:5px;border-radius:50%;margin-left:2px;vertical-align:middle;box-shadow:0 0 0 1px #0d1117}',
    '.L-dy{background:#ffd33d}.L-dm{background:#ff7b72}',
    '.L-ladder{flex:none;display:flex;flex-direction:column;justify-content:center;gap:3px;padding-left:4px;border-left:1px solid #30363d}',
    '.L-ladder button{width:2.3em;padding:2px 0;display:flex;flex-direction:column;align-items:center}',
    '.L-ladder button span{height:6px;line-height:0}',
    '.L-back{font-size:.85em;padding:0 5px;color:#39c5cf;border-color:#1b4e53}',
    '.stair{cursor:pointer}.stair:hover path{fill:#39c5cf}',
  ].join('\n');

  root.LevelCtl = {
    view: function (variant, view) { return (V[variant] || V.A)(view); },
    CSS: CSS, VARIANTS: ['A', 'B', 'C', 'D'],
    NAMES: { A: 'Stepper in the header', B: 'Chips in the header', C: 'Ladder at the side', D: 'Click the stairs' },
  };
})(typeof window !== 'undefined' ? window : globalThis);
