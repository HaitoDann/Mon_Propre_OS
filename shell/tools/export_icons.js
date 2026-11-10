// Exporte le jeu d'icônes de la maquette (prototype/js/icons.js) en fichiers SVG
// dans branding/icons/. Usage : node shell/tools/export_icons.js
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = path.resolve(__dirname, "../..");
const ctx = {};
vm.runInNewContext(fs.readFileSync(path.join(root, "prototype/js/icons.js"), "utf8") + "\nthis.ICONS = ICONS;", ctx);

const out = path.join(root, "branding/icons");
fs.mkdirSync(out, { recursive: true });
let n = 0;
for (const [name, body] of Object.entries(ctx.ICONS)) {
  const inner = typeof body === "function" ? body(80) : body;
  const file = name.replace(/[A-Z]/g, (c) => "-" + c.toLowerCase());
  fs.writeFileSync(path.join(out, file + ".svg"),
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>\n`);
  n++;
}
console.log(`${n} icônes exportées dans branding/icons/`);
