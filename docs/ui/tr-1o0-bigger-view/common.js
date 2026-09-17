// Shared drawing for tr-1o0. Colours, figures, fonts and sizes are placeholders for the real pixel art.
const P={sea:'#2f7f8c',seaDk:'#256a76',foam:'#d8e6e8',wet:'#c49a5a',sand:'#f0cf8a',sandDk:'#d9ae62',
 grass:'#6a9a3e',grassDk:'#4e7a2c',palm:'#3f7a3a',palmDk:'#2f5f2c',woodDk:'#5c3a22',wood:'#8a5a34',
 rock:'#8e8a84',rockDk:'#6b6762',skin:'#e0a172',shirt:'#b8462e',pants:'#3d4f6e',hair:'#4a2c1a',
 text:'#fff6e0',plank:'#8a5a34',plankDk:'#5c3a22',fire:'#e8892a'};
const r=(x,y,w,h,c,o='')=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" ${o}/>`;
const t=(x,y,s,sz=5,c=P.text,a='start',o='')=>`<text x="${x}" y="${y}" font-size="${sz}" fill="${c}" text-anchor="${a}" ${o}>${s}</text>`;

// ---- the island, in world pixels. 16px tiles, one scale everywhere.
// The real strip is 184x26 tiles (2944x416 px); this draws a 1024-wide slice of it, full height.
const MAPH=416, MAPW=1024;
const HIM={x:512,y:230};
function island(){
 let s=r(0,0,MAPW,96,P.sea);
 for(let x=0;x<MAPW;x+=16)for(let y=0;y<96;y+=32)if((x+y)%64===0)s+=r(x,y+8,10,2,P.seaDk);
 s+=r(0,96,MAPW,8,P.foam)+r(0,104,MAPW,20,P.wet)+r(0,124,MAPW,176,P.sand);
 for(let x=0;x<MAPW;x+=16)for(let y=128;y<300;y+=16)if((x*7+y*3)%80===0)s+=r(x+5,y+6,3,2,P.sandDk);
 s+=r(0,300,MAPW,MAPH-300,P.grass);
 for(let x=0;x<MAPW;x+=16)for(let y=304;y<MAPH;y+=16)if((x*5+y)%48===0)s+=r(x+4,y+4,3,3,P.grassDk);
 s+=r(232,52,26,14,P.rock)+r(236,48,14,6,P.rockDk)+r(700,60,20,12,P.rock)+r(704,56,10,5,P.rockDk);
 [[300,336],[430,330],[640,344],[790,334],[180,340],[900,346]].forEach(([x,y])=>{
  s+=r(x,y,6,34,P.woodDk)+r(x-18,y-12,42,12,P.palm)+r(x-12,y-18,30,7,P.palmDk)});
 s+=r(268,206,48,6,P.wood)+r(266,212,6,22,P.woodDk)+r(312,212,6,22,P.woodDk)
   +r(300,244,18,6,'#3a2a1c')+r(304,236,4,8,P.fire)+r(308,234,4,10,'#f6c445');
 s+=r(600,150,26,5,P.wood)+r(452,262,18,4,P.wood)+r(742,196,14,14,P.wood)+r(744,198,10,10,P.woodDk);
 s+=r(560,140,3,3,P.sandDk)+r(566,148,3,3,P.sandDk)+r(372,178,4,3,'#e9d6cf');
 return s}
function man(x,y){return r(x-3,y-14,6,6,P.skin)+r(x-3,y-14,6,2,P.hair)
 +r(x-4,y-8,8,7,P.shirt)+r(x-3,y-1,2,5,P.pants)+r(x+1,y-1,2,5,P.pants)}
// A window W x H of the island, centred on (cx,cy). Anything past the island's edge is black.
function viewAt(cx,cy,W,H,overlay='',him=HIM){
 const x0=Math.round(cx-W/2), y0=Math.round(cy-H/2);
 return `<svg class="px" viewBox="0 0 ${W} ${H}" shape-rendering="crispEdges">`
  +r(0,0,W,H,'#000')+`<g transform="translate(${-x0} ${-y0})">${island()}${man(him.x,him.y)}</g>${overlay}</svg>`}
function view(W,H,overlay=''){return viewAt(HIM.x,HIM.y,W,H,overlay)}

// ---- the overlay, in screen pixels. u = 1 draws it at exactly today's pixel sizes.
function clock(u,day='DAY 2',time='16:30'){const x=4*u,y=4*u,w=64*u,h=54*u,cx=x+32*u;
 let s=r(x,y,w,h,P.plankDk)+r(x+u,y+u,w-2*u,h-2*u,P.plank)+t(cx,y+12*u,day,8*u,P.text,'middle');
 const dcx=cx,dcy=y+32*u,R=14*u;
 s+=`<path d="M${dcx-R} ${dcy} A${R} ${R} 0 0 1 ${dcx+R} ${dcy}" stroke="#f6e3b0" stroke-width="${2*u}" fill="none"/>`;
 const a=Math.PI*0.42,px=dcx+R*Math.cos(a),py=dcy-R*Math.sin(a);
 return s+r(px-3.5*u,py-3.5*u,7*u,7*u,'#ffd24a')+t(cx,y+50*u,time,8*u,P.text,'middle')}
function items(u,W,H,n=4,counts=true){const w=141*u,h=22*u,x=Math.round((W-w)/2),y=H-23*u;
 let s=r(x,y,w,h,P.plankDk)+r(x+u,y+u,w-2*u,h-2*u,P.plank);
 for(let i=0;i<8;i++){const sx=x+3*u+i*17*u;s+=r(sx,y+3*u,16*u,16*u,'#6d4527');
  if(i<n)s+=r(sx+4*u,y+6*u,8*u,7*u,['#5a8fd0','#c0433a','#e0c060','#7a5a3a'][i])+(counts?t(sx+13*u,y+15*u,String(i+2),5*u):'')}
 return s}
function hints(u,W,H,pairs=[['E','Gather'],['TAB','Build']],lift=false){let x=4*u,parts='';
 const y=lift?H-37*u:H-16*u;
 pairs.forEach(([k,l])=>{const kw=(k.length*6+6)*u;
  parts+=r(x+3*u,y+2*u,kw,9*u,'none',`stroke="#fff6e0" stroke-width="${u}"`)+t(x+3*u+kw/2,y+9.5*u,k,5*u,P.text,'middle')
        +t(x+kw+9*u,y+9.5*u,l,8*u);x+=kw+l.length*6.6*u+22*u});
 return r(4*u,y,x-2*u,12*u,'#1b1420','opacity=".7"')+parts}
function spoken(u,W,H,txt='Driftwood. That will burn.'){const y=H-57*u,h=16*u,w=W-24*u;
 return r(12*u,y,w,h,'#000','opacity=".45"')+t(W/2,y+11.5*u,txt,8*u,P.text,'middle')}
function overlay(u,W,H,opts={}){return clock(u)+items(u,W,H)+hints(u,W,H,[['E','Gather']],true)+(opts.noLine?'':spoken(u,W,H))}

// ---- boards
const dim=(W,H,o=.45)=>r(0,0,W,H,'#0d0a10',`opacity="${o}"`);
function plank(x,y,w,h,label,sel,u){return r(x,y,w,h,sel?'#fff1c9':P.plankDk)+r(x+u,y+u,w-2*u,h-2*u,sel?'#c98a4a':P.plank)
 +t(x+w/2,y+h/2+2.5*u,label,5*u,P.text,'middle')}
function pauseBoard(u,W,H,sel=0){const w=110*u,h=98*u,x=Math.round(W/2-w/2),y=Math.round(H/2-h/2);
 return dim(W,H)+r(x,y,w,h,P.plankDk)+r(x+2*u,y+2*u,w-4*u,h-4*u,'#6d4527')+t(W/2,y+16*u,'Paused',7*u,P.text,'middle')
 +['Resume','Settings','Quit to title'].map((l,i)=>plank(x+12*u,y+28*u+i*20*u,w-24*u,14*u,l,i==sel,u)).join('')}
function vrow(x,y,w,h,label,val,sel,u){const vx=x+w-8*u;
 return r(x,y,w,h,sel?'#fff1c9':P.plankDk)+r(x+u,y+u,w-2*u,h-2*u,sel?'#c98a4a':P.plank)+t(x+6*u,y+h/2+2.5*u,label,5*u)
 +(val===null?t(vx,y+h/2+2.5*u,'›',6*u,P.text,'end')
  :t(vx-8*u,y+h/2+2.5*u,val,5*u,P.text,'end')+t(vx,y+h/2+2.5*u,'▶',5*u,P.text,'end')
   +t(vx-11*u-val.length*3.2*u,y+h/2+2.5*u,'◀',5*u,P.text,'end'))}
const ROWS=[['UI size','Normal'],['Text size','Normal'],['Colour cues','Standard'],['Controls',null],['Sound','Half'],['Music','Half'],['Full screen','Off'],['Language','English']];
function settings(u,W,H,sel=0,rows=ROWS,head=true){const w=200*u,x=Math.round(W/2-w/2),gap=18*u;
 const top=head?Math.round(H/2-(rows.length*gap+30*u)/2):20*u;
 let s=r(0,0,W,H,'#2c1d16')+t(W/2,top+14*u,'Settings',8*u,P.text,'middle');
 rows.forEach((rw,i)=>{s+=vrow(x,top+28*u+i*gap,w,14*u,rw[0],rw[1],i==sel,u)});
 s+=t(W/2,top+28*u+rows.length*gap+10*u,'How big the boxes, bars and buttons are.',4*u,'#d9c7a3','middle');
 return s+hints(u,H,[['ENTER','Select'],['ESC','Back']])}

// ---- page furniture
const CSS=`<link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet"><style>
:root{--bg:#f7efe0;--ink:#2b2230;--dim:#7a6b5e;--card:#fffaf0;--edge:#e4d7c0}
@media (prefers-color-scheme:dark){:root{--bg:#17151c;--ink:#efe6d6;--dim:#a79a8c;--card:#221f29;--edge:#3a3442}}
body{background:var(--bg);color:var(--ink);font:15px/1.55 system-ui,sans-serif;margin:0;padding:24px 16px;max-width:1500px}
h1{font-size:22px;margin:0 0 4px}.lede{color:var(--dim);max-width:78ch;margin:0 0 20px}
.strip{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:18px}
.strip.two{grid-template-columns:repeat(auto-fill,minmax(520px,1fr))}
figure{margin:0;background:var(--card);border:1px solid var(--edge);border-radius:8px;padding:8px}
svg.px{width:100%;height:auto;display:block;image-rendering:pixelated;border-radius:3px}
figcaption{font-size:13px;padding:6px 2px 0}figcaption b{display:block}figcaption span{color:var(--dim)}
.cost{background:var(--card);border-left:4px solid #d9ae62;padding:10px 12px;max-width:78ch;border-radius:4px;margin:18px 0}
.q{font:600 16px system-ui;margin:28px 0 8px}.opt{display:inline-block;background:#d9ae62;color:#2b2230;font:700 12px system-ui;padding:2px 8px;border-radius:4px;margin-right:6px}
a{color:inherit}
text{font-family:'Press Start 2P',monospace}</style>`;
document.head.insertAdjacentHTML('beforeend',CSS);
function fig(title,sub,inner){return `<figure>${inner}<figcaption><b>${title}</b><span>${sub}</span></figcaption></figure>`}
function page(h,lede,figs,cost,two){document.body.innerHTML=`<h1>${h}</h1><p class="lede">${lede}</p><div class="strip${two?' two':''}">${figs.join('')}</div>${cost?`<div class="cost">${cost}</div>`:''}`}

// ---- the four real Settings rows
const SROWS=[['UI size','Normal'],['Text size','Normal'],['Colour cues','Standard'],['Controls',null]];
// Settings board: panel 304x138 at (8,21) in base units, four 200x16 rows from y 28, step 20.
function settingsBoard(u,W,H,vals=SROWS,sel=0,step=20,rowh=16){
 const pw=Math.min(304*u,W-16*u),px=Math.round(W/2-pw/2);
 const ph=Math.min(138*u,H-42*u),py=Math.round(H/2-ph/2);
 let s=r(0,0,W,H,'#2c1d16')+r(px,py,pw,ph,P.plankDk)+r(px+2*u,py+2*u,pw-4*u,ph-4*u,'#6d4527')
  +t(W/2,py+14*u,'Settings',8*u,P.text,'middle');
 const rw=Math.min(200*u,pw-24*u),rx=Math.round(W/2-rw/2);
 vals.forEach((rw2,i)=>{const y=py+28*u+i*step*u; if(y+rowh*u<py+ph-20*u||true) s+=vrow(rx,y,rw,rowh*u,rw2[0],rw2[1],i==sel,u)});
 s+=t(W/2,py+ph-22*u,'How big the boxes, bars',8*u,'#d9c7a3','middle')
   +t(W/2,py+ph-10*u,'and buttons are.',8*u,'#d9c7a3','middle');
 return s+hints(u,W,H,[['ENTER','Select'],['ESC','Back']])}
// Pause board: panel 144x96 centred, three 120x16 planks from y 28, step 20.
function pause(u,W,H,sel=0){const pw=144*u,ph=96*u,x=Math.round(W/2-pw/2),y=Math.round(H/2-ph/2);
 return dim(W,H)+r(x,y,pw,ph,P.plankDk)+r(x+2*u,y+2*u,pw-4*u,ph-4*u,'#6d4527')
  +t(W/2,y+14*u,'Paused',8*u,P.text,'middle')
  +['Resume','Settings','Quit to title'].map((l,i)=>plank(x+12*u,y+28*u+i*20*u,120*u,16*u,l,i==sel,u)).join('')
  +hints(u,W,H,[['ENTER','Select'],['ESC','Back']])}
const scr=(W,H,inner)=>`<svg class="px" viewBox="0 0 ${W} ${H}" shape-rendering="crispEdges">${r(0,0,W,H,'#000')}${inner}</svg>`;
const big=(W,H,k,inner)=>`<svg class="px" viewBox="0 0 ${W} ${H}" shape-rendering="crispEdges">${r(0,0,W,H,'#000')}<g transform="scale(${k})">${inner}</g></svg>`;

// ---- the title screen. Objects keep their art-pixel size; bands follow the screen.
function titleArt(W,H){const q=(f)=>Math.round(H*f);
 let s=r(0,0,W,q(.211),'#8fb7d8')+r(0,q(.211),W,q(.167),'#bcd0e0')+r(0,q(.378),W,q(.172),'#e8d3a8');
 s+=r(Math.round(W/2-16),q(.389),32,29,'#f6e3a0');
 s+=r(0,q(.55),W,q(.144),P.sea)+r(0,q(.694),W,q(.111),P.seaDk)+r(0,q(.805),W,q(.022),P.wet)+r(0,q(.828),W,H-q(.828),P.sand);
 s+=r(20,q(.528),6,55,P.woodDk)+r(3,q(.494),40,6,P.palm)+r(3,q(.528),40,3,P.palmDk);
 const wx=Math.round(W*.62);
 s+=r(wx,q(.6),54,16,P.woodDk)+r(wx+10,q(.55),4,32,P.woodDk)+r(wx+14,q(.56),22,14,'#d8c9a8');
 s+=r(20,q(.639),30,2,P.foam)+r(100,q(.678),20,2,P.foam)+r(Math.round(W*.6),q(.722),45,2,P.foam);
 return s}
function titleScreen(W,H,u){let s=titleArt(W,H);
 s+=t(W/2,Math.round(H*.189),'TIDE &amp; TIMBER',16*u,P.text,'middle');
 s+=t(W/2,Math.round(H*.256),'A man, an island, and the tide.',8*u,'#2b2230','middle');
 const pw=90*u,px=Math.round(W/2-pw/2),top=Math.round(H*.46);
 ['Continue','New Game','Settings','Quit'].forEach((l,i)=>{s+=plank(px,top+i*20*u,pw,17*u,l,i==0,u)});
 return s+hints(u,W,H,[['ENTER','Select']])}
// ---- a story picture (the wreck), drawn in art pixels for a W x H canvas.
function storyArt(W,H){let s=r(0,0,W,H,'#2a3550')+r(0,Math.round(H*.61),W,H,'#1f4a66');
 for(let x=0;x<W;x+=24)s+=r(x,Math.round(H*.61)+6+((x/24)%3)*7,14,2,'#2d6a86');
 const cx=Math.round(W*.42),cy=Math.round(H*.44);
 s+=r(cx,cy,110,34,P.woodDk)+r(cx+8,cy-6,94,8,P.wood)+r(cx+46,cy-52,5,52,P.woodDk)
  +r(cx+51,cy-48,36,28,'#d8c9a8')+r(cx+20,cy+34,16,10,P.woodDk);
 s+=r(Math.round(W*.16),Math.round(H*.2),3,3,'#e8eef6')+r(Math.round(W*.78),Math.round(H*.14),3,3,'#e8eef6');
 return s}
function storyScreen(W,H,u){const bh=22*u,by=H-42*u;
 return storyArt(W,H)+r(0,by,W,bh,'#000','opacity=".55"')+t(W/2,by+15*u,'The storm came out of nowhere.',8*u,P.text,'middle')
 +r(W-16*u,7*u,8*u,8*u,'#fff6e0')}
