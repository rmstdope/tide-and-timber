// Drawing only. Redraws the beach around the spawn at the game's 640x360 base, reading the sprites
// straight from assets/. Each page sets window.V before loading this file:
//   spread: "wide" (the agreed placement) | "loose" | false
const V = Object.assign({ palette: "own", shells: "four", crab: "still", wash: false, spread: false, man: null }, window.V || {});
const A = "../../../assets/";
const R = V.palette == "recolour" ? "_recolour" : "";
const SRC = {
  tiles: "beach/tiles.png", driftwood: "beach/driftwood.png", spring: "beach/spring.png",
  rocks: "pixel_crawler/Environment/Props/Static/Rocks.png", veg: "pixel_crawler/Environment/Props/Static/Vegetation.png",
  man: "man/idle.png", warmWaves: "../docs/ui/vendor-art-swap/waves_warm.png",
  edge: "../docs/ui/tr-cfq-beach/art/edge.png",
  fPalms: "../docs/ui/tr-cfq-beach/art/palms" + (R || "_own") + ".png",
  fCoconuts: R ? "../docs/ui/tr-cfq-beach/art/coconuts_recolour.png" : "farming_101/beach/coconuts.png",
  fShells: R ? "../docs/ui/tr-cfq-beach/art/shells_recolour.png" : "farming_101/beach/seashells.png",
  fGrass: R ? "../docs/ui/tr-cfq-beach/art/grass_recolour.png" : "farming_101/beach/beach grass.png",
  fRocks: R ? "../docs/ui/tr-cfq-beach/art/sea_rocks_recolour.png" : "farming_101/beach/ocean rocks.png",
  fCrab: R ? "../docs/ui/tr-cfq-beach/art/crab_recolour.png" : "farming_101/beach/crab.png",
};
const PALMS = [[20,9],[33,9],[47,9],[58,9],[71,9],[84,9],[101,9],[113,9],[126,9],[139,9],[150,9],[163,9]];
const ROCKS = [[26,12],[40,13],[55,11],[66,14],[78,12],[99,13],[108,11],[121,14],[134,12],[147,13],[158,11]];
const BOULDERS = [[17,10],[17,15],[62,10],[118,10],[166,10],[166,15]];
const DRIFTWOOD = [[30,13],[69,12],[88,13],[130,13],[155,12],[19,12],[23,12],[37,13],[44,13],[50,12],[53,13],[61,13],[64,13],[74,12],[80,13],[107,13],[111,13],[116,12],[124,13],[137,13],[142,12],[152,13],[161,12],[164,12]];
const SHELLFISH = [[24,14],[51,14],[75,14],[96,14],[116,14],[143,14],[160,14]];
const SPRINGS = [[96,9]];
const BUSHES = [[14,8],[27,8],[40,8],[52,8],[65,8],[77,8],[90,8],[106,8],[119,8],[132,8],[145,8],[157,8],[170,8],[5,14],[178,14]];
const TUFTS = [[22,8],[46,8],[71,8],[98,8],[125,8],[151,8],[9,11],[175,11]];
const COCONUTS = [[83,10],[85,11]];
// Nudges come from the column, so the beach is the same every time it loads.
const nudge = (x, a) => ((x * 7919) % (2 * a + 1)) - a;
let GRASS = [[74,9],[80,9],[88,9],[94,9],[104,9],[110,9]];
let SEA_ROCKS = [[79,16],[97,16],[106,16]];            // every base on the first shallows row, so he can pass behind and in front
let CRABS = [[103,14]];
if (V.spread) {
  const taken = new Set([...PALMS, ...BUSHES, ...SPRINGS, ...SHELLFISH, ...DRIFTWOOD, ...ROCKS, ...BOULDERS, ...TUFTS].map(c => c + ""));
  for (let x = 20; x <= 164; x += 6) if (!taken.has([x, 9] + "") && !GRASS.some(c => Math.abs(c[0] - x) < 4)) GRASS.push([x, 9]);
  for (let x = 22; x <= 162; x += 13) if (!SEA_ROCKS.some(c => Math.abs(c[0] - x) < 7)) SEA_ROCKS.push([x, 16]);
  for (const x of [34, 63, 135, 157]) CRABS.push([x, 14]);
  const wide = V.spread == "wide";
  GRASS = GRASS.map(([x, y]) => [x, wide ? 9 + (((x * 5) >> 1) % 3) : 9 + (((x * 5) >> 1) % 2), nudge(x, 3), nudge(x + 1, wide ? 2 : 4)]);
  SEA_ROCKS = SEA_ROCKS.map(([x, y]) => [x, y, nudge(x, 5), nudge(x + 2, 6)]);
  CRABS = CRABS.map(([x, y]) => [x, wide && x % 2 ? 13 : y, nudge(x, 4), nudge(x + 3, 4)]);
}
function kind(x, y) {
  if (y <= 8) return 0; if (y >= 18) return 5;
  if (x <= 11 || x >= 172) return y <= 14 ? 0 : 5;
  if (x <= 15 || x >= 168) return 6;
  if (y <= 13) return 1; if (y == 14) return 2; if (y == 15) return 3; return 4;
}
const F_PALMS = [[342,16,31,56],[389,18,36,54],[342,83,34,53],[391,82,33,54],[435,87,37,50],[432,25,64,48]];
const F_PALM_FOOT = [16, 18, 16, 18, 20, 60];
const F_SHELLS = { four: [[2,2,11,12],[0,18,14,11],[2,34,12,13],[18,2,11,12]], pink: [[2,2,11,12]], blue: [[18,2,11,12]] }[V.shells];
const F_COCONUT = [3,19,10,10];
const F_GRASS = [[0,12,15,17],[16,10,15,20],[33,11,13,17],[50,13,11,15]];
const F_SEA_ROCKS = [[3,7,27,19],[32,1,32,14],[33,16,14,15]];
const CRAB_CELLS = [[32,0],[32,32],[64,32]];          // normal, walk 1, walk 2: 32x32 cells, feet 9px above the cell's bottom

const img = {};
const load = ([k, p]) => new Promise((ok, no) => { const i = new Image(); i.onload = ok; i.onerror = () => no(p);
  i.src = A + p.split("/").map(encodeURIComponent).join("/"); img[k] = i; });

// The warm palm shadows, the ragged edge and the recoloured sheets are baked into ./art/ beforehand
// (every new pixel moved to its nearest colour in today's island art), so this file only draws.
function prepare() {}

function draw(id, frame, t) {
  const cv = document.getElementById(id); const g = cv.getContext("2d"); g.imageSmoothingEnabled = false;
  const cam = cv.dataset.cam ? JSON.parse(cv.dataset.cam) : [92 * 16 + 8 - 320, 11 * 16 + 8 - 180];
  const x0 = Math.floor(cam[0] / 16), y0 = Math.floor(cam[1] / 16);
  for (let y = Math.max(0, y0); y < Math.min(26, y0 + cv.height / 16 + 2); y++)
    for (let x = x0; x < x0 + cv.width / 16 + 2; x++) ground(g, frame, kind(x, y), x, y, x * 16 - cam[0], y * 16 - cam[1]);
  if (V.wash) wash(g, cam, t);
  const things = [];
  // A cell may carry a pixel nudge [x, y, dx, dy], so props stop lining up on one row.
  const put = (cells, fn) => cells.forEach((c, n) => things.push({ x: c[0] * 16 + 8 + (c[2] || 0) - cam[0], y: (c[1] + 1) * 16 + (c[3] || 0) - cam[1], n, draw: fn }));
  const whole = (i, dy = 0) => s => g.drawImage(i, Math.round(s.x - i.width / 2), s.y - i.height + dy);
  const region = (i, r, dy = 0, foot = null) => s => g.drawImage(i, r[0], r[1], r[2], r[3], Math.round(s.x - (foot ?? r[2] / 2)), s.y - r[3] + dy, r[2], r[3]);
  put(BUSHES, region(img.veg, [0, 0, 32, 32])); put(TUFTS, region(img.veg, [64, 144, 16, 16]));
  put(ROCKS, region(img.rocks, [160, 16, 16, 16])); put(BOULDERS, region(img.rocks, [128, 16, 32, 32]));
  put(DRIFTWOOD, whole(img.driftwood)); put(SPRINGS, whole(img.spring, 10));
  put(PALMS, s => { const v = s.n % 6; region(img.fPalms, F_PALMS[v], 4, F_PALM_FOOT[v])(s); });
  put(SHELLFISH, s => region(img.fShells, F_SHELLS[s.n % F_SHELLS.length], -1)(s));
  put(COCONUTS, region(img.fCoconuts, F_COCONUT));
  put(GRASS, s => region(img.fGrass, F_GRASS[s.n % 4])(s));
  put(SEA_ROCKS, s => region(img.fRocks, F_SEA_ROCKS[s.n % 3])(s));
  put(CRABS, s => { const c = crabCell(t); g.drawImage(img.fCrab, c[0], c[1], 32, 32, s.x - 16, s.y - 32 + 9, 32, 32); });
  const man = cv.dataset.man ? JSON.parse(cv.dataset.man) : [92 * 16 + 8 - cam[0], 12 * 16 - cam[1]];
  things.push({ x: man[0], y: man[1], draw: s => g.drawImage(img.man, 0, 0, 64, 64, s.x - 32, s.y - 48, 64, 64) });
  things.sort((p, q) => p.y - q.y).forEach(s => s.draw(s));
}

// Idle crab: still most of the time, a short sideways shuffle every few seconds.
function crabCell(t) {
  if (V.crab != "idle") return CRAB_CELLS[0];
  const k = (t % 3.2); if (k < 2.4) return CRAB_CELLS[0];
  return CRAB_CELLS[1 + (Math.floor(k * 6) % 2)];
}

function ground(g, frame, k, x, y, px, py) {
  if (k == 0 && y == 8 && x > 11 && x < 172) { g.drawImage(img.tiles, 16, 0, 16, 16, px, py, 16, 16); return g.drawImage(img.edge, (x % 3) * 16, 0, 16, 16, px, py, 16, 16); }
  if (k == 3) { g.drawImage(img.tiles, 64, 0, 16, 16, px, py, 16, 16); return g.drawImage(img.warmWaves, frame * 16, 0, 16, 16, px, py, 16, 16); }
  g.drawImage(img.tiles, k * 16, 0, 16, 16, px, py, 16, 16);
}

// Today's slow wash: pale water running up the wet sand and back every four seconds.
function wash(g, cam, t) {
  const h = Math.round(10 * (0.5 - 0.5 * Math.cos(2 * Math.PI * t / 4))); if (!h) return;
  const top = 15 * 16 - h - cam[1], x = 16 * 16 - cam[0], w = 152 * 16;
  g.fillStyle = "#7baadb"; g.fillRect(x, top, w, h); g.fillStyle = "#a3c8ee"; g.fillRect(x, top, w, 1);
}

Promise.all(Object.entries(SRC).map(load)).then(() => {
  prepare();
  const ids = [...document.querySelectorAll("canvas.scene")].map(c => c.id);
  const t0 = performance.now();
  const tick = () => { const t = (performance.now() - t0) / 1000, f = Math.floor(t / 0.16) % 9; ids.forEach(id => draw(id, f, t)); };
  tick(); setInterval(tick, 40);
}).catch(p => document.body.insertAdjacentHTML("afterbegin", "<p style='color:#f88'>could not load " + p + "</p>"));
