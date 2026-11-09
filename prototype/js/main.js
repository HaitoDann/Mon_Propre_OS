// Point d'entrée : initialisation des composants et liaisons globales.

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
Shell.on("state", ({ key, value }) => {
  if (key === "theme") document.documentElement.dataset.theme = value;
  if (key === "accent") document.documentElement.style.setProperty("--accent", value);
  if (key === "theme" || key === "accent") syncSettingsUI();
});
function syncSettingsUI() {
  $$("[data-theme-seg] button").forEach((b) => b.classList.toggle("on", b.dataset.v === Shell.state.theme));
  $$("[data-accent]").forEach((b) => b.classList.toggle("on", b.dataset.accent === Shell.state.accent));
}
Shell.on("windows", syncSettingsUI);

// Interactions dans les contenus d'apps (délégation).
document.addEventListener("click", (e) => {
  const seg = e.target.closest("[data-theme-seg] button"); if (seg) Shell.set("theme", seg.dataset.v);
  const acc = e.target.closest("[data-accent]"); if (acc) Shell.set("accent", acc.dataset.accent);
  const chip = e.target.closest("[data-chip]");
  if (chip) $$("[data-chip]", chip.parentElement).forEach((c) => c.classList.toggle("on", c === chip));
  const inst = e.target.closest("[data-install]");
  if (inst && !inst.classList.contains("done")) {
    inst.textContent = "Installation…";
    setTimeout(() => { inst.textContent = "Installé"; inst.classList.replace("primary", "done"); toast("Store", `${inst.dataset.install} a été installé.`, appById("store")); }, 1000);
  }
});

// Raccourcis clavier globaux.
addEventListener("keydown", (e) => {
  const ctrl = e.ctrlKey || e.metaKey;
  if (ctrl && e.code === "Space") { e.preventDefault(); Launcher.toggle(); }
  if (e.key === "Escape" && Launcher.isOpen()) Launcher.toggle(false);
  const w = WM.focused();
  if (ctrl && e.key.toLowerCase() === "w" && w) { e.preventDefault(); WM.close(w); }
  if (ctrl && e.key.toLowerCase() === "m" && w) { e.preventDefault(); WM.minimize(w); }
});

document.addEventListener("contextmenu", (e) => { if (!e.target.closest(".content")) e.preventDefault(); });

TopBar.init();
Dock.init();
Launcher.init();
setTimeout(() => toast("Bienvenue", "Votre système est prêt. Ctrl+Espace pour rechercher."), 700);
