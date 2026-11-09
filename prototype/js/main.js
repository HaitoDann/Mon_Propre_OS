// Point d'entrée : notifications, liaison état ↔ interface, raccourcis, démarrage.

function toast(title, msg, app = appById("settings")) {
  Shell.state.notifications.push({ title, msg, app });
  if (Shell.state.dnd) return;
  const t = h(`<div class="toast material">${appIcon(app)}<div><b>${title}</b><small>${msg}</small></div></div>`);
  const dismiss = () => { t.classList.add("out"); setTimeout(() => t.remove(), 220); };
  t.onclick = dismiss;
  $("#toasts").appendChild(t);
  setTimeout(dismiss, 4500);
}

// Thème et accent appliqués via les tokens CSS (en QML : Theme.dark / Theme.accent).
function applyAppearance() {
  const root = document.documentElement;
  root.dataset.theme = Shell.state.theme;
  // L'accent choisi s'applique aux deux thèmes ; le violet de marque garde sa variante claire.
  if (Shell.state.accent === "#A855F7") root.style.removeProperty("--accent");
  else root.style.setProperty("--accent", Shell.state.accent);
}
Shell.on("state", ({ key }) => {
  if (key === "theme" || key === "accent") applyAppearance();
  syncSettingsUI();
});

// Synchronise les contrôles de l'app Paramètres avec l'état.
function syncSettingsUI() {
  const s = Shell.state;
  $$("[data-theme-seg] button").forEach((b) => b.classList.toggle("on", b.dataset.v === s.theme));
  $$("[data-accent]").forEach((b) => b.classList.toggle("on", b.dataset.accent === s.accent));
  $$("[data-wallpaper]").forEach((b) => b.classList.toggle("on", b.dataset.wallpaper === s.wallpaper));
  $$("[data-widget]").forEach((i) => (i.checked = !!s.widgets[i.dataset.widget]));
  $$("[data-magnify]").forEach((i) => (i.checked = s.magnify));
  $$("[data-dock-size]").forEach((i) => (i.value = s.dockSize));
}
Shell.on("windows", syncSettingsUI);

// Interactions dans les contenus d'apps (délégation).
document.addEventListener("click", (e) => {
  const t = e.target;
  const seg = t.closest("[data-theme-seg] button"); if (seg) Shell.set("theme", seg.dataset.v);
  const acc = t.closest("[data-accent]"); if (acc) Shell.set("accent", acc.dataset.accent);
  const wall = t.closest("[data-wallpaper]"); if (wall) Shell.set("wallpaper", wall.dataset.wallpaper);
  if (t.closest("[data-reset]")) Shell.reset();
  const chip = t.closest("[data-chip]");
  if (chip) $$("[data-chip]", chip.parentElement).forEach((c) => c.classList.toggle("on", c === chip));
  const inst = t.closest("[data-install]");
  if (inst && !inst.classList.contains("done")) {
    inst.textContent = "Installation…";
    setTimeout(() => { inst.textContent = "Installé"; inst.classList.replace("primary", "done"); toast("Store", `${inst.dataset.install} a été installé.`, appById("store")); }, 1000);
  }
});
document.addEventListener("change", (e) => {
  const t = e.target;
  if (t.dataset.widget) Shell.set("widgets", { ...Shell.state.widgets, [t.dataset.widget]: t.checked });
  if (t.hasAttribute("data-magnify")) Shell.set("magnify", t.checked);
});
document.addEventListener("input", (e) => { if (e.target.hasAttribute("data-dock-size")) Shell.set("dockSize", +e.target.value); });

// Raccourcis clavier globaux (liste de référence : SHORTCUTS dans apps.js).
addEventListener("keydown", (e) => {
  const ctrl = e.ctrlKey || e.metaKey, k = e.key;
  const typing = e.target.closest?.("input, textarea") && e.target.id !== "search";
  const w = WM.focused();

  if (ctrl && e.code === "Space") { e.preventDefault(); return Search.toggle(); }
  if (k === "F3" || (ctrl && e.altKey && k === "ArrowUp")) { e.preventDefault(); return Expose.toggle(); }

  if (k === "Escape") {
    if (Popover.close()) return;
    if (Search.isOpen()) return Search.toggle(false);
    if (Expose.active) return Expose.exit();
    const full = WM.visible().find((x) => x.state === "full");
    if (full) return WM.restoreNormal(full);
    return;
  }
  if (typing) return;

  if (ctrl && e.altKey && (k === "ArrowLeft" || k === "ArrowRight")) {
    e.preventDefault();
    const target = WM.ws.current + (k === "ArrowRight" ? 1 : -1);
    if (e.shiftKey && w) { if (target >= 0 && target < WM.ws.count) { WM.moveToWorkspace(w, target); WM.switchWorkspace(target); WM.focus(w); } }
    else WM.switchWorkspace(target);
    if (Expose.active) Expose.refresh();
    return;
  }
  if (ctrl && e.shiftKey && !e.altKey) {
    const map = { ArrowLeft: () => WM.tile(w, "left"), ArrowRight: () => WM.tile(w, "right"), ArrowUp: () => WM.toggleMaximize(w), ArrowDown: () => WM.minimize(w), F: () => WM.toggleFullscreen(w) };
    const key = k.length === 1 ? k.toUpperCase() : k;
    if (key === "G") { e.preventDefault(); return WM.arrange(); }
    if (map[key] && w) { e.preventDefault(); return map[key](); }
  }
  if (ctrl && !e.shiftKey && k.toLowerCase() === "w" && w) { e.preventDefault(); WM.close(w); }
  if (ctrl && !e.shiftKey && k.toLowerCase() === "m" && w) { e.preventDefault(); WM.minimize(w); }
});

document.addEventListener("contextmenu", (e) => { if (!e.target.closest(".content")) e.preventDefault(); });
$("#expose-bg").addEventListener("click", () => Expose.exit());
addEventListener("resize", () => { if (Expose.active) Expose.refresh(); });

// Démarrage
applyAppearance();
Desktop.init();
TopBar.init();
Dock.init();
Search.init();
setTimeout(() => toast("Bienvenue sur VinX OS", "Ctrl+Espace pour rechercher · F3 pour la vue d'ensemble."), 700);
