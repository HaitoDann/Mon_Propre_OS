// Maquette interactive du bureau — HTML/CSS/JS pur, sans dépendance.
// Référence UX pour la future implémentation Qt 6 / QML. Ce n'est pas du code de production.

const APPS = [
  { id: "files",    name: "Fichiers",    icon: "📁", color: "#3B82F6", dock: true },
  { id: "firefox",  name: "Firefox",     icon: "🦊", color: "#F97316", dock: true },
  { id: "writer",   name: "Documents",   icon: "📝", color: "#2563EB", dock: true },
  { id: "calc",     name: "Tableur",     icon: "📊", color: "#16A34A", dock: true },
  { id: "mail",     name: "Courrier",    icon: "✉️", color: "#0EA5E9", dock: true },
  { id: "calendar", name: "Calendrier",  icon: "📅", color: "#EF4444", dock: true },
  { id: "store",    name: "Store",       icon: "🛍️", color: "#8B5CF6", dock: true },
  { id: "settings", name: "Paramètres",  icon: "⚙️", color: "#64748B", dock: true },
  { id: "terminal", name: "Terminal",    icon: "⌨️", color: "#111827" },
  { id: "notes",    name: "Notes",       icon: "🗒️", color: "#EAB308" },
  { id: "photos",   name: "Photos",      icon: "🖼️", color: "#EC4899" },
  { id: "music",    name: "Musique",     icon: "🎵", color: "#F43F5E" },
];
const ACCENTS = ["#4F7CFF", "#8B5CF6", "#EC4899", "#F97316", "#16A34A", "#0EA5E9"];

const $ = (s) => document.querySelector(s);
const windows = new Map();
let z = 10, cascade = 0;

/* ---------- Contenu des apps fictives ---------- */
function content(app) {
  switch (app.id) {
    case "firefox":
      return `<div class="browser-bar"><span>‹ ›</span><input value="https://www.debian.org"></div>
        <div class="hero"><h1>Bienvenue</h1><p>Firefox ESR, préinstallé et prêt à l'emploi.</p></div>`;
    case "files":
      return `<div class="files">${[["📁","Documents"],["📁","Téléchargements"],["📁","Images"],["📁","Musique"],["📄","Rapport.odt"],["📊","Budget.ods"],["🖼️","Vacances.jpg"],["📕","Guide.pdf"]]
        .map(([i,n]) => `<div class="file"><div>${i}</div>${n}</div>`).join("")}</div>`;
    case "store": {
      const items = [["Développement","💻","#111827","VS Codium, Git, Docker"],["Gaming","🎮","#16A34A","Steam, Lutris, Heroic"],["Multimédia","🎬","#EC4899","VLC, Kdenlive, OBS"],
        ["Graphisme","🎨","#F97316","GIMP, Inkscape, Krita"],["LibreOffice","📝","#2563EB","Suite bureautique"],["Thunderbird","✉️","#0EA5E9","Messagerie"]];
      return `<div class="store-cats">${["À la une","Packs","Bureautique","Développement","Jeux","Multimédia"].map((c,i)=>`<span class="chip ${i?"":"on"}">${c}</span>`).join("")}</div>
        <div class="store-grid">${items.map(([n,i,c,d]) => `<div class="card"><div class="ic" style="background:${c}">${i}</div><div><b>${n}</b><small>${d}</small></div><button class="btn" data-install="${n}">Obtenir</button></div>`).join("")}</div>`;
    }
    case "settings":
      return `<p><b>Paramètres</b> — à concevoir (Phase 4). Utilisez le centre de contrôle pour tester l'apparence.</p>`;
    default:
      return `<p style="color:var(--text-dim)">${app.name} — application de démonstration.</p>`;
  }
}

/* ---------- Fenêtres ---------- */
function openApp(id) {
  const app = APPS.find((a) => a.id === id);
  if (windows.has(id)) { const w = windows.get(id); w.classList.remove("minimized"); focus(w); return; }
  const w = document.createElement("div");
  w.className = "window";
  const W = Math.min(820, innerWidth - 40), H = Math.min(520, innerHeight - 160);
  const off = (cascade++ % 6) * 28;
  Object.assign(w.style, { width: W + "px", height: H + "px", left: Math.max(10, (innerWidth - W) / 2 - 80 + off) + "px", top: 60 + off + "px" });
  w.innerHTML = `<div class="titlebar"><button class="wbtn close" title="Fermer"></button><button class="wbtn min" title="Réduire"></button><button class="wbtn max" title="Agrandir"></button><span class="title">${app.name}</span></div>
    <div class="content">${content(app)}</div>`;
  w.dataset.app = id;
  w.querySelector(".close").onclick = (e) => { e.stopPropagation(); closeApp(id); };
  w.querySelector(".min").onclick = (e) => { e.stopPropagation(); w.classList.add("minimized"); updateActive(); };
  w.querySelector(".max").onclick = (e) => { e.stopPropagation(); toggleMax(w); };
  w.querySelector(".titlebar").ondblclick = () => toggleMax(w);
  w.addEventListener("mousedown", () => focus(w));
  drag(w);
  $("#windows").appendChild(w);
  windows.set(id, w);
  focus(w);
  renderDock();
}
function closeApp(id) {
  const w = windows.get(id); if (!w) return;
  w.classList.add("closing");
  windows.delete(id);
  setTimeout(() => { w.remove(); updateActive(); }, 130);
  renderDock();
}
function focus(w) {
  document.querySelectorAll(".window").forEach((x) => x.classList.remove("focused"));
  w.classList.add("focused"); w.style.zIndex = ++z; updateActive();
}
function toggleMax(w) {
  if (w.dataset.prev) { Object.assign(w.style, JSON.parse(w.dataset.prev)); delete w.dataset.prev; return; }
  w.dataset.prev = JSON.stringify({ left: w.style.left, top: w.style.top, width: w.style.width, height: w.style.height });
  Object.assign(w.style, { left: "0px", top: "32px", width: innerWidth + "px", height: innerHeight - 32 - 90 + "px" });
}
function drag(w) {
  const bar = w.querySelector(".titlebar");
  bar.addEventListener("pointerdown", (e) => {
    if (e.target.classList.contains("wbtn")) return;
    const sx = e.clientX - w.offsetLeft, sy = e.clientY - w.offsetTop;
    const move = (ev) => { w.style.left = ev.clientX - sx + "px"; w.style.top = Math.max(32, ev.clientY - sy) + "px"; };
    const up = () => { removeEventListener("pointermove", move); removeEventListener("pointerup", up); };
    addEventListener("pointermove", move); addEventListener("pointerup", up);
  });
}
function updateActive() {
  const f = [...windows.values()].filter((w) => !w.classList.contains("minimized")).sort((a, b) => b.style.zIndex - a.style.zIndex)[0];
  $("#active-app").textContent = f ? APPS.find((a) => a.id === f.dataset.app).name : "Bureau";
}

/* ---------- Dock (avec effet d'agrandissement) ---------- */
function renderDock() {
  const dock = $("#dock");
  const items = APPS.filter((a) => a.dock);
  dock.innerHTML = "";
  items.forEach((a, i) => {
    if (a.id === "store") dock.insertAdjacentHTML("beforeend", `<div class="dock-sep"></div>`);
    const b = document.createElement("button");
    b.className = "dock-item" + (windows.has(a.id) ? " running" : "");
    b.style.background = a.color;
    b.innerHTML = `${a.icon}<span class="tip">${a.name}</span>`;
    b.onclick = () => openApp(a.id);
    dock.appendChild(b);
  });
}
$("#dock").addEventListener("mousemove", (e) => {
  if (innerWidth < 640) return;
  document.querySelectorAll(".dock-item").forEach((el) => {
    const r = el.getBoundingClientRect();
    const d = Math.abs(e.clientX - (r.left + r.width / 2));
    const s = 50 + Math.max(0, 22 * (1 - d / 140));
    el.style.width = el.style.height = s + "px";
  });
});
$("#dock").addEventListener("mouseleave", () => document.querySelectorAll(".dock-item").forEach((el) => (el.style.width = el.style.height = "")));

/* ---------- Lanceur ---------- */
let sel = 0;
function renderGrid() {
  const q = $("#search").value.trim().toLowerCase();
  const list = APPS.filter((a) => a.name.toLowerCase().includes(q));
  sel = Math.min(sel, Math.max(0, list.length - 1));
  $("#app-grid").innerHTML = list.map((a, i) => `<button class="app-tile ${i === sel ? "sel" : ""}" data-id="${a.id}"><div class="ic" style="background:${a.color}">${a.icon}</div>${a.name}</button>`).join("")
    || `<p style="color:var(--text-dim);grid-column:1/-1">Aucun résultat</p>`;
  return list;
}
function toggleLauncher(show = $("#launcher").classList.contains("hidden")) {
  $("#launcher").classList.toggle("hidden", !show);
  if (show) { $("#control").classList.add("hidden"); $("#search").value = ""; sel = 0; renderGrid(); setTimeout(() => $("#search").focus(), 50); }
}
$("#btn-launcher").onclick = () => toggleLauncher();
$("#launcher").addEventListener("click", (e) => {
  const t = e.target.closest(".app-tile");
  if (t) { openApp(t.dataset.id); toggleLauncher(false); }
  else if (e.target.id === "launcher") toggleLauncher(false);
});
$("#search").addEventListener("input", () => { sel = 0; renderGrid(); });
$("#search").addEventListener("keydown", (e) => {
  const list = renderGrid();
  if (e.key === "ArrowRight" || e.key === "ArrowDown") { sel = (sel + 1) % list.length; renderGrid(); e.preventDefault(); }
  if (e.key === "ArrowLeft" || e.key === "ArrowUp") { sel = (sel - 1 + list.length) % list.length; renderGrid(); e.preventDefault(); }
  if (e.key === "Enter" && list[sel]) { openApp(list[sel].id); toggleLauncher(false); }
});
addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.code === "Space") { e.preventDefault(); toggleLauncher(); }
  if (e.key === "Escape") { toggleLauncher(false); $("#control").classList.add("hidden"); }
});

/* ---------- Centre de contrôle, thème, accent ---------- */
$("#btn-control").onclick = (e) => { e.stopPropagation(); $("#control").classList.toggle("hidden"); };
$("#desktop").addEventListener("mousedown", (e) => { if (!e.target.closest("#control, #btn-control")) $("#control").classList.add("hidden"); });
document.querySelectorAll("[data-toggle]").forEach((t) => (t.onclick = () => t.classList.toggle("on")));
const toggleTheme = () => { const r = document.documentElement; r.dataset.theme = r.dataset.theme === "dark" ? "light" : "dark"; $("#tile-dark").classList.toggle("on", r.dataset.theme === "dark"); };
$("#btn-theme").onclick = toggleTheme;
$("#tile-dark").onclick = toggleTheme;
$("#accents").innerHTML = ACCENTS.map((c, i) => `<button class="sw ${i ? "" : "on"}" style="background:${c}" data-c="${c}"></button>`).join("");
$("#accents").onclick = (e) => {
  const c = e.target.dataset.c; if (!c) return;
  document.documentElement.style.setProperty("--accent", c);
  document.querySelectorAll(".sw").forEach((s) => s.classList.toggle("on", s.dataset.c === c));
};

/* ---------- Store : installation fictive + notification ---------- */
document.addEventListener("click", (e) => {
  const b = e.target.closest("[data-install]"); if (!b || b.classList.contains("done")) return;
  b.textContent = "…";
  setTimeout(() => { b.textContent = "Installé"; b.classList.add("done"); toast("Store", `${b.dataset.install} a été installé.`); }, 900);
});
function toast(title, msg) {
  const t = document.createElement("div");
  t.className = "toast";
  t.innerHTML = `<span>🔔</span><div><b>${title}</b><small>${msg}</small></div>`;
  $("#toasts").appendChild(t);
  setTimeout(() => t.remove(), 4000);
}

/* ---------- Horloge ---------- */
function tick() { $("#clock").textContent = new Date().toLocaleString("fr-FR", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }); }
tick(); setInterval(tick, 10000);

renderDock();
setTimeout(() => toast("Bienvenue", "Votre système est prêt. Ctrl+Espace pour rechercher."), 600);
