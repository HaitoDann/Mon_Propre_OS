// Noyau : espace de noms, bus d'événements, état partagé, utilitaires.
// En QML : signaux/propriétés d'objets singletons (ShellState, Settings…).
window.Shell = {
  _handlers: {},
  on(evt, fn) { (this._handlers[evt] ||= []).push(fn); },
  emit(evt, data) { (this._handlers[evt] || []).forEach((fn) => fn(data)); },

  // État global (futur : services D-Bus / fichiers de configuration)
  state: {
    theme: "dark",
    accent: "#5B7CFF",
    wifi: true,
    bluetooth: true,
    dnd: false,
    volume: 60,
    brightness: 80,
    battery: 86,
    notifications: [],
  },
  set(key, value) { this.state[key] = value; this.emit("state", { key, value }); },
};

const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];
const h = (html) => { const t = document.createElement("template"); t.innerHTML = html.trim(); return t.content.firstElementChild; };
