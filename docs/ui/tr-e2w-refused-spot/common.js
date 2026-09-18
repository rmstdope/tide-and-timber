// Drawings for "a refused build spot on jungle". 320x180 pixel scenes, SVG.
const P={jungle:'#3f7a3a',jungleDk:'#2f5e2c',jungleLt:'#5a8f45',sand:'#f0cf8a',sandDk:'#d9ae62',woodDk:'#5c3a22',wood:'#8a5a34',woodLt:'#b98452',red:'#e0503a',pale:'#f4ead2',skin:'#e0a172',shirt:'#b8462e',pants:'#3d4f6e',hair:'#4a2c1a',text:'#fff6e0',plank:'#8a5a34',plankDk:'#5c3a22',orange:'#ffb38a',quiet:'#b89a7a'};
const r=(x,y,w,h,c,o='')=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" ${o}/>`;
const t=(x,y,s,sz=6,c=P.text,a='start',o='')=>`<text x="${x}" y="${y}" font-size="${sz}" fill="${c}" text-anchor="${a}" ${o}>${s}</text>`;
const FILTER=`<filter id="deu" color-interpolation-filters="linearRGB"><feColorMatrix type="matrix" values="0.367 0.861 -0.228 0 0  0.280 0.673 0.047 0 0  -0.012 0.043 0.969 0 0  0 0 0 1 0"/></filter>`;
const svg=(i,cb)=>`<svg class="px" viewBox="0 0 320 180" shape-rendering="crispEdges"><defs>${FILTER}</defs><g ${cb?'filter="url(#deu)"':''}>${i}</g></svg>`;
function jungle(){let s=r(0,0,320,180,P.jungle);
 for(let x=0;x<320;x+=16)for(let y=0;y<180;y+=16){if((x*7+y*3)%5===0)s+=r(x+4,y+5,4,3,P.jungleDk);if((x*3+y*11)%7===0)s+=r(x+9,y+10,3,2,P.jungleLt)}
 s+=r(0,150,320,30,P.sand)+r(0,148,320,2,P.sandDk);
 s+=r(40,40,8,30,P.woodDk)+r(22,30,44,14,'#2a5226')+r(260,60,8,30,P.woodDk)+r(242,50,44,14,'#2a5226');
 s+=r(118,112,6,6,P.skin)+r(118,112,6,2,P.hair)+r(117,118,8,7,P.shirt)+r(118,125,2,5,P.pants)+r(122,125,2,5,P.pants);return s}
// the lean-to outline at (ox,oy) = its foot middle, 2x so it reads at this size
function leanTo(ox,oy,ok,cross,tick){const S=2,a=.55;const R=(x,y,w,h,c)=>r(ox+x*S,oy+y*S,w*S,h*S,ok?c:P.red);
 let s=`<g opacity="${a}">`+R(-22,-5,44,4,P.woodDk);for(let i=0;i<5;i++){s+=R(-22+8*i,-9-6*i,12,6,P.wood)+R(-20+8*i,-9-6*i,6,2,P.woodLt)}s+=R(15,-40,3,36,P.woodDk);
 if(cross){for(let i=0;i<11;i++){s+=r(ox+(-5+i)*S,oy+(-25+i)*S,S,S,P.pale)+r(ox+(5-i)*S,oy+(-25+i)*S,S,S,P.pale)}}
 if(tick){[[-4,-20],[-3,-19],[-2,-18],[-1,-19],[0,-20],[1,-21],[2,-22],[3,-23],[4,-24]].forEach(([x,y])=>s+=r(ox+x*S,oy+y*S,S,S,P.pale))}
 return s+'</g>'}
const key=(x,y,k)=>{const w=k.length*5+4;return [r(x,y,w,9,'none','stroke="#fff6e0" stroke-width="1"')+t(x+w/2,y+7,k,4,P.text,'middle'),w]};
function hint(pairs){let x=6,s='';const parts=[];for(const [k,l] of pairs){const [ks,w]=key(x+3,168,k);parts.push(ks+t(x+w+6,175,l,4));x+=w+l.length*4+14}return r(4,165,x-2,14,'#1b1420','opacity=".7"')+parts.join('')}
function scene(ok,cross,tick){return jungle()+leanTo(190,110,ok,cross,tick)+hint([['E','Build'],['ESC','Cancel']])}
function fig(title,sub,inner,cb){return `<figure>${svg(inner,cb)}<figcaption><b>${title}</b><span>${sub}</span></figcaption></figure>`}
// a settings-style row
function vrow(x,y,w,label,val,sel){const h=14,vx=x+w-8;return r(x,y,w,h,sel?'#fff1c9':P.plankDk)+r(x+1,y+1,w-2,h-2,sel?'#c98a4a':P.plank)+t(x+6,y+9.5,label,5)+t(vx-8,y+9.5,val,5,P.text,'end')+t(vx,y+9.5,'▶',5,P.text,'end')+t(vx-11-val.length*3.2,y+9.5,'◀',5,P.text,'end')}
function ctrlRow(y,label,mark,orange){return r(20,y,280,16,P.plankDk)+r(21,y+1,278,14,P.plank)+t(28,y+10.5,label,5)+t(170,y+10.5,'W',5,P.text,'middle')+t(240,y+10.5,mark,6,orange?P.orange:P.quiet,'middle')}
function controls(missingMark){return r(0,0,320,180,'#2c1d16')+t(160,18,'Controls',7,P.text,'middle')+t(170,34,'Keys',5,'#ffe2a8','middle')+t(240,34,'Pad',5,'#ffe2a8','middle')+ctrlRow(40,'Walk up','—',false)+ctrlRow(58,'Build',missingMark,true)+ctrlRow(76,'Use','—',false)+''}
const CSS=`<link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet"><style>:root{--bg:#f7efe0;--ink:#2b2230;--dim:#7a6b5e;--card:#fffaf0}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#17151c;--ink:#efe6d6;--dim:#a79a8c;--card:#221f29}}
:root[data-theme="dark"]{--bg:#17151c;--ink:#efe6d6;--dim:#a79a8c;--card:#221f29}
body{background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,sans-serif;margin:0;padding:24px 16px}
h1{font-size:22px;margin:0 0 4px}h2{font-size:17px;margin:28px 0 6px}.lede{color:var(--dim);max-width:75ch;margin:0 0 16px}
.strip{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px}
figure{margin:0;background:var(--card);border-radius:8px;padding:8px}
svg.px{width:100%;height:auto;display:block;border-radius:3px}
figcaption{font-size:13px;padding:6px 2px 0}figcaption b{display:block}figcaption span{color:var(--dim)}
.cost{background:var(--card);border-left:4px solid #d9ae62;padding:8px 12px;max-width:75ch;border-radius:4px;margin:12px 0}
text{font-family:'Press Start 2P',monospace}</style>`;
document.head.insertAdjacentHTML('beforeend',CSS);
function page(h,lede,sections){document.body.innerHTML=`<h1>${h}</h1><p class="lede">${lede}</p>`+sections.map(([h2,txt,figs,cost])=>`<h2>${h2}</h2><p class="lede">${txt}</p><div class="strip">${figs.join('')}</div>${cost?`<div class="cost">${cost}</div>`:''}`).join('')}
