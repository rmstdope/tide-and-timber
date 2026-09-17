const K=t=>`<span class="cap">${t}</span>`,A=`<span class="btn g">A</span>`,B=`<span class="btn rd">B</span>`,X=`<span class="btn bl">X</span>`,Y=`<span class="btn y">Y</span>`,LB=`<span class="sh">LB</span>`,RB=`<span class="sh">RB</span>`,ST=`<span class="sh">START</span>`,S=d=>`<span class="stk">L ${d}</span>`;
const ACT=[['Walk up',[K('W'),K('↑')],[S('↑')]],['Walk down',[K('S'),K('↓')],[S('↓')]],['Walk left',[K('A'),K('←')],[S('←')]],['Walk right',[K('D'),K('→')],[S('→')]],['Run (hold)',[K('Shift')],[LB]],['Use / take',[K('E')],[A]],['Build list',[K('B')],[Y]],['Pause',[K('Esc')],[ST]]];
function scr(inner){return `<div class="scr"><div class="ttl">Controls</div>${inner}</div>`}
function hint(h){return `<div class="hint">${h}</div>`}
function page(t,n,figs){document.body.innerHTML=`<h1>${t}</h1><p>${n}</p><div class="wrap">${figs.map(f=>`<div><div class="lab">${f[0]}</div>${f[1]}<div class="note">${f[2]||''}</div></div>`).join('')}</div><p style="font-size:12px">Each picture is at 2x the game's 320x180 base. Colours, fonts and button pictures are placeholders for the real pixel art.</p>`}
const TAB=t=>`<div class="tabs"><span class="${t==0?"on":""}">Keyboard</span><span class="${t==1?"on":""}">Controller</span></div>`;
const NOTE=`<div class="msg" style="bottom:38px;color:#d9c7a3;font-size:10px">Menus always use the arrow keys, Enter and Esc</div>`;
const NOTEP=`<div class="msg" style="bottom:38px;color:#d9c7a3;font-size:10px">Menus always use the d-pad, A and B</div>`;
function T(tab,sel,slot,sub={},extra=""){const rows=ACT.map((a,i)=>{const v=tab==0?[a[1][0],a[1][1]||"<span class=lock>—</span>"]:[a[2][0]];return `<div class="r${i==sel?" sel":""}"><span class="n">${a[0]}</span>${v.map((x,j)=>`<span class="c" style="width:80px"><span class="cell${i==sel&&slot==j?" on":""}">${sub[i+"-"+j]!==undefined?sub[i+"-"+j]:x}</span></span>`).join("")}</div>`}).join("");
return scr(TAB(tab)+`<div class="list">${rows}<div class="r${sel==8?" sel":""}"><span class="n">Reset ${tab==0?"keyboard":"controller"} to defaults</span></div></div>`+(tab==0?NOTE:NOTEP)+extra)}
const HK=hint(K("Q")+K("E")+"Tab "+K("Enter")+"Change "+K("Esc")+"Back"),HP=hint(LB+RB+"Tab "+A+"Change "+B+"Back");
const BOX=(l,b,s)=>`<div class="dim"></div><div class="box">${l}${b?`<div class="bb">${b.map((x,i)=>`<span class="${i==s?"sel":""}">${x}</span>`).join("")}</div>`:""}</div>`;
const FIX=s=>s.replace(/<\/div>(<div class="hint">(?:(?!<div class="scr">).)*?<\/div>)(?=$|<div class="scr">)/g,'$1</div>');
const _page=page;page=(t,n,figs)=>_page(t,n,figs.map(f=>[f[0],FIX(f[1]),f[2]]));
