// Jeu d'icônes SVG au trait (grille 24 px, trait 1.8, extrémités arrondies).
// Un seul style pour tout le système ; exportable tel quel en thème d'icônes.
const ICONS = {
  folder: '<path d="M3 7.5A2.5 2.5 0 0 1 5.5 5H9l2 2h7.5A2.5 2.5 0 0 1 21 9.5v7a2.5 2.5 0 0 1-2.5 2.5h-13A2.5 2.5 0 0 1 3 16.5z"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.7 3.8 5.7 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-5.7-3.8-9S9.5 5.7 12 3z"/>',
  doc: '<path d="M7 3h7l5 5v11a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"/><path d="M14 3v5h5M9 13h6M9 17h6"/>',
  table: '<rect x="4" y="4" width="16" height="16" rx="2.5"/><path d="M4 10h16M4 15h16M10 4v16"/>',
  mail: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m4 7 8 6 8-6"/>',
  calendar: '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
  bag: '<path d="M5 8h14l-1.2 11a2 2 0 0 1-2 1.8H8.2a2 2 0 0 1-2-1.8z"/><path d="M9 10V7a3 3 0 0 1 6 0v3"/>',
  sliders: '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"/><circle cx="15" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="18" r="2"/>',
  terminal: '<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="m7 9 3 3-3 3M12.5 15H17"/>',
  note: '<path d="M6 3h12a1 1 0 0 1 1 1v12l-5 5H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/><path d="M14 21v-5h5M9 8h6M9 12h4"/>',
  image: '<rect x="3" y="4" width="18" height="16" rx="2.5"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>',
  music: '<path d="M9 18V5l11-2v13"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="17.5" cy="16" r="2.5"/>',

  search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
  wifi: '<path d="M2.5 9a14 14 0 0 1 19 0M5.5 12.5a9.5 9.5 0 0 1 13 0M8.8 16a4.8 4.8 0 0 1 6.4 0"/><circle cx="12" cy="19.3" r=".9" fill="currentColor"/>',
  wifiOff: '<path d="M3 3l18 18M8.8 16a4.8 4.8 0 0 1 6.4 0M5.5 12.5a9.5 9.5 0 0 1 4-2.3M2.5 9a14 14 0 0 1 5-2.8M14.5 10.4a9.5 9.5 0 0 1 4 2.1M12 5a14 14 0 0 1 9.5 4"/>',
  bluetooth: '<path d="m7 7 10 10-5 4.5v-19L17 7 7 17"/>',
  moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M4.6 4.6 6 6M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4 6 18M18 6l1.4-1.4"/>',
  volume: '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11"/>',
  volumeOff: '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="m16 10 4 4M20 10l-4 4"/>',
  brightness: '<circle cx="12" cy="12" r="3.5"/><path d="M12 3v1.5M12 19.5V21M3 12h1.5M19.5 12H21M5.6 5.6l1 1M17.4 17.4l1 1M5.6 18.4l1-1M17.4 6.6l1-1"/>',
  bell: '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
  bellOff: '<path d="M3 3l18 18M9 5.5A6 6 0 0 1 18 11v4M6 11v5l-1.5 2H17"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
  power: '<path d="M12 3v8"/><path d="M6.5 6.5a7.5 7.5 0 1 0 11 0"/>',
  lock: '<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V7.5a4 4 0 0 1 8 0V11"/>',
  restart: '<path d="M4 12a8 8 0 1 0 2.4-5.7L4 8.5"/><path d="M4 4v4.5h4.5"/>',
  logout: '<path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4M10 16l-4-4 4-4M6 12h10"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  chevronL: '<path d="m15 6-6 6 6 6"/>',
  chevronR: '<path d="m9 6 6 6-6 6"/>',
  close: '<path d="M6 6l12 12M18 6 6 18"/>',
  minus: '<path d="M5 12h14"/>',
  expand: '<path d="M14 4h6v6M10 20H4v-6M20 4l-7 7M4 20l7-7"/>',
  grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.8"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.8"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  bolt: '<path d="M13 2.5 4.5 14H11l-1 7.5L18.5 10H12z"/>',
  equals: '<path d="M5 9h14M5 15h14"/>',
  splitL: '<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M12 4v16"/><rect x="5" y="6" width="5" height="12" rx="1" fill="currentColor" stroke="none"/>',
  splitR: '<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M12 4v16"/><rect x="14" y="6" width="5" height="12" rx="1" fill="currentColor" stroke="none"/>',
  fullscreen: '<path d="M4 9V5a1 1 0 0 1 1-1h4M15 4h4a1 1 0 0 1 1 1v4M20 15v4a1 1 0 0 1-1 1h-4M9 20H5a1 1 0 0 1-1-1v-4"/>',
  check: '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
  battery(pct = 80) {
    const w = Math.max(1.5, 13 * pct / 100).toFixed(1);
    return `<rect x="2.5" y="7" width="17" height="10" rx="2.5"/><path d="M22 10.5v3"/><rect x="4.5" y="9" width="${w}" height="6" rx="1" fill="currentColor" stroke="none"/>`;
  },
};

function icon(name, arg) {
  const body = typeof ICONS[name] === "function" ? ICONS[name](arg) : ICONS[name];
  return `<svg class="i" viewBox="0 0 24 24" aria-hidden="true">${body || ""}</svg>`;
}
function appIcon(app, cls = "") {
  return `<div class="app-icon ${cls}" style="background:linear-gradient(160deg, ${app.colors[0]}, ${app.colors[1]})">${icon(app.glyph)}</div>`;
}

// Logo VinX (copie de branding/logo/vinx-logo.svg — couleur héritée de currentColor).
const VINX_LOGO = '<svg class="vinx-logo" viewBox="115 268 1024 735" fill="currentColor" aria-label="VinX OS"><polygon points="125,278 253,278 618,645 263,993 263,493 349,578 349,795 491,653"/><polygon transform="translate(1254 0) scale(-1 1)" points="125,278 253,278 618,645 263,993 263,493 349,578 349,795 491,653"/><polygon points="627,283 707,383 627,488 547,383"/><polygon points="627,693 752,823 502,823"/></svg>';
