// Drawing helpers for the tr-1ci pages. Every picture is the game's 640x360 base drawn x2.
// OPT (set by each page before this loads): { rows: "plain" | "knobbed", slot: "slot_inset.png" | "slot_raised.png" }
const A = "../../../assets/", R = "../ui-revamp/";
const SRC = {
  tiles: A + "beach/tiles.png", driftwood: A + "beach/driftwood.png", spring: A + "beach/spring.png",
  rocks: A + "pixel_crawler/Environment/Props/Static/Rocks.png", veg: A + "pixel_crawler/Environment/Props/Static/Vegetation.png",
  floors: A + "pixel_crawler/Environment/Tilesets/Floors_Tiles.png", man: A + "man/idle.png",
  waves: "../vendor-art-swap/waves_warm.png", fPalms: A + "farming_101/beach/palm trees.png", fShells: A + "farming_101/beach/seashells.png",
  fGrass: A + "farming_101/beach/beach grass.png", fRocks: A + "farming_101/beach/ocean rocks.png", fCrab: A + "farming_101/beach/crab.png",
  fCoconuts: A + "farming_101/beach/coconuts.png",
  iCoconut: A + "items/coconut.png", iDrift: A + "items/driftwood.png", iShell: A + "items/shellfish.png", iWater: A + "items/fresh_water.png", iEmpty: A + "items/empty_shell.png",
  wSlot: OPT.slot, wFrame: R + "wood_Inventory_9Slices.png",
};
const img = {};
const enc = p => p.split("/").map(s => s == ".." ? s : encodeURIComponent(s)).join("/");
const WOOD_DARK = "#58351e", WOOD = "#865932", WOOD_LIGHT = "#b68c48", SLOT_FACE = "#fee0a1", SLOT_EDGE = "#fff6e4",
  INK = "#301d0e", PALE = "#fff6e4", CREAM = "#fee0a1", DIM = "#c6ab9f", SUN = "#f6cc2b", MOON = "#eff8ff", CAP_SHADOW = "#927e65";

const rect = (g, x, y, w, h, c) => { g.fillStyle = c; g.fillRect(x, y, w, h); };
function text(g, s, x, y, c) { g.font = '8px "PS2P"'; g.textBaseline = "top"; g.fillStyle = c; g.fillText(s, x, y); }
const tw = s => s.length * 8;
function count(g, n, x, y, c, halo) { if (n < 2) return; const s = String(n); g.font = '8px "PS2P"'; g.textBaseline = "top"; g.save(); g.translate(x - s.length * 5, y); g.scale(0.625, 0.625);
  if (halo) { g.fillStyle = halo; for (const [dx, dy] of [[-1.6,0],[1.6,0],[0,-1.6],[0,1.6]]) g.fillText(s, dx, dy); } g.fillStyle = c; g.fillText(s, 0, 0); g.restore(); }
function nine(g, i, m, x, y, w, h, fill) {
  const W = i.width, Hh = i.height, c = W - 2 * m, r = Hh - 2 * m;
  rect(g, x + m, y + m, w - 2 * m, h - 2 * m, fill);
  for (let dx = m; dx < w - m; dx += c) { const n = Math.min(c, w - m - dx); g.drawImage(i, m, 0, n, m, x + dx, y, n, m); g.drawImage(i, m, Hh - m, n, m, x + dx, y + h - m, n, m); }
  for (let dy = m; dy < h - m; dy += r) { const n = Math.min(r, h - m - dy); g.drawImage(i, 0, m, m, n, x, y + dy, m, n); g.drawImage(i, W - m, m, m, n, x + w - m, y + dy, m, n); }
  g.drawImage(i, 0, 0, m, m, x, y, m, m); g.drawImage(i, W - m, 0, m, m, x + w - m, y, m, m);
  g.drawImage(i, 0, Hh - m, m, m, x, y + h - m, m, m); g.drawImage(i, W - m, Hh - m, m, m, x + w - m, y + h - m, m, m);
}
// the knobbed frame, for a board
const frame = (g, x, y, w, h, fill = WOOD) => nine(g, img.wFrame, 6, x, y, w, h, fill);
// the plain two-colour plate (today's plank without its highlight line is the same idea)
function plate(g, x, y, w, h, on) { rect(g, x, y, w, h, on ? PALE : WOOD_DARK); rect(g, x + 1, y + 1, w - 2, h - 2, on ? WOOD_LIGHT : WOOD); }
// a menu row: a plain plate, or its own knobbed frame when OPT.rows == "knobbed"
const ROW_H = () => OPT.rows == "knobbed" ? 22 : 15;
function row(g, x, y, w, words, on, dim) {
  const h = ROW_H();
  if (OPT.rows == "knobbed") { frame(g, x, y, w, h, on ? WOOD_LIGHT : WOOD); if (on) { g.strokeStyle = PALE; g.lineWidth = 1; g.strokeRect(x - 0.5, y - 0.5, w + 1, h + 1); } }
  else plate(g, x, y, w, h, on);
  text(g, words, x + Math.round((w - tw(words)) / 2), y + Math.round((h - 8) / 2), dim ? DIM : on ? INK : CREAM);
}
const ICON = { coconut: "iCoconut", drift: "iDrift", shell: "iShell", water: "iWater", empty: "iEmpty" };
function slot(g, x, y, item, on) {
  g.drawImage(img.wSlot, 5, 5, 22, 22, x, y, 22, 22);
  if (on) { g.strokeStyle = PALE; g.lineWidth = 1; g.strokeRect(x - 0.5, y - 0.5, 23, 23); }
  if (item) { g.drawImage(img[ICON[item[0]]], x + 6, y + 5); count(g, item[1], x + 21, y + 15, INK, SLOT_EDGE); }
}
function bar(g, items, sel, bx = 218, by = 325) {
  frame(g, bx, by, 204, 34);
  for (let i = 0; i < 8; i++) slot(g, bx + 6 + i * 24, by + 6, items[i], i == sel);
}
function nameplate(g, words, x, y) { const w = tw(words) + 8; plate(g, x, y, w, 13); text(g, words, x + 4, y + 3, CREAM); }
function clock(g, night) {
  frame(g, 4, 4, 64, 54);
  text(g, "Day 3", 16, 9, CREAM);
  for (let k = 0; k <= 64; k++) { const a = Math.PI * (1 - k / 64); if (k % 3 == 0) rect(g, 36 + Math.round(Math.cos(a) * 14), 42 - Math.round(Math.sin(a) * 14), 1, 1, CREAM); }
  const a = Math.PI * (1 - (night ? 0.75 : 0.3)); rect(g, 34 + Math.round(Math.cos(a) * 14), 40 - Math.round(Math.sin(a) * 14), 5, 5, night ? MOON : SUN);
}
function keycap(g, k, x, y) { rect(g, x, y + 1, 11, 11, CAP_SHADOW); rect(g, x, y, 11, 11, CREAM); text(g, k, x + 2, y + 2, INK); }
function usePrompt(g, x, y) { plate(g, x, y, 76, 15); keycap(g, "E", x + 3, y + 1); text(g, "Pick up", x + 17, y + 4, CREAM); }
function shade(g, a = 0.45) { g.fillStyle = `rgba(20,12,6,${a})`; g.fillRect(0, 0, 640, 360); }

// the beach agreed as scene E of the art mockup, one still frame
function beach(g) {
  const cam = [92 * 16 + 8 - 320, 11 * 16 + 8 - 180];
  const kind = (x, y) => y <= 8 ? 0 : y >= 18 ? 5 : y <= 13 ? 1 : y == 14 ? 2 : y == 15 ? 3 : 4;
  for (let y = 0; y < 26; y++) for (let x = 70; x < 115; x++) {
    const k = kind(x, y), px = x * 16 - cam[0], py = y * 16 - cam[1];
    if (y == 8) { g.drawImage(img.tiles, 16, 0, 16, 16, px, py, 16, 16); g.drawImage(img.floors, 16 + (x % 3) * 16, 80, 16, 16, px, py, 16, 16); }
    else if (k == 3) { g.drawImage(img.tiles, 64, 0, 16, 16, px, py, 16, 16); g.drawImage(img.waves, 32, 0, 16, 16, px, py, 16, 16); }
    else g.drawImage(img.tiles, k * 16, 0, 16, 16, px, py, 16, 16);
  }
  const at = (c) => [c[0] * 16 + 8 - cam[0], (c[1] + 1) * 16 - cam[1]];
  const reg = (i, r, c, foot, dy = 0) => { const [x, y] = at(c); g.drawImage(i, r[0], r[1], r[2], r[3], Math.round(x - (foot ?? r[2] / 2)), y - r[3] + dy, r[2], r[3]); };
  [[77,8],[90,8],[106,8]].forEach(c => reg(img.veg, [0, 0, 32, 32], c));
  [[74,9],[80,9],[88,9],[94,9],[104,9],[110,9]].forEach((c, n) => reg(img.fGrass, [[0,12,15,17],[16,10,15,20],[33,11,13,17],[50,13,11,15]][n % 4], c));
  reg(img.fPalms, [432, 25, 64, 48], [84, 9], 60, 4); reg(img.fPalms, [342, 16, 31, 56], [101, 9], 16, 4);
  { const [x, y] = at([96, 9]); g.drawImage(img.spring, x - 16, y - 14); }
  [[78,12],[99,13],[108,11]].forEach(c => reg(img.rocks, [160, 16, 16, 16], c));
  [[74,12],[80,13],[88,13],[107,13],[111,13]].forEach(c => { const [x, y] = at(c); g.drawImage(img.driftwood, x - 16, y - 8); });
  reg(img.fShells, [2, 34, 12, 13], [75, 14]); reg(img.fShells, [2, 2, 11, 12], [96, 14]); reg(img.fCrab, [39, 12, 17, 11], [103, 14]);
  reg(img.fCoconuts, [3, 19, 10, 10], [83, 10]);
  g.drawImage(img.man, 0, 0, 64, 64, 288, 12 * 16 - cam[1] - 48, 64, 64);
}

const ITEMS = [["coconut", 3], ["drift", 12], ["shell", 1], ["water", 2], ["empty", 20], null, null, null];
const SCENES = {
  play(g) { beach(g); clock(g); bar(g, ITEMS, 0); nameplate(g, "Coconut", 222, 306); usePrompt(g, 330, 150); },
  playStates(g) { beach(g); shade(g, 0.15); clock(g, true);
    bar(g, ITEMS, 6); nameplate(g, "Empty shell", 318, 306);
    text(g, "Click where to put it.", 232, 290, PALE); },
  pause(g) { beach(g); clock(g); bar(g, ITEMS, 0); shade(g);
    const rows = ["Resume", "Skip story", "Settings", "Debug", "Quit to title"], h = ROW_H(), gap = 3, w = 132;
    const bh = 22 + rows.length * (h + gap) + 8, bx = 320 - (w + 16) / 2, by = 180 - bh / 2;
    frame(g, bx, by, w + 16, bh); text(g, "Paused", 320 - tw("Paused") / 2, by + 8, CREAM);
    rows.forEach((r, i) => row(g, bx + 8, by + 22 + i * (h + gap), w, r, i == 0)); },
  confirm(g) { beach(g); shade(g, 0.6);
    const w = 236, h = OPT.rows == "knobbed" ? 84 : 74, x = 320 - w / 2, y = 180 - h / 2;
    frame(g, x, y, w, h); text(g, "Quit to title?", 320 - tw("Quit to title?") / 2, y + 10, CREAM);
    text(g, "Nothing has been saved yet.", 320 - tw("Nothing has been saved yet.") / 2 * 0.95, y + 28, PALE);
    row(g, x + 22, y + h - ROW_H() - 10, 84, "Stay", true); row(g, x + w - 106, y + h - ROW_H() - 10, 84, "Quit", false); },
  title(g) { rect(g, 0, 0, 640, 360, "#2a6f97"); rect(g, 0, 250, 640, 110, "#e7c485");
    text(g, "TIDE & TIMBER", 320 - tw("TIDE & TIMBER") / 2, 60, CREAM); // drawn x2 below
    g.save(); g.clearRect(0,0,0,0); g.restore();
    text(g, "a story of an island", 320 - tw("a story of an island") / 2, 90, PALE);
    const w = 140, h = ROW_H(), gap = 5; let y = 140;
    row(g, 250, y, w, "Continue", true); text(g, "Day 3", 320 - 20, y + h + 2, PALE); y += h + 14;
    ["New Game", "Settings", "Quit"].forEach(r => { row(g, 250, y, w, r, false); y += h + gap; }); },
  settings(g) { beach(g); shade(g);
    const rows = [["UI size", "Large"], ["Text size", "Normal"], ["Cues", "Standard"], ["Fullscreen", "Off"], ["Controls", ""]];
    const h = ROW_H(), gap = 3, w = 220, bh = 24 + rows.length * (h + gap) + 8, bx = 320 - (w + 16) / 2, by = 180 - bh / 2;
    frame(g, bx, by, w + 16, bh); text(g, "Settings", 320 - tw("Settings") / 2, by + 8, CREAM);
    rows.forEach(([k, v], i) => { const y = by + 24 + i * (h + gap); row(g, bx + 8, y, w, "", i == 0);
      text(g, k, bx + 16, y + Math.round((h - 8) / 2), i == 0 ? INK : CREAM); if (v) text(g, "‹ " + v + " ›", bx + 8 + w - 8 - tw("‹ " + v + " ›"), y + Math.round((h - 8) / 2), i == 0 ? INK : CREAM); }); },
  build(g) { beach(g); clock(g); bar(g, ITEMS, 1);
    const rows = [["Fire pit", "3 drift", true], ["Lean-to", "8 drift", false]], h = ROW_H(), gap = 3, w = 150;
    const bh = 22 + rows.length * (h + gap) + 8, bx = 460, by = 110;
    frame(g, bx, by, w + 16, bh); text(g, "Build", bx + 8, by + 8, CREAM);
    rows.forEach(([n, c, ok], i) => { const y = by + 22 + i * (h + gap); row(g, bx + 8, y, w, "", i == 0);
      text(g, n, bx + 14, y + Math.round((h - 8) / 2), i == 0 ? INK : ok ? CREAM : DIM); text(g, c, bx + 8 + w - 6 - tw(c), y + Math.round((h - 8) / 2), i == 0 ? INK : ok ? CREAM : DIM); }); },
  morning(g) { beach(g); shade(g, 0.3); const w = 200, h = 70, x = 220, y = 120;
    frame(g, x, y, w, h); text(g, "Day 4", 320 - tw("Day 4") / 2, y + 12, CREAM);
    text(g, "You woke by the fire.", 320 - tw("You woke by the fire.") / 2, y + 34, PALE); },
};
// Largest: the same bar and clock at 2x, as the player would see them with the biggest UI size
SCENES.largest = g => { beach(g); g.save(); g.scale(2, 2); clock(g); g.restore();
  g.save(); g.translate(320, 360); g.scale(2, 2); g.translate(-320, -360); bar(g, ITEMS, 0); nameplate(g, "Coconut", 222, 306); g.restore();
  text(g, "Hints lift above the bar", 230, 270, PALE); };

function draw(id, scene) {
  const g = document.getElementById(id).getContext("2d"); g.imageSmoothingEnabled = false; g.scale(2, 2);
  SCENES[scene](g);
}
Promise.all([document.fonts.load('8px "PS2P"'), ...Object.entries(SRC).map(([k, p]) => new Promise((ok, no) => {
  const i = new Image(); i.onload = ok; i.onerror = () => no(p); i.src = enc(p); img[k] = i;
}))]).then(() => document.querySelectorAll("canvas[data-scene]").forEach(c => draw(c.id, c.dataset.scene)))
  .catch(p => document.body.insertAdjacentHTML("afterbegin", "<p style='color:#f88'>could not load " + p + "</p>"));
SCENES.zoom = g => { rect(g, 0, 0, 640, 180, "#e7c485"); g.save(); g.translate(116 - 218 * 2, 56 - 325 * 2); g.scale(2, 2); bar(g, ITEMS, 0); g.restore(); };
