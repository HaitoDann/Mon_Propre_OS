// Popovers : un seul ouvert à la fois, fermeture au clic extérieur ou Échap.
// Futur : composant Popup.qml partagé.
const Popover = {
  current: null,

  open(anchor, content, { align = "left", onClose } = {}) {
    this.close(true);
    const el = h(`<div class="popover"></div>`);
    typeof content === "string" ? (el.innerHTML = content) : el.appendChild(content);
    $("#desktop").appendChild(el);
    const r = anchor.getBoundingClientRect();
    const top = r.bottom + 6;
    let left = align === "right" ? r.right - el.offsetWidth : r.left;
    left = Math.max(8, Math.min(left, innerWidth - el.offsetWidth - 8));
    Object.assign(el.style, { top: top + "px", left: left + "px" });
    anchor.classList.add("open");
    this.current = { el, anchor, onClose };
    return el;
  },

  close(immediate = false) {
    const c = this.current; if (!c) return;
    this.current = null;
    c.anchor.classList.remove("open");
    c.onClose?.();
    if (immediate) c.el.remove();
    else { c.el.classList.add("closing"); setTimeout(() => c.el.remove(), 100); }
  },

  isOpenFor(anchor) { return this.current?.anchor === anchor; },
};

// Menu : items = [{ label, kbd, action, disabled, checked, icon } | "-" | { header }]
function buildMenu(items) {
  const el = h(`<div class="menu" role="menu"></div>`);
  items.forEach((it) => {
    if (it === "-") return el.appendChild(h(`<div class="menu-sep"></div>`));
    if (it.header) return el.appendChild(h(`<div class="menu-header">${it.header}</div>`));
    const b = h(`<button class="menu-item" role="menuitem" ${it.disabled ? "disabled" : ""}>
      ${it.checked !== undefined ? `<span class="check">${it.checked ? icon("check") : ""}</span>` : ""}
      ${it.icon ? icon(it.icon) : ""}<span>${it.label}</span>${it.kbd ? `<span class="kbd">${it.kbd}</span>` : ""}</button>`);
    b.onclick = () => { Popover.close(); it.action?.(); };
    el.appendChild(b);
  });
  return el;
}

document.addEventListener("pointerdown", (e) => {
  const c = Popover.current;
  if (c && !c.el.contains(e.target) && !c.anchor.contains(e.target)) Popover.close();
});
document.addEventListener("keydown", (e) => { if (e.key === "Escape") Popover.close(); });
