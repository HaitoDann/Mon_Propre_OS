// Recherche globale : applications, actions, réglages, fichiers, calcul, web.
// Futur : service de recherche (plugins D-Bus : apps, Tracker/Baloo pour les fichiers).
const Search = {
  sel: 0, items: [],

  init() {
    const input = $("#search");
    $("#launcher").addEventListener("click", (e) => {
      const t = e.target.closest("[data-idx]");
      if (t) this.run(+t.dataset.idx);
      else if (e.target.id === "launcher") this.toggle(false);
    });
    $("#launcher").addEventListener("mousemove", (e) => {
      const t = e.target.closest("[data-idx]");
      if (t && +t.dataset.idx !== this.sel) { this.sel = +t.dataset.idx; this.highlight(); }
    });
    input.addEventListener("input", () => { this.sel = 0; this.render(); });
    input.addEventListener("keydown", (e) => {
      const n = this.items.length || 1, grid = !input.value.trim();
      const step = { ArrowDown: grid ? 6 : 1, ArrowUp: grid ? -6 : -1, ArrowRight: grid ? 1 : 0, ArrowLeft: grid ? -1 : 0 }[e.key];
      if (step) { e.preventDefault(); this.sel = Math.min(n - 1, Math.max(0, this.sel + step)); this.highlight(); }
      if (e.key === "Enter") this.run(this.sel);
    });
  },

  isOpen() { return !$("#launcher").classList.contains("hidden"); },
  toggle(show = !this.isOpen()) {
    if (show && Expose.active) Expose.exit();
    $("#launcher").classList.toggle("hidden", !show);
    if (show) { Popover.close(true); $("#search").value = ""; this.sel = 0; this.render(); $("#search").focus(); }
    else $("#search").blur();
  },

  run(i) {
    const it = this.items[i]; if (!it) return;
    this.toggle(false);
    it.run();
  },

  // Sources de résultats, dans l'ordre d'affichage.
  results(q) {
    const s = Shell.state, nq = norm(q), m = (t) => norm(t).includes(nq);
    const groups = [];

    // Calcul (ex. « 12*4+3 »)
    if (/^[\d\s+\-*/().,%]+$/.test(q) && /[+\-*/%]/.test(q)) {
      try {
        const v = Function(`"use strict";return (${q.replace(/,/g, ".")})`)();
        if (Number.isFinite(v)) {
          const out = (+v.toFixed(10)).toLocaleString("fr-FR");
          groups.push({ title: "Calcul", items: [{ glyph: "equals", label: `= ${out}`, sub: "Entrée pour copier le résultat", run: () => { navigator.clipboard?.writeText(String(v)).catch(() => {}); toast("Calcul", `${out} copié dans le presse-papiers`); } }] });
        }
      } catch {}
    }

    const apps = APPS.filter((a) => m(a.name)).map((a) => ({ app: a, label: a.name, sub: "Application", run: () => WM.activate(a.id) }));
    if (apps.length) groups.push({ title: "Applications", items: apps });

    const actions = [
      { glyph: s.theme === "dark" ? "sun" : "moon", label: s.theme === "dark" ? "Passer en thème clair" : "Passer en thème sombre", kw: "theme mode sombre clair apparence", run: () => Shell.set("theme", s.theme === "dark" ? "light" : "dark") },
      { glyph: "grid", label: "Vue d'ensemble", kw: "expose fenetres espaces bureaux", run: () => Expose.enter() },
      { glyph: "grid", label: "Organiser les fenêtres", kw: "mosaique ranger grille tuiles", run: () => WM.arrange() },
      { glyph: "plus", label: "Nouvel espace de travail", kw: "bureau virtuel workspace", run: () => WM.addWorkspace() },
      { glyph: "lock", label: "Verrouiller l'écran", kw: "session securite", run: () => toast("Session", "Écran verrouillé (simulation)") },
      { glyph: "info", label: "Raccourcis clavier", kw: "aide clavier help", run: () => WM.activate("help") },
    ].filter((a) => m(a.label) || m(a.kw)).map((a) => ({ ...a, sub: "Action" }));
    if (actions.length) groups.push({ title: "Actions", items: actions });

    const settings = [
      { glyph: s.wifi ? "wifi" : "wifiOff", label: `${s.wifi ? "Désactiver" : "Activer"} le Wi-Fi`, kw: "wifi reseau internet", run: () => Shell.set("wifi", !s.wifi) },
      { glyph: "bluetooth", label: `${s.bluetooth ? "Désactiver" : "Activer"} le Bluetooth`, kw: "bluetooth", run: () => Shell.set("bluetooth", !s.bluetooth) },
      { glyph: s.dnd ? "bell" : "bellOff", label: s.dnd ? "Désactiver Ne pas déranger" : "Activer Ne pas déranger", kw: "concentration notifications dnd", run: () => Shell.set("dnd", !s.dnd) },
      { glyph: "image", label: "Fond d'écran", kw: "wallpaper apparence", run: () => WM.activate("settings") },
      { glyph: "sliders", label: "Widgets du bureau", kw: "horloge agenda note", run: () => WM.activate("settings") },
    ].filter((a) => m(a.label) || m(a.kw)).map((a) => ({ ...a, sub: "Réglage" }));
    if (settings.length) groups.push({ title: "Réglages", items: settings });

    const files = FILES.filter((f) => m(f.name)).map((f) => ({ glyph: f.glyph, label: f.name, sub: f.where, run: () => WM.activate(f.app) }));
    if (files.length) groups.push({ title: "Fichiers", items: files });

    groups.push({ title: "Web", items: [{ glyph: "globe", label: `Rechercher « ${q} » sur le web`, sub: "Firefox", run: () => WM.activate("firefox") }] });
    return groups;
  },

  render() {
    const q = $("#search").value.trim(), box = $("#search-results");
    if (!q) {
      this.items = APPS.map((a) => ({ app: a, label: a.name, run: () => WM.activate(a.id) }));
      box.className = "app-grid";
      box.innerHTML = this.items.map((it, i) => `<button class="app-tile" data-idx="${i}">${appIcon(it.app)}<span>${it.label}</span></button>`).join("");
    } else {
      const groups = this.results(q);
      this.items = groups.flatMap((g) => g.items);
      let i = 0;
      box.className = "result-list";
      box.innerHTML = groups.map((g) => `<div class="res-group">${g.title}</div>` + g.items.map((it) => {
        const ic = it.app ? appIcon(it.app) : `<span class="res-ic">${icon(it.glyph)}</span>`;
        return `<button class="res-item" data-idx="${i++}">${ic}<span class="res-text"><b>${it.label}</b><small>${it.sub || ""}</small></span><span class="res-enter">↵</span></button>`;
      }).join("")).join("");
    }
    this.sel = Math.min(this.sel, this.items.length - 1);
    this.highlight();
  },

  highlight() {
    $$("[data-idx]", $("#search-results")).forEach((el) => el.classList.toggle("sel", +el.dataset.idx === this.sel));
    $(`#search-results [data-idx="${this.sel}"]`)?.scrollIntoView({ block: "nearest" });
  },
};
