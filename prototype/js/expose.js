// Vue d'ensemble (Exposé) : fenêtres de l'espace courant en mosaïque + barre des espaces.
// Glisser une fenêtre sur une vignette la déplace vers cet espace.
// Futur : effet KWin (Overview) piloté par le shell, vignettes en QML.
const Expose = {
  active: false,

  toggle() { this.active ? this.exit() : this.enter(); },

  enter() {
    if (this.active) return;
    Popover.close(true);
    if (Search.isOpen()) Search.toggle(false);
    this.active = true;
    document.body.classList.add("expose");
    this.refresh();
  },

  exit(focusWin) {
    if (!this.active) return;
    this.active = false;
    document.body.classList.remove("expose");
    WM.windows.forEach((w) => (w.el.style.transform = ""));
    $("#expose-labels").innerHTML = "";
    setTimeout(() => !this.active && WM.windows.forEach((w) => w.el.classList.remove("exposing")), 320);
    if (focusWin) WM.focus(focusWin);
  },

  refresh() { this.renderStrip(); this.layout(); },

  layout() {
    const wins = WM.visible();
    const top = TOPBAR_H + 150, bottom = Shell.state.dockSize + 40;
    const area = { x: 48, y: top, w: innerWidth - 96, h: innerHeight - top - bottom };
    const labels = $("#expose-labels");
    labels.innerHTML = wins.length ? "" : `<div class="expose-empty">Aucune fenêtre sur ce bureau</div>`;
    const n = wins.length; if (!n) return;
    const cols = Math.ceil(Math.sqrt(n * (area.w / area.h) / 1.6)), rows = Math.ceil(n / cols);
    const cw = area.w / cols, ch = area.h / rows;
    wins.forEach((w, i) => {
      const row = Math.floor(i / cols), col = i % cols;
      const inRow = row === rows - 1 ? n - row * cols : cols;
      const cx = area.x + (cols - inRow) * cw / 2 + col * cw + cw / 2;
      const cy = area.y + row * ch + ch / 2 - 12;
      const r = WM.rectOf(w);
      const s = Math.min((cw - 40) / r.w, (ch - 56) / r.h, 1);
      w.el.classList.add("exposing");
      w.el.style.transformOrigin = "0 0";
      w.el.style.transform = `translate(${cx - (r.w * s) / 2 - r.x}px, ${cy - (r.h * s) / 2 - r.y}px) scale(${s})`;
      const app = appById(w.appId);
      labels.appendChild(h(`<div class="expose-label" style="left:${cx}px;top:${cy + (r.h * s) / 2 + 10}px">${appIcon(app)}<span>${app.name}</span></div>`));
    });
  },

  renderStrip() {
    const strip = $("#ws-strip");
    strip.innerHTML = "";
    for (let i = 0; i < WM.ws.count; i++) {
      const minis = WM.windows.filter((w) => w.ws === i && !w.minimized).map((w) => {
        const r = WM.rectOf(w), app = appById(w.appId);
        return `<i style="left:${(r.x / innerWidth) * 100}%;top:${(r.y / innerHeight) * 100}%;width:${(r.w / innerWidth) * 100}%;height:${(r.h / innerHeight) * 100}%;background:linear-gradient(160deg,${app.colors[0]},${app.colors[1]})"></i>`;
      }).join("");
      const t = h(`<button class="ws-thumb ${i === WM.ws.current ? "on" : ""}" data-ws="${i}"><div class="mini">${minis}</div><span>Bureau ${i + 1}</span></button>`);
      t.onclick = () => { WM.switchWorkspace(i); this.refresh(); };
      strip.appendChild(t);
    }
    if (WM.ws.count < 6) {
      const add = h(`<button class="ws-add" title="Nouvel espace de travail">${icon("plus")}</button>`);
      add.onclick = () => { WM.addWorkspace(); this.refresh(); };
      strip.appendChild(add);
    }
  },

  // Clic : sélectionne la fenêtre ; glisser : la déplace vers un autre espace.
  onWindowPointer(win, e) {
    e.preventDefault();
    const base = win.el.style.transform;
    let moved = false;
    const move = (ev) => {
      const dx = ev.clientX - e.clientX, dy = ev.clientY - e.clientY;
      if (!moved && Math.hypot(dx, dy) < 5) return;
      moved = true;
      win.el.classList.add("expose-drag");
      win.el.style.transform = `translate(${dx}px, ${dy}px) ${base}`;
      const t = document.elementFromPoint(ev.clientX, ev.clientY)?.closest(".ws-thumb");
      $$(".ws-thumb").forEach((x) => x.classList.toggle("drop", x === t));
    };
    const up = () => {
      removeEventListener("pointermove", move); removeEventListener("pointerup", up);
      win.el.classList.remove("expose-drag");
      if (!moved) return this.exit(win);
      const t = $(".ws-thumb.drop");
      if (t) { WM.moveToWorkspace(win, +t.dataset.ws); win.el.style.transform = ""; }
      this.refresh();
    };
    addEventListener("pointermove", move); addEventListener("pointerup", up);
  },
};
