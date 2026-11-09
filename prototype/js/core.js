// Noyau : espace de noms, bus d'événements, état partagé (persistant), utilitaires.
// En QML : signaux/propriétés d'objets singletons (ShellState, Settings…).
const PERSISTED = ["theme", "accent", "wallpaper", "widgets", "widgetPos", "note", "dockSize", "magnify", "pinned"];

window.Shell = {
  _handlers: {},
  on(evt, fn) { (this._handlers[evt] ||= []).push(fn); },
  emit(evt, data) { (this._handlers[evt] || []).forEach((fn) => fn(data)); },

  // État global (futur : services D-Bus et fichiers de configuration utilisateur)
  state: {
    theme: "dark",
    accent: "#A855F7",
    wallpaper: "nebula",
    widgets: { clock: true, agenda: true, note: false },
    widgetPos: {},
    note: "",
    dockSize: 48,
    magnify: true,
    pinned: ["files", "firefox", "writer", "calc", "mail", "calendar", "store", "settings"],
    wifi: true,
    bluetooth: true,
    dnd: false,
    volume: 60,
    brightness: 80,
    battery: 86,
    notifications: [],
  },

  set(key, value) { this.state[key] = value; this.save(); this.emit("state", { key, value }); },

  // Préférences conservées dans le navigateur (équivalent : ~/.config/vinx/shell.toml).
  save() {
    try { localStorage.setItem("vinx-state", JSON.stringify(Object.fromEntries(PERSISTED.map((k) => [k, this.state[k]])))); } catch {}
  },
  load() {
    try {
      const saved = JSON.parse(localStorage.getItem("vinx-state") || "{}");
      PERSISTED.forEach((k) => { if (k in saved) this.state[k] = saved[k]; });
    } catch {}
  },
  reset() { try { localStorage.removeItem("vinx-state"); } catch {} location.reload(); },
};
Shell.load();

const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];
const h = (html) => { const t = document.createElement("template"); t.innerHTML = html.trim(); return t.content.firstElementChild; };
const norm = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
const TOPBAR_H = 34;
