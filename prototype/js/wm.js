// Gestionnaire de fenêtres simulé. Dans l'OS réel, ce rôle est tenu par KWin :
// magnétisme, tuiles, espaces de travail et Exposé y seront des scripts/effets KWin
// pilotés par le shell. Cette maquette fige le comportement attendu.
const MIN_W = 360, MIN_H = 220;

const WM = {
  windows: [],          // { id, appId, el, ws, state, minimized, prev }
  z: 10, seq: 0, GAP: 8,
  ws: { count: 3, current: 0 },

  // ---------- Géométrie ----------
  workArea() { return { x: 0, y: TOPBAR_H, w: innerWidth, h: innerHeight - TOPBAR_H - (Shell.state.dockSize + 26) }; },
  rectOf(win) { const s = win.el.style; return { x: parseFloat(s.left), y: parseFloat(s.top), w: parseFloat(s.width), h: parseFloat(s.height) }; },
  setRect(win, r, animate = false) {
    if (animate) {
      win.el.classList.add("animating");
      clearTimeout(win._anim);
      win._anim = setTimeout(() => win.el.classList.remove("animating"), 280);
    }
    Object.assign(win.el.style, { left: r.x + "px", top: r.y + "px", width: r.w + "px", height: r.h + "px" });
  },
  setState(win, state) { win.state = state; win.el.dataset.state = state; },

  // Zones de magnétisme : moitiés, quarts, agrandi (avec marge régulière).
  zoneRect(zone) {
    const a = this.workArea(), g = this.GAP;
    const L = a.x + g, T = a.y + g, W = a.w - 2 * g, H = a.h - 2 * g;
    const hw = (W - g) / 2, hh = (H - g) / 2;
    return {
      max: { x: L, y: T, w: W, h: H },
      left: { x: L, y: T, w: hw, h: H },
      right: { x: L + hw + g, y: T, w: hw, h: H },
      tl: { x: L, y: T, w: hw, h: hh },
      tr: { x: L + hw + g, y: T, w: hw, h: hh },
      bl: { x: L, y: T + hh + g, w: hw, h: hh },
      br: { x: L + hw + g, y: T + hh + g, w: hw, h: hh },
    }[zone];
  },
  snapZone(x, y) {
    const E = 8, corner = innerHeight * 0.22;
    if (x <= E) return y < TOPBAR_H + corner ? "tl" : y > innerHeight - corner ? "bl" : "left";
    if (x >= innerWidth - E) return y < TOPBAR_H + corner ? "tr" : y > innerHeight - corner ? "br" : "right";
    if (y <= TOPBAR_H + 2) return "max";
    return null;
  },

  // ---------- Requêtes ----------
  onCurrent() { return this.windows.filter((w) => w.ws === this.ws.current); },
  visible() { return this.onCurrent().filter((w) => !w.minimized); },
  ofApp(appId) { return this.windows.filter((w) => w.appId === appId); },
  focused() { return this.visible().sort((a, b) => b.el.style.zIndex - a.el.style.zIndex)[0] || null; },

  // ---------- Cycle de vie ----------
  // Clic sur une app : la crée, la ramène, ou la réduit si elle est déjà au premier plan.
  activate(appId) {
    const list = this.ofApp(appId);
    if (!list.length) return this.create(appId);
    let here = list.filter((w) => w.ws === this.ws.current);
    if (!here.length) { this.switchWorkspace(list[0].ws); here = list.filter((w) => w.ws === this.ws.current); }
    const f = this.focused();
    if (here.length === 1 && f === here[0]) return this.minimize(f);
    here.forEach((w) => w.minimized && this.restore(w));
    this.focus(here[here.length - 1]);
  },

  create(appId) {
    const app = appById(appId);
    const id = "w" + ++this.seq;
    const a = this.workArea();
    const W = Math.min(880, a.w - 80), H = Math.min(560, a.h - 40);
    const off = (this.onCurrent().length % 6) * 26;
    const el = h(`<section class="window" data-id="${id}" data-state="normal" role="dialog" aria-label="${app.name}">
      <div class="titlebar">
        <div class="wctl">
          <button class="wbtn close" title="Fermer (Ctrl+W)">${icon("close")}</button>
          <button class="wbtn min" title="Réduire (Ctrl+Maj+↓)">${icon("minus")}</button>
          <button class="wbtn max" title="Plein écran (Ctrl+Maj+F)">${icon("expand")}</button>
        </div>
        <div class="title">${app.name}</div>
      </div>
      <div class="content">${appContent(app)}</div></section>`);
    const win = { id, appId, el, ws: this.ws.current, state: "normal", minimized: false };
    this.setRect(win, { x: Math.max(8, (a.w - W) / 2 - 60 + off), y: a.y + 24 + off, w: W, h: H });

    el.querySelector(".close").onclick = (e) => { e.stopPropagation(); this.close(win); };
    el.querySelector(".min").onclick = (e) => { e.stopPropagation(); this.minimize(win); };
    el.querySelector(".max").onclick = (e) => { e.stopPropagation(); this.toggleFullscreen(win); };
    const bar = el.querySelector(".titlebar");
    bar.ondblclick = (e) => { if (!e.target.closest(".wctl")) this.toggleMaximize(win); };
    bar.addEventListener("contextmenu", (e) => { e.preventDefault(); this.focus(win); Popover.openAt(e.clientX, e.clientY, buildMenu(this.windowMenu(win))); });
    el.addEventListener("pointerdown", (e) => (Expose.active ? Expose.onWindowPointer(win, e) : this.focus(win)));
    this.makeDraggable(win);
    this.makeResizable(win);
    $("#windows").appendChild(el);
    this.windows.push(win);
    this.focus(win);
    return win;
  },

  close(win) {
    if (win.state === "full") this.setFullscreenMode(false);
    win.el.classList.add("closing");
    this.windows = this.windows.filter((w) => w !== win);
    setTimeout(() => win.el.remove(), 160);
    Shell.emit("windows");
  },
  closeApp(appId) { this.ofApp(appId).forEach((w) => this.close(w)); },

  focus(win) {
    if (win.ws !== this.ws.current) this.switchWorkspace(win.ws);
    this.windows.forEach((w) => w.el.classList.toggle("focused", w === win));
    win.el.style.zIndex = ++this.z;
    Shell.emit("windows");
  },

  // Réduction animée vers l'icône du dock.
  minimize(win) {
    if (win.state === "full") { this.setFullscreenMode(false); this.restoreNormal(win, false); }
    const target = $(`.dock-item[data-app="${win.appId}"]`);
    const r = win.el.getBoundingClientRect(), t = target?.getBoundingClientRect();
    const finish = () => { win.minimized = true; win.el.classList.add("minimized"); Shell.emit("windows"); };
    if (!t) return finish();
    const dx = t.left + t.width / 2 - (r.left + r.width / 2), dy = t.top - (r.top + r.height / 2);
    win.el.animate([{ transform: "none", opacity: 1 }, { transform: `translate(${dx}px, ${dy}px) scale(.08)`, opacity: 0 }],
      { duration: 320, easing: "cubic-bezier(.4,0,.6,1)" }).onfinish = finish;
  },
  restore(win) {
    win.minimized = false;
    win.el.classList.remove("minimized");
    win.el.animate([{ transform: "translateY(40px) scale(.9)", opacity: 0 }, { transform: "none", opacity: 1 }], { duration: 260, easing: "cubic-bezier(.2,.8,.2,1)" });
    this.focus(win);
  },

  // ---------- États : normal, tuiles, agrandi, plein écran ----------
  tile(win, zone) {
    if (win.state === "full") this.setFullscreenMode(false);
    if (win.state === "normal") win.prev = this.rectOf(win);
    this.setRect(win, this.zoneRect(zone), true);
    this.setState(win, zone);
    this.focus(win);
  },
  restoreNormal(win, animate = true, rect) {
    if (win.state === "full") this.setFullscreenMode(false);
    this.setRect(win, rect || win.prev || this.rectOf(win), animate);
    this.setState(win, "normal");
    Shell.emit("windows");
  },
  toggleMaximize(win) { win.state === "max" ? this.restoreNormal(win) : this.tile(win, "max"); },
  toggleFullscreen(win) {
    if (win.state === "full") return this.restoreNormal(win);
    if (win.state === "normal") win.prev = this.rectOf(win);
    this.setFullscreenMode(true);
    this.setRect(win, { x: 0, y: 0, w: innerWidth, h: innerHeight }, true);
    this.setState(win, "full");
    this.focus(win);
  },
  setFullscreenMode(on) { document.body.classList.toggle("fullscreen", on); },

  // Mosaïque automatique des fenêtres de l'espace courant.
  arrange() {
    const wins = this.visible(); if (!wins.length) return;
    const a = this.workArea(), g = this.GAP;
    const cols = Math.ceil(Math.sqrt(wins.length)), rows = Math.ceil(wins.length / cols);
    const cw = (a.w - g * (cols + 1)) / cols, ch = (a.h - g * (rows + 1)) / rows;
    wins.forEach((w, i) => {
      if (w.state === "full") this.setFullscreenMode(false);
      if (w.state === "normal") w.prev = this.rectOf(w);
      this.setRect(w, { x: g + (i % cols) * (cw + g), y: a.y + g + Math.floor(i / cols) * (ch + g), w: cw, h: ch }, true);
      this.setState(w, "grid");
    });
    Shell.emit("windows");
  },

  // ---------- Espaces de travail ----------
  switchWorkspace(i) {
    if (i < 0 || i >= this.ws.count || i === this.ws.current) return;
    const dir = i > this.ws.current ? 1 : -1;
    this.ws.current = i;
    this.applyWorkspace();
    if (!Expose.active) $("#windows").animate([{ transform: `translateX(${dir * 80}px)`, opacity: 0 }, { transform: "none", opacity: 1 }], { duration: 280, easing: "cubic-bezier(.2,.8,.2,1)" });
    Shell.emit("workspace", { changed: true });
    Shell.emit("windows");
  },
  applyWorkspace() {
    this.windows.forEach((w) => w.el.classList.toggle("offws", w.ws !== this.ws.current));
    this.setFullscreenMode(this.visible().some((w) => w.state === "full"));
  },
  moveToWorkspace(win, i) {
    if (i < 0 || i >= this.ws.count) return;
    win.ws = i;
    this.applyWorkspace();
    Shell.emit("workspace", {});
    Shell.emit("windows");
  },
  addWorkspace() { if (this.ws.count < 6) { this.ws.count++; Shell.emit("workspace", {}); } },

  // Menu d'une fenêtre (clic droit sur la barre de titre, menu Fenêtre).
  windowMenu(win) {
    return [
      { label: "Réduire", kbd: "Ctrl+Maj+↓", action: () => this.minimize(win) },
      { label: win.state === "max" ? "Restaurer" : "Agrandir", kbd: "Ctrl+Maj+↑", action: () => this.toggleMaximize(win) },
      { label: win.state === "full" ? "Quitter le plein écran" : "Plein écran", kbd: "Ctrl+Maj+F", action: () => this.toggleFullscreen(win) },
      "-",
      { label: "Placer à gauche", icon: "splitL", kbd: "Ctrl+Maj+←", action: () => this.tile(win, "left") },
      { label: "Placer à droite", icon: "splitR", kbd: "Ctrl+Maj+→", action: () => this.tile(win, "right") },
      { label: "Organiser les fenêtres", icon: "grid", kbd: "Ctrl+Maj+G", action: () => this.arrange() },
      "-",
      { header: "Déplacer vers" },
      ...Array.from({ length: this.ws.count }, (_, i) => ({ label: `Bureau ${i + 1}`, checked: win.ws === i, disabled: win.ws === i, action: () => this.moveToWorkspace(win, i) })),
      "-",
      { label: "Fermer", kbd: "Ctrl+W", action: () => this.close(win) },
    ];
  },

  // ---------- Interactions pointeur ----------
  makeDraggable(win) {
    const bar = win.el.querySelector(".titlebar");
    bar.addEventListener("pointerdown", (e) => {
      if (Expose.active || e.button !== 0 || e.target.closest(".wctl") || win.state === "full") return;
      const r0 = this.rectOf(win);
      let ox = e.clientX - r0.x, oy = e.clientY - r0.y, moved = false, zone = null;
      const move = (ev) => {
        if (!moved) {
          if (Math.hypot(ev.clientX - e.clientX, ev.clientY - e.clientY) < 4) return;
          moved = true;
          document.body.classList.add("dragging");
          // Une fenêtre en tuile reprend sa taille d'origine sous le pointeur.
          if (win.state !== "normal") {
            const p = win.prev || r0, ratio = ox / r0.w;
            ox = ratio * p.w;
            this.restoreNormal(win, false, { x: ev.clientX - ox, y: ev.clientY - oy, w: p.w, h: p.h });
          }
        }
        win.el.style.left = ev.clientX - ox + "px";
        win.el.style.top = Math.max(TOPBAR_H, ev.clientY - oy) + "px";
        zone = this.snapZone(ev.clientX, ev.clientY);
        SnapPreview.show(zone && this.zoneRect(zone), win);
      };
      const up = () => {
        removeEventListener("pointermove", move); removeEventListener("pointerup", up);
        document.body.classList.remove("dragging");
        SnapPreview.show(null);
        if (zone) this.tile(win, zone);
      };
      addEventListener("pointermove", move); addEventListener("pointerup", up);
    });
  },

  makeResizable(win) {
    ["n", "s", "e", "w", "ne", "nw", "se", "sw"].forEach((d) => {
      const hdl = h(`<div class="rh ${d}"></div>`);
      win.el.appendChild(hdl);
      hdl.addEventListener("pointerdown", (e) => {
        if (Expose.active || win.state === "full" || e.button !== 0) return;
        e.stopPropagation(); e.preventDefault();
        this.focus(win);
        const r = this.rectOf(win);
        document.body.classList.add("dragging");
        const move = (ev) => {
          const dx = ev.clientX - e.clientX, dy = ev.clientY - e.clientY;
          let { x, y, w, h: hh } = r;
          if (d.includes("e")) w = Math.max(MIN_W, r.w + dx);
          if (d.includes("s")) hh = Math.max(MIN_H, r.h + dy);
          if (d.includes("w")) { w = Math.max(MIN_W, r.w - dx); x = r.x + r.w - w; }
          if (d.includes("n")) { hh = Math.max(MIN_H, r.h - dy); y = r.y + r.h - hh; if (y < TOPBAR_H) { hh -= TOPBAR_H - y; y = TOPBAR_H; } }
          this.setRect(win, { x, y, w, h: hh });
          if (win.state !== "normal") this.setState(win, "normal");
        };
        const up = () => { removeEventListener("pointermove", move); removeEventListener("pointerup", up); document.body.classList.remove("dragging"); };
        addEventListener("pointermove", move); addEventListener("pointerup", up);
      });
    });
  },
};

// Aperçu de la zone de magnétisme pendant le déplacement d'une fenêtre.
const SnapPreview = {
  show(rect, win) {
    const el = $("#snap-preview");
    if (!rect) return el.classList.add("hidden");
    Object.assign(el.style, { left: rect.x + "px", top: rect.y + "px", width: rect.w + "px", height: rect.h + "px", zIndex: (+win.el.style.zIndex || 10) - 1 });
    el.classList.remove("hidden");
  },
};
