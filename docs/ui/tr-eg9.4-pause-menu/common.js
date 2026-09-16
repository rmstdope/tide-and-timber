const P={sand:'#f0cf8a',sandDk:'#d9ae62',wet:'#c49a5a',shallow:'#4fa3a5',foam:'#d8e6e8',grass:'#6a9a3e',palm:'#3f7a3a',woodDk:'#5c3a22',wood:'#8a5a34',skin:'#e0a172',shirt:'#b8462e',pants:'#3d4f6e',hair:'#4a2c1a',text:'#fff6e0',plank:'#8a5a34',plankDk:'#5c3a22'};
const r=(x,y,w,h,c,o='')=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" ${o}/>`;
const t=(x,y,s,sz=6,c=P.text,a='start',o='')=>`<text x="${x}" y="${y}" font-size="${sz}" fill="${c}" text-anchor="${a}" ${o}>${s}</text>`;
const svg=i=>`<svg class="px" viewBox="0 0 320 180" shape-rendering="crispEdges">${i}</svg>`;
function beach(){let s=r(0,0,320,180,P.sand)+r(0,0,320,34,P.shallow)+r(0,34,320,6,P.foam)+r(0,40,320,8,P.wet);
 for(let x=0;x<320;x+=16)for(let y=48;y<180;y+=16)if((x*7+y*3)%5===0)s+=r(x+5,y+6,3,2,P.sandDk);
 s+=r(0,150,320,30,P.grass)+r(30,128,6,26,P.woodDk)+r(14,118,40,12,P.palm)+r(270,132,6,22,P.woodDk)+r(254,122,40,12,P.palm);
 s+=r(200,100,22,4,P.wood)+r(96,112,14,3,P.wood);
 s+=r(153,82,6,6,P.skin)+r(153,82,6,2,P.hair)+r(152,88,8,7,P.shirt)+r(153,95,2,5,P.pants)+r(157,95,2,5,P.pants);return s}
const tint=(c,o)=>r(0,0,320,180,c,`opacity="${o}"`);
const dawnTint=tint('#6a5a9a',.28);
function dial(frac,label,day){const cx=30,cy=26,R=16,h=34;let s=r(6,4,50,h,P.plankDk)+r(7,5,48,h-2,P.plank);
 s+=t(cx,13,day,5,P.text,'middle');
 s+=`<path d="M${cx-R} ${cy} A${R} ${R} 0 0 1 ${cx+R} ${cy}" stroke="#f6e3b0" stroke-width="2" fill="none"/>`;
 const a=Math.PI*(1-frac),x=cx+R*Math.cos(a),y=cy-R*Math.sin(a);
 s+=`<circle cx="${x}" cy="${y}" r="3" fill="#ffd24a"/>`+t(cx,cy+9,label,5,P.text,'middle');return s}
// a small bound journal: the save mark
function journal(x,y,op=1){return `<g opacity="${op}">`+r(x,y,9,11,P.plankDk)+r(x+1,y+1,7,9,'#e9d6a8')+r(x+1,y+1,2,9,'#b8462e')+r(x+4,y+4,3,1,P.wood)+r(x+4,y+6,3,1,P.wood)+`</g>`}
function journalX(x,y){return journal(x,y)+r(x+5,y+7,6,6,'#fff6e0')+`<path d="M${x+6} ${y+8} L${x+10} ${y+12} M${x+10} ${y+8} L${x+6} ${y+12}" stroke="#5c3a22" stroke-width="1.2"/>`}
const band=(w,y=150)=>r(40,y,240,16,'#000','opacity=".45"')+t(160,y+11,w,6,P.text,'middle');
function fig(title,sub,inner){return `<figure>${svg(inner)}<figcaption><b>${title}</b><span>${sub}</span></figcaption></figure>`}
const CSS=`<link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet"><style>:root{--bg:#f7efe0;--ink:#2b2230;--dim:#7a6b5e;--card:#fffaf0}
@media (prefers-color-scheme:dark){:root{--bg:#17151c;--ink:#efe6d6;--dim:#a79a8c;--card:#221f29}}
body{background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,sans-serif;margin:0;padding:24px 16px}
h1{font-size:22px;margin:0 0 4px}.lede{color:var(--dim);max-width:75ch;margin:0 0 20px}
.strip{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:16px}
figure{margin:0;background:var(--card);border-radius:8px;padding:8px}
svg.px{width:100%;height:auto;display:block;image-rendering:pixelated;border-radius:3px}
figcaption{font-size:13px;padding:6px 2px 0}figcaption b{display:block}figcaption span{color:var(--dim)}
.cost{background:var(--card);border-left:4px solid #d9ae62;padding:8px 12px;max-width:75ch;border-radius:4px;margin:16px 0}
text{font-family:'Press Start 2P',monospace}</style>`;
document.head.insertAdjacentHTML('beforeend',CSS);
function page(h,lede,figs,cost){document.body.innerHTML=`<h1>${h}</h1><p class="lede">${lede}</p><div class="strip">${figs.join('')}</div>${cost?`<div class="cost">${cost}</div>`:''}`}
// ---- pause menu additions
const dim=(o=.45)=>r(0,0,320,180,'#0d0a10',`opacity="${o}"`);
const plank=(x,y,w,label,sel,h=14)=>r(x,y,w,h,sel?'#fff1c9':P.plankDk)+r(x+1,y+1,w-2,h-2,sel?'#c98a4a':P.plank)+t(x+w/2,y+h/2+2.5,label,5,P.text,'middle');
const key=(x,y,k)=>{const w=k.length*5+4;return [r(x,y,w,9,'none','stroke="#fff6e0" stroke-width="1"')+t(x+w/2,y+7,k,4,P.text,'middle'),w]};
function hint(pairs){let x=6,s='';const parts=[];for(const [k,l] of pairs){const [ks,w]=key(x+3,168,k);parts.push(ks+t(x+w+6,175,l,4));x+=w+l.length*4+14}return r(4,165,x-2,14,'#1b1420','opacity=".7"')+parts.join('')}
const HSB=hint([['ENTER','Select'],['ESC','Back']]);
function menuA(sel){const x=105,y=42,w=110;return dim()+r(x,y,w,98,P.plankDk)+r(x+2,y+2,w-4,94,'#6d4527')+t(160,y+16,'Paused',7,P.text,'middle')+['Resume','Settings','Quit to title'].map((l,i)=>plank(x+12,y+28+i*20,w-24,l,i==sel)).join('')}
function menuB(sel,day='DAY 3',time='16:30'){return dim(.3)+r(0,0,112,180,P.plankDk)+r(0,0,110,180,'#6d4527')+t(55,24,'Paused',7,P.text,'middle')+t(55,40,day+'  '+time,5,'#ffe2a8','middle')+['Resume','Settings','Quit to title'].map((l,i)=>plank(12,56+i*20,86,l,i==sel)).join('')}
function confirmBox(lines,btns,sel){let s=dim(.55)+r(56,50,208,80,'#fff1c9')+r(58,52,204,76,P.plank);lines.forEach((l,i)=>s+=t(160,66+i*11,l,i?4.5:6,i?'#ffe2a8':P.text,'middle'));const bw=80,gap=12,x0=160-(bw*btns.length+gap*(btns.length-1))/2;btns.forEach((b,i)=>s+=plank(x0+i*(bw+gap),108,bw,b,i==sel,13));return s}
function storyPic(){return r(0,0,320,180,'#2a3550')+r(0,110,320,70,'#1f4a66')+r(120,70,90,30,P.woodDk,'transform="skewX(-15)"')+r(160,30,4,45,P.woodDk)+r(164,32,30,24,'#d8c9a8')+r(20,150,280,18,'#000','opacity=".5"')+t(160,162,'The storm came out of nowhere.',5,P.text,'middle')}
const EXTRA=`<style>.q{font:600 16px system-ui;margin:28px 0 8px}.opt{display:inline-block;background:#d9ae62;color:#2b2230;font:700 12px system-ui;padding:2px 8px;border-radius:4px;margin-right:6px}</style>`;
document.head.insertAdjacentHTML('beforeend',EXTRA);
