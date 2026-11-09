// Gestionnaire de fenêtres simulé. Dans l'OS réel, ce rôle est tenu par KWin ;
// le shell ne fait qu'observer/commander les fenêtres (API KWin / protocoles Wayland).
const WM = {
  windows: [],          // { id, appId, el, minimized, maximized, prev }
  z: 10, seq: 0,

  workArea() { return { x: 0, y: parseInt(getComputedStyle(document.documentElement).getPropertyValue("--topbar-h")), w: innerWidth, h: innerHeight - 34 }; },
  ofApp(appId) { return this.windows.filter((w) => w.appId === appId); },
  focused() { return this.windows.filter((w) => !w.minimized).sort((a, b) => b.el.style.zIndex - a.el.style.zIndex)[0] || null; },

  // Ouvre l'app : réactive sa fenêtre si elle existe, sinon en crée une.
  activate(appId) {
    const list = this.ofApp(appId);
    if (!list.length) return this.create(appId);
    const f = this.focused();
    if (list.length === 1 && f === list[0]) return this.minimize(f); // clic sur l'app active = réduire
    list.forEach((w) => w.minimized && this.restore(w));
    this.focus(list[list.length - 1]);
  },

  create(appId) {
    const app = appById(appId);
    const id = "w" + ++this.seq;
    const wa = this.workArea();
    const W = Math.min(860, innerWidth - 40), H = Math.min(540, innerHeight - 180);
    const off = (this.windows.length % 6) * 26;
    const el = h(`<section class="window" data-id="${id}" role="dialog" aria-label="${app.name}">
      <div class="titlebar">
        <div class="wctl">
          <button class="wbtn close" title="Fermer">${icon("close")}</button>
          <button class="wbtn min" title="Réduire">${icon("minus")}</button>
          <button class="wbtn max" title="Plein écran">${icon("expand")}</button>
        </div>
        <div class="title">${app.name}</div>
      </div>
      <div class="content">${appContent(app)}</div></section>`);
    Object.assign(el.style, { width: W + "px", height: H + "px", left: Math.max(8, (innerWidth - W) / 2 - 70 + off) + "px", top: wa.y + 40 + off + "px" });
    const win = { id, appId, el, minimized: false, maximized: false };
    el.querySelector(".close").onclick = (e) => { e.stopPropagation(); this.close(win); };
    el.querySelector(".min").onclick = (e) => { e.stopPropagation(); this.minimize(win); };
    el.querySelector(".max").onclick = (e) => { e.stopPropagation(); this.toggleMaximize(win); };
    el.querySelector(".titlebar").ondblclick = (e) => { if (!e.target.closest(".wctl")) this.toggleMaximize(win); };
    el.addEventListener("pointerdown", () => this.focus(win));
    this.makeDraggable(win);
    $("#windows").appendChild(el);
    this.windows.push(win);
    this.focus(win);
    Shell.emit("windows");
    return win;
  },

  close(win) {
    win.el.classList.add("closing");
    this.windows = this.windows.filter((w) => w !== win);
    setTimeout(() => win.el.remove(), 160);
    Shell.emit("windows");
  },
  closeApp(appId) { this.ofApp(appId).forEach((w) => this.close(w)); },

  focus(win) {
    this.windows.forEach((w) => w.el.classList.toggle("focused", w === win));
    win.el.style.zIndex = ++this.z;
    Shell.emit("windows");
  },

  // Réduction animée vers l'icône du dock (effet « génie » simplifié).
  minimize(win) {
    const target = $(`.dock-item[data-app="${win.appId}"]`);
    const r = win.el.getBoundingClientRect(), t = target?.getBoundingClientRect();
    const finish = () => { win.minimized = true; win.el.classList.add("minimized"); win.el.style.transform = ""; Shell.emit("windows"); };
    if (!t) return finish();
    const dx = t.left + t.width / 2 - (r.left + r.width / 2), dy = t.top - (r.top + r.height / 2);
    win.el.animate([{ transform: "none", opacity: 1 }, { transform: `translate(${dx}px, ${dy}px) scale(.08)`, opacity: 0 }],
      { duration: 300, easing: "cubic-bezier(.4,0,.6,1)" }).onfinish = finish;
  },
  restore(win) {
    win.minimized = false;
    win.el.classList.remove("minimized");
    win.el.animate([{ transform: "translateY(40px) scale(.9)", opacity: 0 }, { transform: "none", opacity: 1 }], { duration: 240, easing: "cubic-bezier(.2,.8,.2,1)" });
    this.focus(win);
  },

  toggleMaximize(win) {
    const s = win.el.style;
    win.el.classList.add("animating");
    setTimeout(() => win.el.classList.remove("animating"), 260);
    if (win.maximized) {
      Object.assign(s, win.prev);
      win.maximized = false;
    } else {
      win.prev = { left: s.left, top: s.top, width: s.width, height: s.height };
      const wa = this.workArea();
      Object.assign(s, { left: "0px", top: wa.y + "px", width: wa.w + "px", height: innerHeight - wa.y + "px" });
      win.maximized = true;
    }
    win.el.classList.toggle("maximized", win.maximized);
    Shell.emit("windows");
  },

  makeDraggable(win) {
    const bar = win.el.querySelector(".titlebar");
    bar.addEventListener("pointerdown", (e) => {
      if (e.target.closest(".wctl") || e.button !== 0) return;
      let sx = e.clientX - win.el.offsetLeft, sy = e.clientY - win.el.offsetTop;
      const move = (ev) => {
        if (win.maximized) { // détacher une fenêtre maximisée en la glissant
          const ratio = (ev.clientX) / innerWidth;
          this.toggleMaximize(win);
          win.el.classList.remove("animating");
          sx = parseInt(win.prev?.width || win.el.style.width) * ratio; sy = 18;
        }
        win.el.style.left = ev.clientX - sx + "px";
        win.el.style.top = Math.max(this.workArea().y, ev.clientY - sy) + "px";
      };
      const up = () => { removeEventListener("pointermove", move); removeEventListener("pointerup", up); };
      addEventListener("pointermove", move); addEventListener("pointerup", up);
    });
  },
};
