// Dock : épinglées | séparateur | ouvertes non épinglées.
// Agrandissement au survol, indicateurs, infobulles, menu contextuel.
const Dock = {
  el: null, tip: null, RANGE: 150,

  init() {
    this.el = $("#dock");
    this.tip = h(`<div class="dock-tip hidden"></div>`);
    $("#desktop").appendChild(this.tip);
    this.el.addEventListener("mousemove", (e) => this.magnify(e.clientX));
    this.el.addEventListener("mouseleave", () => this.reset());
    Shell.on("windows", () => this.render());
    Shell.on("state", ({ key }) => {
      if (key === "pinned") this.render();
      if (key === "dockSize") this.applySize();
    });
    this.applySize();
    this.render();
  },

  base() { return innerWidth < 760 ? 38 : Shell.state.dockSize; },
  applySize() { document.documentElement.style.setProperty("--dock-icon", this.base() + "px"); },

  render() {
    const pinned = Shell.state.pinned;
    const running = [...new Set(WM.windows.map((w) => w.appId))];
    const extra = running.filter((id) => !pinned.includes(id));
    const before = new Set($$(".dock-item", this.el).map((e) => e.dataset.app));
    this.el.innerHTML = "";
    const add = (id) => {
      const app = appById(id), count = WM.ofApp(id).length;
      const b = h(`<button class="dock-item" data-app="${id}" aria-label="${app.name}">${appIcon(app)}
        <span class="ind">${count ? "<i></i>" : ""}${count > 1 ? "<i></i>" : ""}</span></button>`);
      if (before.size && !before.has(id)) b.classList.add("enter");
      b.onclick = () => { if (!count) this.bounce(b); if (Expose.active) Expose.exit(); WM.activate(id); };
      b.oncontextmenu = (e) => { e.preventDefault(); this.contextMenu(b, id); };
      b.onmouseenter = () => this.showTip(b, app.name);
      b.onmouseleave = () => this.tip.classList.add("hidden");
      this.el.appendChild(b);
    };
    pinned.forEach(add);
    if (extra.length) { this.el.appendChild(h(`<div class="dock-sep"></div>`)); extra.forEach(add); }
  },

  // Agrandissement : taille selon une courbe cosinus de la distance au curseur.
  magnify(x) {
    if (!Shell.state.magnify || innerWidth < 760) return;
    const base = this.base(), max = Math.round(base * 1.45);
    $$(".dock-item", this.el).forEach((it) => {
      it.classList.remove("animate");
      const r = it.getBoundingClientRect();
      const d = Math.abs(x - (r.left + r.width / 2));
      const k = d > this.RANGE ? 0 : (Math.cos((d / this.RANGE) * Math.PI) + 1) / 2;
      it.style.width = it.style.height = base + (max - base) * k + "px";
    });
    if (!this.tip.classList.contains("hidden")) this.placeTip();
  },
  reset() { $$(".dock-item", this.el).forEach((it) => { it.classList.add("animate"); it.style.width = it.style.height = ""; }); },

  showTip(item, text) { this.tip.textContent = text; this.tip._for = item; this.tip.classList.remove("hidden"); this.placeTip(); },
  placeTip() {
    const r = this.tip._for.getBoundingClientRect();
    Object.assign(this.tip.style, { left: r.left + r.width / 2 + "px", top: r.top - 10 + "px" });
  },

  bounce(b) { b.classList.remove("bounce"); void b.offsetWidth; b.classList.add("bounce"); },

  contextMenu(anchor, id) {
    const app = appById(id), wins = WM.ofApp(id), pinned = Shell.state.pinned.includes(id);
    this.tip.classList.add("hidden");
    const items = [];
    if (wins.length) {
      items.push({ header: "Fenêtres" }, ...wins.map((w, i) => ({
        label: `${app.name}${wins.length > 1 ? " " + (i + 1) : ""} — Bureau ${w.ws + 1}`,
        action: () => (w.minimized ? WM.restore(w) : WM.focus(w)),
      })), "-");
    }
    items.push({ label: "Nouvelle fenêtre", action: () => WM.create(id) });
    items.push({ label: pinned ? "Retirer du Dock" : "Garder dans le Dock", action: () => Shell.set("pinned", pinned ? Shell.state.pinned.filter((p) => p !== id) : [...Shell.state.pinned, id]) });
    if (wins.length) items.push("-", { label: "Quitter", action: () => WM.closeApp(id) });
    const pop = Popover.open(anchor, buildMenu(items));
    const r = anchor.getBoundingClientRect();
    pop.style.top = r.top - pop.offsetHeight - 10 + "px";
    pop.style.left = Math.max(8, Math.min(innerWidth - pop.offsetWidth - 8, r.left + r.width / 2 - pop.offsetWidth / 2)) + "px";
    pop.style.transformOrigin = "bottom center";
  },
};
