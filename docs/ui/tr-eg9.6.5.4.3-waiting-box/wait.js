// The waiting box while a new key or button is being pressed, at every UI / Text size.
// rule: 'cap' | 'shed' | 'full'
const MARGIN = 8;

function wrapWords(text, maxChars) {
  if (maxChars < 1) maxChars = 1;
  const words = text.split(' ');
  const out = []; let cur = '';
  for (const w of words) {
    if (cur === '') cur = w;
    else if ((cur + ' ' + w).length <= maxChars) cur += ' ' + w;
    else { out.push(cur); cur = w; }
  }
  out.push(cur);
  return out;
}

// One attempt at a layout. Returns null-ish info including whether it fits.
function attempt(ui, w, rule, NAME, PRESS) {
  const font = 8 * w, lh = Math.round(font * 1.25);
  const noPanel = (rule === 'full');
  const pad = noPanel ? 0 : Math.round(8 * ui);
  const panelMax = 320 - 2 * MARGIN;
  const wordMax = panelMax - 2 * pad;
  const maxChars = Math.floor(wordMax / font);
  const nameLines = wrapWords(NAME, maxChars);
  const pressLines = wrapWords(PRESS, maxChars);
  const picW = Math.round(22 * ui);          // the Esc cap / B button picture
  const picH = Math.round(11 * ui);
  const ringR = Math.round(5 * ui);
  const gap = Math.round(3 * ui);
  const shed = (rule === 'shed' || rule === 'full');
  // the hold line
  let hold;                                   // array of runs: each {kind:'w'|'pic', s}
  const holdRunW = font * 4 + gap + picW + gap + font * 9;   // "Hold" + pic + "to cancel"
  if (shed) hold = [[{ k: 'pic' }]];
  else if (holdRunW + 2 * ringR + gap <= wordMax) hold = [[{ k: 'w', s: 'Hold' }, { k: 'pic' }, { k: 'w', s: 'to cancel' }]];
  else hold = [[{ k: 'w', s: 'Hold' }, { k: 'pic' }], [{ k: 'w', s: 'to cancel' }]];
  const holdH = hold.length * Math.max(lh, picH + 2);
  const nf = Math.round(font * 0.7), nlh = Math.round(nf * 1.3);
  const noteLines = (typeof NOTE === 'string' && NOTE) ? wrapWords(NOTE, Math.floor(wordMax / nf)) : [];
  const h = (nameLines.length + pressLines.length) * lh + Math.round(lh * 0.4) + holdH
    + (noteLines.length ? Math.round(lh * 0.3) + noteLines.length * nlh : 0) + 2 * pad;
  // widest line
  let widest = 0;
  for (const l of nameLines.concat(pressLines)) widest = Math.max(widest, l.length * font);
  for (const l of noteLines) widest = Math.max(widest, l.length * nf);
  for (const row of hold) {
    let rw = 0;
    row.forEach((it, i) => { rw += (it.k === 'pic' ? picW : it.s.length * font) + (i ? gap : 0); });
    widest = Math.max(widest, rw + gap + 2 * ringR);
  }
  const boxW = noPanel ? 320 : Math.min(panelMax, Math.max(Math.round(200 * ui), widest + 2 * pad));
  return { font, lh, pad, nf, nlh, noteLines, nameLines, pressLines, hold, picW, picH, ringR, gap, h, boxW, noPanel, fits: h <= 180 - 8 };
}

// Find the layout actually drawn: grow words to ui*text, step down until it fits.
function solve(ui, tx, rule, NAME, PRESS) {
  const want = ui * tx;
  // Every option keeps the ordinary box with all its words for as long as that fits.
  const plain = attempt(ui, want, 'cap', NAME, PRESS);
  if (plain.fits) return Object.assign(plain, { w: want, capped: false, want });
  if (rule === 'cap') {
    for (let w = want; w >= 1; w -= 0.25) {
      const a = attempt(ui, w, 'cap', NAME, PRESS);
      if (a.fits) return Object.assign(a, { w, capped: true, want });
    }
    return Object.assign(attempt(ui, 1, 'cap', NAME, PRESS), { w: 1, capped: true, want });
  }
  for (let w = want; w >= 1; w -= 0.25) {
    const a = attempt(ui, w, rule, NAME, PRESS);
    if (a.fits) return Object.assign(a, { w, capped: w < want - 0.001, want, shed: true });
  }
  return Object.assign(attempt(ui, 1, rule, NAME, PRESS), { w: 1, capped: true, want, shed: true });
}

// The Controls page behind, dimmed.
function controlsBehind(ui) {
  const s0 = r(0, 0, 320, 180, '#2c1d16');
  const f = 5 * ui, rowH = Math.round(14 * ui), x = Math.round(160 - 100 * ui), wd = Math.round(200 * ui);
  let s = s0 + t(160, Math.round(18 * ui), 'Controls', Math.round(7 * ui), P.text, 'middle');
  const rows = [['Walk right', 'D'], ['Walk left', 'A'], ['Use', 'E'], ['Build', 'B']];
  rows.forEach((rw, i) => {
    const y = Math.round(26 * ui) + i * (rowH + Math.round(3 * ui));
    if (y + rowH > 176) return;
    s += r(x, y, wd, rowH, P.plankDk) + r(x + 1, y + 1, wd - 2, rowH - 2, P.plank) +
      t(x + 5 * ui, y + rowH / 2 + f * 0.45, rw[0], f) +
      t(x + wd - 5 * ui, y + rowH / 2 + f * 0.45, rw[1], f, P.text, 'end');
  });
  return s;
}

function ringMark(cx, cy, rad) {
  return `<circle cx="${cx}" cy="${cy}" r="${rad}" fill="none" stroke="#ffe2a8" stroke-width="1.5" opacity=".5"/>` +
    `<path d="M${cx} ${cy - rad} A${rad} ${rad} 0 0 1 ${cx + rad} ${cy}" fill="none" stroke="#ffd24a" stroke-width="1.5"/>`;
}

function picMark(x, y, w, h, label) {
  return r(x, y, w, h, 'none', 'stroke="#fff6e0" stroke-width="1"') +
    t(x + w / 2, y + h / 2 + h * 0.3, label, Math.max(3, h * 0.5), P.text, 'middle');
}

// The whole screen: the Controls page, the dim, and the waiting box.
function waitScreen(ui, tx, rule, NAME, PRESS, KEYLABEL) {
  const L = solve(ui, tx, rule, NAME, PRESS);
  let s = controlsBehind(ui) + r(0, 0, 320, 180, '#000', 'opacity="0.55"');
  const boxX = Math.round(160 - L.boxW / 2), boxY = Math.round(90 - L.h / 2);
  if (!L.noPanel) s += r(boxX, boxY, L.boxW, L.h, '#fff1c9') + r(boxX + 2, boxY + 2, L.boxW - 4, L.h - 4, P.plank);
  let y = boxY + L.pad;
  for (const l of L.nameLines) { s += t(160, y + L.font, l, L.font, P.text, 'middle'); y += L.lh; }
  for (const l of L.pressLines) { s += t(160, y + L.font, l, L.font, '#ffe2a8', 'middle'); y += L.lh; }
  y += Math.round(L.lh * 0.4);
  const rowH = Math.max(L.lh, L.picH + 2);
  for (const row of L.hold) {
    let rw = 0;
    row.forEach((it, i) => { rw += (it.k === 'pic' ? L.picW : it.s.length * L.font) + (i ? L.gap : 0); });
    const isLast = row === L.hold[L.hold.length - 1];
    const total = rw + (isLast ? L.gap + 2 * L.ringR : 0);
    let cx = Math.round(160 - total / 2);
    row.forEach(it => {
      if (it.k === 'pic') { s += picMark(cx, y + (rowH - L.picH) / 2, L.picW, L.picH, KEYLABEL); cx += L.picW + L.gap; }
      else { s += t(cx, y + rowH / 2 + L.font * 0.4, it.s, L.font, P.text, 'start'); cx += it.s.length * L.font + L.gap; }
    });
    if (isLast) s += ringMark(cx - L.gap + L.ringR + L.gap, y + rowH / 2, L.ringR);
    y += rowH;
  }
  if (L.noteLines.length) {
    y += Math.round(L.lh * 0.3);
    for (const l of L.noteLines) { s += t(160, y + L.nf, l, L.nf, '#d9c7a3', 'middle'); y += L.nlh; }
  }
  return s;
}

function cap(ui, tx, rule, NAME, PRESS) {
  const L = solve(ui, tx, rule, NAME, PRESS);
  const bits = [];
  if (L.shed) bits.push('cancel words gone, picture and ring only');
  if (L.noPanel) bits.push('no box, the whole screen');
  if (L.capped) bits.push('words held back to ' + (L.w / ui).toFixed(2).replace(/0+$/, '').replace(/\.$/, '') + '\u00d7 of normal');
  return bits.length ? bits.join('; ') + '.' : 'Everything at the chosen size, nothing given up.';
}
