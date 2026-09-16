const esc=s=>s.replace(/&/g,'&amp;');
function scene(inner){return `<div class="screen"><div class="sky"></div><div class="sun"></div><div class="wave" style="left:40px;top:230px;width:60px"></div><div class="wave" style="left:380px;top:260px;width:90px"></div><div class="wreck"></div><div class="beach"></div><div class="palm" style="left:40px"></div><div class="logo" style="left:0;right:0;top:36px;text-align:center">TIDE &amp; TIMBER<small>a story of an island</small></div>${inner}<div class="foot">v0.1</div></div>`}
function menu(items,top=222){return `<div class="menu" style="left:220px;top:${top}px;width:200px;text-align:center">${items.map(i=>`<div class="plank${i.sel?' sel':''}" style="${i.style||''}">${i.t}${i.sub?`<div style="font-size:8px;padding:4px 0 0;margin:0;color:#ffe2a8">${i.sub}</div>`:''}</div>`).join('')}</div>`}
function box(lines,btns,sel){return `<div class="dim"></div><div class="box">${lines.map(l=>`<div>${l}</div>`).join('')}<div class="row">${btns.map((b,i)=>`<span class="${i==sel?'sel':''}">${b}</span>`).join('')}</div></div>`}
function black(inner){return `<div class="screen" style="background:#000">${inner}</div>`}
function page(h,note,figs){document.body.innerHTML=`<h1 class="page">${h}</h1><p class="note">${note}</p><div class="wrap">${figs.map(f=>`<div>${f[1]}<p class="cap"><b>${f[0]}</b> — ${f[2]}</p></div>`).join('')}</div>`}
const M3=s=>menu(['Continue','New Game','Quit'].map((t,i)=>({t,sel:i==s,sub:i==0?'DAY 4':''})),212);
const pad=t=>`<div class="pad">${t}</div>`;
const ptr=(x,y)=>`<div class="cursor" style="left:${x}px;top:${y}px"></div>`;
const A='<span class="btn" style="background:#3a9a3a">A</span>',B='<span class="btn" style="background:#c0392b">B</span>';
function variant(title,note,figs){page(title,'Each picture is the title screen at 2x the game\'s 320x180 base; what applies here applies the same way in the pause menu and the settings screen. The box top-left says what the player is doing with the controller. '+note,figs)}
const hp=s=>`<div class="hint">${s}</div>`;
const HS=hp(A+'Select'), HSB=hp(A+'Select &nbsp; '+B+'Back');
function settings(row,val,extra=''){const rows=[['UI size',['1x','2x','3x'][val]],['Text size','Normal'],['Colour cues','Standard'],['Controls','']];return `<div class="screen" style="background:#2c1d16"><div style="position:absolute;left:0;right:0;top:24px;text-align:center;font-size:16px;color:#fff4d6">Settings</div><div class="menu" style="left:120px;top:70px;width:400px">${rows.map((r,i)=>`<div class="plank${i==row?' sel':''}" style="display:flex;justify-content:space-between"><span>${r[0]}</span><span>${r[1]?'◀ '+r[1]+' ▶':''}</span></div>`).join('')}</div>${extra}</div>`}
