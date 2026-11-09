// Lanceur d'applications (deviendra la recherche globale au lot 2).
const Launcher = {
  sel: 0,
  init() {
    $("#launcher").addEventListener("click", (e) => {
      const t = e.target.closest(".app-tile");
      if (t) { WM.activate(t.dataset.id); this.toggle(false); }
      else if (e.target.id === "launcher") this.toggle(false);
    });
    $("#search").addEventListener("input", () => { this.sel = 0; this.render(); });
    $("#search").addEventListener("keydown", (e) => {
      const list = this.render(), n = list.length || 1;
      if (["ArrowRight", "ArrowDown"].includes(e.key)) { this.sel = (this.sel + 1) % n; e.preventDefault(); }
      if (["ArrowLeft", "ArrowUp"].includes(e.key)) { this.sel = (this.sel - 1 + n) % n; e.preventDefault(); }
      if (e.key === "Enter" && list[this.sel]) { WM.activate(list[this.sel].id); this.toggle(false); }
      this.render();
    });
  },
  isOpen() { return !$("#launcher").classList.contains("hidden"); },
  toggle(show = !this.isOpen()) {
    $("#launcher").classList.toggle("hidden", !show);
    if (show) { Popover.close(true); $("#search").value = ""; this.sel = 0; this.render(); $("#search").focus(); }
  },
  render() {
    const q = $("#search").value.trim().toLowerCase();
    const list = APPS.filter((a) => a.name.toLowerCase().includes(q));
    this.sel = Math.min(this.sel, Math.max(0, list.length - 1));
    $("#app-grid").innerHTML = list.map((a, i) => `<button class="app-tile ${i === this.sel ? "sel" : ""}" data-id="${a.id}">${appIcon(a)}${a.name}</button>`).join("")
      || `<div class="empty" style="grid-column:1/-1">Aucun résultat</div>`;
    return list;
  },
};
