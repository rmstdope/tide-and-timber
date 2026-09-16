// Shared drawing helpers for the gathering drawings. Base picture 320x180, shown at 2x.
// Colours and shapes are placeholders for the real pixel art.
const T = 16;
const C = {
  sea: '#2c6d91', sh: '#5fb3c9', foam: '#bfe9ef', wet: '#d2a86a', sand: '#e9c27f',
  grass: '#5a9a3e', dark: '#3f7a33', rock: '#8a8378', rockD: '#625c53', rockL: '#b1aa9c',
  wood: '#9c7048', woodD: '#6e4a2c', trunk: '#7a4a2a', leaf: '#3f8a3a', leafD: '#2f6e2d',
  coco: '#6b4226', shell: '#f1d6c8', shellD: '#c98f86', water: '#7fd3e6',
  plank: '#b07a45', plankD: '#7a5030', plankL: '#d9a56b', ink: '#3a2414', paper: '#f4e3c1',
  hi: '#fff3c4', red: '#c8553d', blue: '#4aa3df', green: '#7bc96f', night: '#1b1420'
};

function screen(parent, caption) {
  const fig = document.createElement('figure');
  fig.className = 'fig';
  const cv = document.createElement('canvas');
  cv.width = 640; cv.height = 360;
  fig.appendChild(cv);
  if (caption) { const c = document.createElement('figcaption'); c.innerHTML = caption; fig.appendChild(c); }
  parent.appendChild(fig);
  const g = cv.getContext('2d');
  g.imageSmoothingEnabled = false;
  g.setTransform(2, 0, 0, 2, 0, 0);
  return g;
}

function rect(g, x, y, w, h, col) { g.fillStyle = col; g.fillRect(Math.round(x), Math.round(y), w, h); }

// Beach: jungle top rows, sand, wet line, foam, shallows, sea.
function beach(g, opt = {}) {
  rect(g, 0, 0, 320, 180, C.sand);
  for (let x = 0; x < 320; x += T) {
    rect(g, x, 0, T, 28, (x / T) % 2 ? C.grass : C.dark);
    rect(g, x + 2, 24, 12, 6, C.dark);
  }
  rect(g, 0, 128, 320, 6, C.wet);
  rect(g, 0, 134, 320, 4, C.foam);
  rect(g, 0, 138, 320, 18, C.sh);
  rect(g, 0, 156, 320, 24, C.sea);
  for (let i = 0; i < 12; i++) rect(g, (i * 53) % 320, 44 + (i * 37) % 70, 2, 1, '#d8b06c');
  if (opt.rocks !== false) { rock(g, 250, 60); rock(g, 30, 100); }
}

function rock(g, x, y) { rect(g, x, y, 16, 12, C.rock); rect(g, x, y + 9, 16, 3, C.rockD); rect(g, x + 2, y + 1, 5, 3, C.rockL); }

function palm(g, x, y, cocos = 2) { // x,y = base of trunk
  rect(g, x - 2, y - 30, 4, 30, C.trunk);
  rect(g, x - 14, y - 36, 12, 5, C.leaf); rect(g, x + 2, y - 36, 12, 5, C.leafD);
  rect(g, x - 8, y - 40, 16, 5, C.leaf);
  for (let i = 0; i < cocos; i++) rect(g, x - 5 + i * 5, y - 31, 4, 4, C.coco);
}

function coconut(g, x, y) { rect(g, x, y, 5, 5, C.coco); rect(g, x + 1, y + 1, 1, 1, '#8b5a36'); }

function driftwood(g, x, y) {
  rect(g, x, y + 3, 14, 3, C.wood); rect(g, x + 2, y + 5, 10, 1, C.woodD); rect(g, x + 9, y, 2, 4, C.wood);
}

function shellfish(g, x, y) { rect(g, x, y, 5, 3, C.shell); rect(g, x + 1, y + 2, 3, 1, C.shellD); rect(g, x + 7, y + 2, 4, 3, C.shell); }

function spring(g, x, y) { // rocks around a small freshwater pool, trickle down
  rect(g, x, y, 28, 14, C.rock); rect(g, x + 4, y + 3, 20, 8, C.water); rect(g, x + 6, y + 4, 6, 1, '#cff3fa');
  rect(g, x, y + 11, 28, 3, C.rockD); rect(g, x + 12, y + 14, 3, 8, C.water);
}

// The man: 10x18, facing 'down' | 'up' | 'left' | 'right'.
function man(g, x, y, face = 'down', pose = 'stand') {
  rect(g, x + 2, y, 6, 6, '#e0a878');          // head
  rect(g, x + 2, y, 6, 2, '#5a3a22');          // hair
  if (face === 'down') { rect(g, x + 3, y + 3, 1, 1, C.ink); rect(g, x + 6, y + 3, 1, 1, C.ink); }
  rect(g, x + 1, y + 6, 8, 7, '#d9d2b8');      // torn shirt
  rect(g, x + 1, y + 13, 8, 5, '#4d6a8a');     // trousers
  if (pose === 'crouch') { rect(g, x + 1, y + 11, 8, 4, '#4d6a8a'); rect(g, x, y + 15, 10, 3, 'transparent'); }
  if (face === 'left') rect(g, x - 1, y + 8, 2, 4, '#e0a878');
  if (face === 'right') rect(g, x + 9, y + 8, 2, 4, '#e0a878');
}

// Pixel-ish text in base coordinates.
function text(g, s, x, y, col = C.paper, size = 7, align = 'left') {
  g.font = `bold ${size}px "Press Start 2P", ui-monospace, monospace`;
  g.textAlign = align; g.textBaseline = 'top';
  g.fillStyle = '#00000088'; g.fillText(s, x + 0.5, y + 0.5);
  g.fillStyle = col; g.fillText(s, x, y);
}

function plank(g, x, y, w, h) {
  rect(g, x, y, w, h, C.plankD); rect(g, x + 1, y + 1, w - 2, h - 2, C.plank); rect(g, x + 1, y + 1, w - 2, 1, C.plankL);
}

function keycap(g, k, x, y) { rect(g, x, y, 9, 9, C.paper); rect(g, x, y + 8, 9, 1, '#a8977a'); text(g, k, x + 4.5, y + 1.5, C.ink, 6, 'center'); }

// Item icons, 10x10 at (x,y).
const ICON = {
  wood: (g, x, y) => { rect(g, x, y + 5, 10, 3, C.wood); rect(g, x + 1, y + 7, 8, 1, C.woodD); rect(g, x + 6, y + 2, 2, 4, C.wood); },
  coconut: (g, x, y) => { rect(g, x + 2, y + 2, 7, 7, C.coco); rect(g, x + 3, y + 3, 2, 1, '#8b5a36'); },
  shellfish: (g, x, y) => { rect(g, x + 1, y + 3, 8, 5, C.shell); rect(g, x + 2, y + 7, 6, 1, C.shellD); rect(g, x + 3, y + 4, 1, 3, C.shellD); rect(g, x + 6, y + 4, 1, 3, C.shellD); },
  water: (g, x, y) => { rect(g, x + 2, y + 3, 7, 6, C.coco); rect(g, x + 3, y + 3, 5, 2, C.water); },
  stone: (g, x, y) => { rect(g, x + 1, y + 3, 8, 6, C.rock); rect(g, x + 2, y + 4, 3, 2, C.rockL); },
};

function slot(g, x, y, icon, n, selected) {
  rect(g, x, y, 16, 16, selected ? C.hi : C.plankD);
  rect(g, x + 1, y + 1, 14, 14, '#e8cf9c');
  rect(g, x + 1, y + 1, 14, 1, '#f6e4bb');
  if (icon) ICON[icon](g, x + 3, y + 2);
  if (n != null) text(g, String(n), x + 15, y + 10, '#fff', 5, 'right');
}

function hotbar(g, items, n = 8, sel = -1, y = 160) {
  const w = n * 17 + 5, x0 = Math.round((320 - w) / 2);
  plank(g, x0, y - 3, w, 22);
  for (let i = 0; i < n; i++) { const it = items[i]; slot(g, x0 + 3 + i * 17, y, it && it[0], it && it[1], i === sel); }
  return x0;
}

function page(title, note) {
  document.title = title;
  document.body.insertAdjacentHTML('afterbegin', `<h1>${title}</h1><p class="note">${note}</p>`);
}

function option(label, blurb) {
  const sec = document.createElement('section');
  sec.innerHTML = `<h2>${label}</h2><p class="blurb">${blurb}</p><div class="row"></div>`;
  document.body.appendChild(sec);
  return sec.querySelector('.row');
}

document.head.insertAdjacentHTML('beforeend', `<style>
body{margin:0;background:#1b1420;color:#f4e3c1;font-family:system-ui,sans-serif;padding:16px 24px 40px}
h1{font-size:20px;margin:4px 0}h2{font-size:17px;margin:28px 0 4px;color:#ffd98a}
p.note,p.blurb{font-size:14px;max-width:1000px;color:#d9c7a3;margin:4px 0 10px}
.row{display:flex;flex-wrap:wrap;gap:18px}.fig{margin:0}
canvas{width:640px;height:360px;image-rendering:pixelated;border:4px solid #0d0a10;display:block;max-width:100%;height:auto}
figcaption{font-size:13px;color:#d9c7a3;max-width:640px;margin-top:6px}
</style>`);
ICON.shell = (g, x, y) => { rect(g, x + 2, y + 4, 7, 5, C.coco); rect(g, x + 3, y + 4, 5, 2, '#3a2414'); };
function emptyShell(g, x, y) { rect(g, x, y + 1, 6, 4, C.coco); rect(g, x + 1, y + 1, 4, 2, '#3a2414'); }
function cursor(g,x,y){ rect(g,x,y,1,9,C.ink); for(let i=1;i<6;i++){ rect(g,x+i,y+i,1,1,C.ink); if(i>1) rect(g,x+1,y+i,i-1,1,'#fff'); } rect(g,x+1,y+6,4,1,C.ink); }
function outline(g,x,y,w,h){ g.strokeStyle=C.hi; g.lineWidth=1; g.strokeRect(x-1.5,y-1.5,w+3,h+3); }
function prompt(g,cx,y,key,word){ const w = 16 + word.length*6; plank(g, cx - w/2, y, w, 13); keycap(g, key, cx - w/2 + 3, y + 2); text(g, word, cx - w/2 + 14, y + 4, C.paper, 6); }
