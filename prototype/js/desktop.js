// Bureau : fond d'écran, widgets optionnels, menu contextuel, indicateur d'espace (OSD).
// Futur : Desktop.qml (couche sous les fenêtres) + widgets QML enfichables.

const WIDGETS = {
  clock: {
    name: "Horloge",
    render: () => {
      const d = new Date();
      return `<div class="w-time">${d.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}</div>
        <div class="w-date">${d.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" })}</div>`;
    },
  },
  agenda: {
    name: "Agenda",
    render: () => {
      const now = new Date(), mins = now.getHours() * 60 + now.getMinutes();
      const ev = [["09:30", "Point d'équipe", "#6366F1"], ["14:00", "Revue du budget", "#A855F7"], ["17:30", "Appel client", "#EC4899"]];
      return `<div class="w-head">Aujourd'hui</div>` + ev.map(([t, n, c]) => {
        const [hh, mm] = t.split(":").map(Number), past = hh * 60 + mm < mins;
        return `<div class="w-event ${past ? "past" : ""}"><i style="background:${c}"></i><span>${n}</span><small>${t}</small></div>`;
      }).join("");
    },
  },
  note: {
    name: "Note rapide",
    render: () => `<div class="w-head">Note rapide</div><textarea class="w-note" placeholder="Écrire une note…" spellcheck="false"></textarea>`,
  },
};

const Desktop = {
  init() {
    this.applyWallpaper();
    this.renderWidgets();
    setInterval(() => this.updateClock(), 15_000);
    Shell.on("state", ({ key }) => {
      if (key === "widgets") this.renderWidgets();
      if (key === "wallpaper") this.applyWallpaper();
    });
    Shell.on("workspace", ({ changed }) => changed && !Expose.active && this.osd());
    addEventListener("resize", () => this.renderWidgets());

    // Menu contextuel du bureau (fond uniquement).
    $("#desktop").addEventListener("contextmenu", (e) => {
      if (e.target.closest(".window, #dock, #topbar, .widget, .popover, #launcher, #expose-top")) return;
      e.preventDefault();
      const w = Shell.state.widgets;
      Popover.openAt(e.clientX, e.clientY, buildMenu([
        { header: "Widgets" },
        ...Object.entries(WIDGETS).map(([k, d]) => ({ label: d.name, checked: !!w[k], action: () => this.toggleWidget(k) })),
        "-",
        { label: "Vue d'ensemble", icon: "grid", kbd: "F3", action: () => Expose.enter() },
        { label: "Organiser les fenêtres", icon: "grid", kbd: "Ctrl+Maj+G", disabled: !WM.visible().length, action: () => WM.arrange() },
        "-",
        { label: "Changer le fond d'écran…", icon: "image", action: () => WM.activate("settings") },
        { label: "Paramètres…", icon: "sliders", action: () => WM.activate("settings") },
      ]));
    });
  },

  applyWallpaper() { document.documentElement.style.setProperty("--wallpaper", `url("${wallpaperUrl(Shell.state.wallpaper)}")`); },

  toggleWidget(k) { Shell.set("widgets", { ...Shell.state.widgets, [k]: !Shell.state.widgets[k] }); },

  // Par défaut, les widgets s'empilent en colonne à gauche (la droite accueille les notifications) ; position libre une fois déplacés.
  renderWidgets() {
    const layer = $("#widgets");
    layer.innerHTML = "";
    let y = TOPBAR_H + 24;
    Object.entries(WIDGETS).forEach(([k, def]) => {
      if (!Shell.state.widgets[k]) return;
      const el = h(`<div class="widget material" data-w="${k}">${def.render()}</div>`);
      layer.appendChild(el);
      const saved = Shell.state.widgetPos[k];
      const x = saved ? Math.min(saved.x, innerWidth - el.offsetWidth - 8) : 24;
      const top = saved ? Math.min(saved.y, innerHeight - el.offsetHeight - 8) : y;
      Object.assign(el.style, { left: Math.max(8, x) + "px", top: Math.max(TOPBAR_H + 8, top) + "px" });
      if (!saved) y += el.offsetHeight + 12;
      if (k === "note") {
        const ta = el.querySelector("textarea");
        ta.value = Shell.state.note;
        ta.addEventListener("input", () => { Shell.state.note = ta.value; Shell.save(); });
      }
      this.makeDraggable(el, k);
    });
  },

  updateClock() { const c = $('.widget[data-w="clock"]'); if (c) c.innerHTML = WIDGETS.clock.render(); const a = $('.widget[data-w="agenda"]'); if (a) a.innerHTML = WIDGETS.agenda.render(); },

  makeDraggable(el, key) {
    el.addEventListener("pointerdown", (e) => {
      if (e.target.closest("textarea") || e.button !== 0) return;
      const ox = e.clientX - el.offsetLeft, oy = e.clientY - el.offsetTop;
      el.classList.add("moving");
      const move = (ev) => {
        el.style.left = Math.max(8, Math.min(innerWidth - el.offsetWidth - 8, ev.clientX - ox)) + "px";
        el.style.top = Math.max(TOPBAR_H + 8, Math.min(innerHeight - el.offsetHeight - 8, ev.clientY - oy)) + "px";
      };
      const up = () => {
        removeEventListener("pointermove", move); removeEventListener("pointerup", up);
        el.classList.remove("moving");
        Shell.set("widgetPos", { ...Shell.state.widgetPos, [key]: { x: el.offsetLeft, y: el.offsetTop } });
      };
      addEventListener("pointermove", move); addEventListener("pointerup", up);
    });
  },

  // Indicateur bref lors d'un changement d'espace de travail.
  osd() {
    const el = $("#ws-osd");
    el.innerHTML = `<span>Bureau ${WM.ws.current + 1}</span><span class="dots">${Array.from({ length: WM.ws.count }, (_, i) => `<i class="${i === WM.ws.current ? "on" : ""}"></i>`).join("")}</span>`;
    el.classList.remove("hidden");
    clearTimeout(this._osd);
    this._osd = setTimeout(() => el.classList.add("hidden"), 900);
  },
};
