// Drawing only. A close-up of the wet sand at the game's pixel size, drawn four times over, with one
// crab and the man walking up to it and away again, on a loop. Each page sets window.V first:
//   move:  "home" | "roam" | "still"      how it gets about on its own
//   react: "two" | "one" | "dig"          what it does as he comes near
//   under: "mound" | "none"               what shows while it is under the sand
//   solid: false | true                   whether he can walk through it
//   path:  "walk" | "run" | "none"        what the man does
//   night: false | "same" | "hide"        a night view: crabs as by day, or under the sand all night
const V = Object.assign({ move: "home", react: "two", under: "mound", solid: false, path: "walk", night: false }, window.V || {});
const A = "../../../assets/";
const W = 320, H = 96, HOME = 210, CRAB_Y = 44, T = 18;
const CELL = { normal: [[32, 0]], walk: [[32, 32], [64, 32]], claws: [[32, 64], [64, 64]], hole: [[32, 96], [64, 96]] };
const img = {};
const load = (k, p) => new Promise((ok, no) => { const i = new Image(); i.onload = ok; i.onerror = () => no(p);
  i.src = A + p.split("/").map(encodeURIComponent).join("/"); img[k] = i; });

// The man's path: [time, x], straight lines between. He stops twice on the way in.
const MAN_Y = V.path == "run" ? CRAB_Y : 30;
const PATH = V.path == "run"
  ? [[0, -30], [1, -30], [3.6, 220], [5, 220], [7.5, 340], [T, 340]]
  : [[0, -30], [1, -30], [4.5, 140], [7.5, 140], [8.3, 176], [11, 176], [15, -30], [T, -30]];
function manAt(t) {
  if (V.path == "none") return null;
  for (let i = 1; i < PATH.length; i++) if (t <= PATH[i][0]) {
    const [t0, x0] = PATH[i - 1], [t1, x1] = PATH[i], f = (t - t0) / (t1 - t0);
    return { x: x0 + (x1 - x0) * f, dir: Math.sign(x1 - x0) };
  }
  return { x: -30, dir: 0 };
}

// A seeded random, so every loop plays the same.
let seed = 1; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
let c;
function reset() { seed = 7; c = { x: HOME, target: HOME, wait: 1, mode: V.night == "hide" ? "under" : "about", since: 0, clear: 0, dir: 1 }; }

function step(t, dt, man) {
  const d = man ? Math.abs(man.x - c.x) + Math.abs(MAN_Y - CRAB_Y) * 0.5 : 999;
  c.since += dt;
  const set = m => { c.mode = m; c.since = 0; };
  // Reacting to him
  if (c.mode == "about" || c.mode == "claws") {
    if (V.react == "dig" && d < 48) set("digging");
    else if (V.react == "one") { if (c.mode == "about" && d < 48) set("claws"); else if (c.mode == "claws" && c.since > 0.7) set("digging"); }
    else if (V.react == "two") {
      if (d < 32) set("digging");
      else if (c.mode == "about" && d < 64) set("claws");
      else if (c.mode == "claws" && d > 72) set("about");
    }
  }
  if (c.mode == "digging" && c.since > 0.5) set("under");
  if (c.mode == "under" && V.night == "hide") return;
  if (c.mode == "under") { c.clear = d > 80 ? c.clear + dt : 0; if (c.clear > 2) set("emerging"); }
  if (c.mode == "emerging" && c.since > 0.5) { set("about"); c.wait = 0.8; }
  if (c.mode != "about") return;
  // Getting about on its own
  const speed = 16;
  if (c.wait > 0) { c.wait -= dt; return; }
  if (Math.abs(c.target - c.x) < 1) {
    if (V.move == "home") { c.target = HOME + Math.round((rnd() * 2 - 1) * 40); c.wait = 1 + rnd() * 2; }
    else if (V.move == "roam") { c.target = c.x > W / 2 ? 12 : W - 12; c.wait = rnd() < 0.3 ? 1 : 0; }
    else { c.target = c.x == HOME ? HOME + (rnd() < 0.5 ? -6 : 6) : HOME; c.wait = c.x == HOME ? 3 + rnd() * 2 : 0.3; }
    return;
  }
  const s = Math.sign(c.target - c.x);
  let nx = c.x + s * speed * dt;
  if (V.solid && man && Math.abs(nx - man.x) < 12 && Math.abs(MAN_Y - CRAB_Y) < 6) return;
  c.x = nx;
}

function crabCell(t) {
  const f = n => CELL[n][Math.floor(t * 6) % CELL[n].length];
  switch (c.mode) {
    case "claws": return f("claws");
    case "digging": return CELL.hole[c.since < 0.25 ? 0 : 1];
    case "emerging": return CELL.hole[c.since < 0.25 ? 1 : 0];
    case "under": return null;
    default: return c.wait <= 0 && Math.abs(c.target - c.x) >= 1 ? f("walk") : CELL.normal[0];
  }
}

function drawMound(g, x, y) {
  // A little heap of dug sand, 9x3, a shade darker than the wet sand, lit along its top.
  g.fillStyle = "rgba(96,52,30,0.45)"; g.fillRect(x - 4, y - 2, 9, 2); g.fillRect(x - 3, y - 3, 7, 1);
  g.fillStyle = "rgba(255,226,190,0.55)"; g.fillRect(x - 2, y - 3, 5, 1);
  g.fillStyle = "rgba(60,30,18,0.6)"; g.fillRect(x - 1, y - 1, 3, 1);
}

function draw(g, t, man) {
  g.imageSmoothingEnabled = false;
  const rows = [1, 1, 2, 3, 4, 4];
  for (let y = 0; y < 6; y++) for (let x = 0; x < W / 16; x++) {
    g.drawImage(img.tiles, rows[y] * 16, 0, 16, 16, x * 16, y * 16, 16, 16);
    if (rows[y] == 3) g.drawImage(img.waves, (Math.floor(t / 0.16) % 9) * 16, 0, 16, 16, x * 16, y * 16, 16, 16);
  }
  const things = [];
  const cell = crabCell(t), cx = Math.round(c.x);
  if (cell) things.push({ y: CRAB_Y, f: () => g.drawImage(img.crab, cell[0], cell[1], 32, 32, cx - 16, CRAB_Y - 32 + 9, 32, 32) });
  else if (V.under == "mound") things.push({ y: CRAB_Y - 1, f: () => drawMound(g, cx, CRAB_Y) });
  if (man) {
    const sheet = man.dir ? (V.path == "run" ? img.run : img.walk) : img.idle;
    const cols = man.dir ? 6 : 4, row = man.dir < 0 ? 2 : 3;
    const fr = Math.floor(t * (man.dir ? (V.path == "run" ? 16 : 12) : 6)) % cols;
    things.push({ y: MAN_Y, f: () => g.drawImage(sheet, fr * 64, row * 64, 64, 64, Math.round(man.x) - 32, MAN_Y - 48, 64, 64) });
  }
  things.sort((p, q) => p.y - q.y).forEach(s => s.f());
  // Night, roughly as the day-night drawing darkens the island.
  if (V.night) { g.fillStyle = "rgba(18,26,70,0.5)"; g.fillRect(0, 0, W, H); }
}

const WORDS = { about: "going about", claws: "claws up", digging: "digging in", under: "under the sand", emerging: "coming back out" };
Promise.all([["tiles", "beach/tiles.png"], ["waves", "../docs/ui/vendor-art-swap/waves_warm.png"],
  ["crab", "farming_101/beach/crab.png"], ["walk", "man/walk.png"], ["run", "man/run.png"], ["idle", "man/idle.png"]]
  .map(([k, p]) => load(k, p))).then(() => {
  const cv = document.getElementById("c"), g = cv.getContext("2d"), note = document.getElementById("state");
  let t0 = performance.now(), last = 0; reset();
  setInterval(() => {
    let t = (performance.now() - t0) / 1000;
    if (t >= T) { t0 = performance.now(); t = 0; last = 0; reset(); }
    let man = manAt(t);
    // The man stops rather than walk through a solid crab.
    if (V.solid && man && c.mode != "under" && Math.abs(MAN_Y - CRAB_Y) < 6 && man.dir > 0 && man.x > c.x - 14) man = { x: c.x - 14, dir: 0 };
    step(t, t - last, man); last = t;
    draw(g, t, man);
    note.textContent = "crab: " + WORDS[c.mode] + (man && man.x > -20 && man.x < W + 20 ? " · man " + Math.round(Math.abs(man.x - c.x) / 16 * 10) / 10 + " tiles away" : "");
  }, 30);
}).catch(p => document.body.insertAdjacentHTML("afterbegin", "<p style='color:#f88'>could not load " + p + "</p>"));
