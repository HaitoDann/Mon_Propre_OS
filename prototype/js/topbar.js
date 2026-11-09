// Barre supérieure : menu système, app active + menus, recherche, état système, horloge.
const TopBar = {
  init() {
    const bar = $("#topbar");
    bar.innerHTML = `
      <div class="zone">
        <button class="tb-item tb-logo" id="tb-logo" aria-label="Menu système">${VINX_LOGO}</button>
        <button class="tb-item tb-app" id="tb-app">Bureau</button>
        <div class="zone" id="tb-menus"></div>
      </div>
      <div class="zone">
        <button class="tb-item" id="tb-search" title="Rechercher (Ctrl+Espace)">${icon("search")}</button>
        <button class="tb-item tb-status" id="tb-status" title="Centre de contrôle"></button>
        <button class="tb-item tb-clock" id="tb-clock" title="Calendrier et notifications"></button>
      </div>`;

    this.bindMenu($("#tb-logo"), () => this.systemMenu());
    this.bindMenu($("#tb-app"), () => this.appMenu());
    this.bindMenu($("#tb-status"), () => ControlCenter.build(), "right");
    this.bindMenu($("#tb-clock"), () => CalendarPanel.build(), "right");
    $("#tb-search").onclick = () => Launcher.toggle(true);

    Shell.on("windows", () => this.updateApp());
    Shell.on("state", () => this.updateStatus());
    this.updateApp(); this.updateStatus(); this.tick();
    setInterval(() => this.tick(), 10_000);
  },

  // Ouvre au clic ; si un menu de la barre est ouvert, le survol bascule (comme macOS).
  bindMenu(btn, builder, align = "left") {
    const open = () => Popover.open(btn, builder(), { align });
    btn.addEventListener("click", () => (Popover.isOpenFor(btn) ? Popover.close() : open()));
    btn.addEventListener("mouseenter", () => {
      const c = Popover.current;
      if (c && c.anchor !== btn && c.anchor.closest("#topbar")) open();
    });
  },

  focusedApp() { const w = WM.focused(); return w ? appById(w.appId) : null; },

  updateApp() {
    const app = this.focusedApp();
    $("#tb-app").textContent = app ? app.name : "Bureau";
    const menus = $("#tb-menus");
    menus.innerHTML = "";
    (app ? APP_MENUS : ["Affichage", "Aide"]).forEach((name) => {
      const b = h(`<button class="tb-item tb-menu">${name}</button>`);
      this.bindMenu(b, () => this.genericMenu(name));
      menus.appendChild(b);
    });
  },

  updateStatus() {
    const s = Shell.state;
    $("#tb-status").innerHTML = `${icon(s.wifi ? "wifi" : "wifiOff")}${icon(s.volume ? "volume" : "volumeOff")}${s.dnd ? icon("bellOff") : ""}${icon("battery", s.battery)}<span class="pct">${s.battery} %</span>`;
  },

  tick() {
    $("#tb-clock").textContent = new Date().toLocaleString("fr-FR", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).replace(",", "");
  },

  systemMenu() {
    return buildMenu([
      { label: "À propos de ce système", icon: "info", action: () => toast("Système", "VinX OS 0.1 — Debian 13 « Trixie »") },
      "-",
      { label: "Paramètres…", icon: "sliders", action: () => WM.activate("settings") },
      { label: "Store…", icon: "bag", action: () => WM.activate("store") },
      "-",
      { label: "Verrouiller l'écran", icon: "lock", kbd: "Ctrl+Alt+L", action: () => toast("Session", "Écran verrouillé (simulation)") },
      { label: "Fermer la session…", icon: "logout", action: () => toast("Session", "Fermeture de session (simulation)") },
      { label: "Redémarrer…", icon: "restart", action: () => toast("Système", "Redémarrage (simulation)") },
      { label: "Éteindre…", icon: "power", action: () => toast("Système", "Extinction (simulation)") },
    ]);
  },

  appMenu() {
    const app = this.focusedApp();
    if (!app) return buildMenu([{ label: "Aucune application active", disabled: true }]);
    return buildMenu([
      { label: `À propos de ${app.name}`, action: () => toast(app.name, "Application de démonstration", app) },
      "-",
      { label: "Préférences…", kbd: "Ctrl+,", disabled: true },
      "-",
      { label: `Masquer ${app.name}`, kbd: "Ctrl+H", action: () => WM.ofApp(app.id).forEach((w) => WM.minimize(w)) },
      { label: `Quitter ${app.name}`, kbd: "Ctrl+Q", action: () => WM.closeApp(app.id) },
    ]);
  },

  genericMenu(name) {
    const w = WM.focused();
    const menus = {
      Fichier: [{ label: "Nouvelle fenêtre", kbd: "Ctrl+N", action: () => w && WM.create(w.appId) }, { label: "Ouvrir…", kbd: "Ctrl+O", disabled: true }, "-", { label: "Fermer la fenêtre", kbd: "Ctrl+W", action: () => w && WM.close(w) }],
      Édition: [{ label: "Annuler", kbd: "Ctrl+Z", disabled: true }, { label: "Rétablir", kbd: "Ctrl+Maj+Z", disabled: true }, "-", { label: "Couper", kbd: "Ctrl+X", disabled: true }, { label: "Copier", kbd: "Ctrl+C", disabled: true }, { label: "Coller", kbd: "Ctrl+V", disabled: true }],
      Affichage: [
        { label: "Thème sombre", checked: Shell.state.theme === "dark", action: () => Shell.set("theme", Shell.state.theme === "dark" ? "light" : "dark") },
        "-", { label: "Plein écran", kbd: "Ctrl+Cmd+F", disabled: !w, action: () => w && WM.toggleMaximize(w) }],
      Fenêtre: [{ label: "Réduire", kbd: "Ctrl+M", disabled: !w, action: () => w && WM.minimize(w) }, { label: "Agrandir / restaurer", disabled: !w, action: () => w && WM.toggleMaximize(w) }, "-",
        ...WM.windows.map((x) => ({ label: appById(x.appId).name, checked: x === w, action: () => (x.minimized ? WM.restore(x) : WM.focus(x)) }))],
      Aide: [{ label: "Raccourcis clavier", action: () => toast("Aide", "Ctrl+Espace : rechercher · Échap : fermer") }],
    };
    return buildMenu(menus[name] || []);
  },
};

// ---------- Centre de contrôle ----------
const ControlCenter = {
  build() {
    const s = Shell.state;
    const el = h(`<div class="panel">
      <div class="cc-grid">
        ${this.tile("wifi", s.wifi ? "wifi" : "wifiOff", "Wi-Fi", s.wifi ? "Maison" : "Désactivé")}
        ${this.tile("bluetooth", "bluetooth", "Bluetooth", s.bluetooth ? "Activé" : "Désactivé")}
        ${this.tile("dnd", s.dnd ? "bellOff" : "bell", "Concentration", s.dnd ? "Ne pas déranger" : "Désactivé")}
        ${this.tile("theme", s.theme === "dark" ? "moon" : "sun", "Apparence", s.theme === "dark" ? "Sombre" : "Clair", s.theme === "dark")}
      </div>
      <label class="cc-slider">Luminosité<span class="row">${icon("brightness")}<input class="range" type="range" data-k="brightness" value="${s.brightness}"></span></label>
      <label class="cc-slider">Son<span class="row" data-vol-icon>${icon(s.volume ? "volume" : "volumeOff")}<input class="range" type="range" data-k="volume" value="${s.volume}"></span></label>
      <div class="cc-footer"><span>${icon("battery", s.battery)} Batterie ${s.battery} %</span>
        <span style="display:flex;gap:6px"><button class="icon-btn" data-act="settings" title="Paramètres">${icon("sliders")}</button><button class="icon-btn" data-act="power" title="Éteindre">${icon("power")}</button></span></div>
    </div>`);
    el.addEventListener("click", (e) => {
      const t = e.target.closest("[data-tile]");
      if (t) {
        const k = t.dataset.tile;
        if (k === "theme") Shell.set("theme", s.theme === "dark" ? "light" : "dark");
        else Shell.set(k, !s[k]);
        el.replaceWith(this.build()); // re-rendu local
      }
      const a = e.target.closest("[data-act]")?.dataset.act;
      if (a === "settings") { Popover.close(); WM.activate("settings"); }
      if (a === "power") { Popover.close(); toast("Système", "Extinction (simulation)"); }
    });
    el.addEventListener("input", (e) => {
      const k = e.target.dataset.k; if (!k) return;
      Shell.set(k, +e.target.value);
      if (k === "volume") el.querySelector("[data-vol-icon] svg").outerHTML = icon(+e.target.value ? "volume" : "volumeOff");
    });
    return el;
  },
  tile(key, ic, title, sub, on = Shell.state[key]) {
    return `<button class="cc-tile ${on ? "on" : ""}" data-tile="${key}"><span class="dot">${icon(ic)}</span><span><b>${title}</b><small>${sub}</small></span></button>`;
  },
};

// ---------- Calendrier + centre de notifications ----------
const CalendarPanel = {
  offset: 0,
  build() {
    const el = h(`<div class="panel"></div>`);
    const render = () => {
      const now = new Date(), d = new Date(now.getFullYear(), now.getMonth() + this.offset, 1);
      const first = (d.getDay() + 6) % 7, days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
      const prevDays = new Date(d.getFullYear(), d.getMonth(), 0).getDate();
      let cells = "";
      for (let i = 0; i < 42; i++) {
        const n = i - first + 1;
        const muted = n < 1 || n > days;
        const label = n < 1 ? prevDays + n : n > days ? n - days : n;
        const today = !muted && this.offset === 0 && n === now.getDate();
        cells += `<div class="d ${muted ? "muted" : ""} ${today ? "today" : ""}">${label}</div>`;
      }
      const notifs = Shell.state.notifications;
      el.innerHTML = `
        <div class="cal-head"><span>${d.toLocaleDateString("fr-FR", { month: "long", year: "numeric" })}</span>
          <div><button class="icon-btn" data-nav="-1">${icon("chevronL")}</button><button class="icon-btn" data-nav="0" title="Aujourd'hui" style="font-size:11px">•</button><button class="icon-btn" data-nav="1">${icon("chevronR")}</button></div></div>
        <div class="cal-grid">${["L", "M", "M", "J", "V", "S", "D"].map((x) => `<div class="dow">${x}</div>`).join("")}${cells}</div>
        <div class="panel-title"><span>Notifications</span>${notifs.length ? `<button data-clear>Tout effacer</button>` : ""}</div>
        <div class="notif-list">${notifs.length ? notifs.slice().reverse().map((n) => `<div class="notif">${appIcon(n.app)}<div><b>${n.title}</b><small>${n.msg}</small></div></div>`).join("") : `<div class="empty">Aucune notification</div>`}</div>`;
    };
    el.addEventListener("click", (e) => {
      const nav = e.target.closest("[data-nav]");
      if (nav) { this.offset = +nav.dataset.nav === 0 ? 0 : this.offset + +nav.dataset.nav; render(); }
      if (e.target.closest("[data-clear]")) { Shell.state.notifications = []; render(); }
    });
    this.offset = 0; render();
    return el;
  },
};
