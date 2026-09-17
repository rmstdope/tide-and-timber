// Tall box at Largest UI + Largest text, in the game. Everything x2.
const S=2;
function scene(stripHidden){let s=beach()+dim(.55);
 s+=g(3,160,178,bar()).replace(/<g /,'<g opacity="'+(stripHidden?'.35':'1')+'" ');
 if(!stripHidden) s+=g(S,4,150,hint([['ENTER','Select'],['ESC','Back']]).replace(/168/g,'122').replace(/175/g,'129').replace(/165/g,'119'));
 return s}
// content items: {k:'big'|'small'|'btn'|'pic', s:text}
const PAUSE=[{k:'big',s:'Quit to title?'},{k:'small',s:'Nothing has been'},{k:'small',s:'saved yet.'},{k:'btn',s:'Stay'},{k:'btn',s:'Quit'}];
const DAWN=[{k:'pic'},{k:'big',s:"The day couldn't"},{k:'big',s:'be saved.'},{k:'small',s:'Your progress since'},{k:'small',s:'yesterday may be lost'},{k:'small',s:'if you quit.'},{k:'btn',s:'Try again'},{k:'btn',s:'Keep playing'}];
const H={big:17,small:13,btn:28,pic:26};
function layout(items){let y=6,out=[];items.forEach((it,i)=>{if(it.k=='btn'&&items[i-1]&&items[i-1].k!='btn')y+=6;out.push({...it,y});y+=H[it.k]+(it.k=='btn'?4:0)});return {items:out,h:y+2}}
// draw box: band [top,bot] in screen px, off = scroll px, sel = button index (0/1), marks auto
function box(items,band,off,sel,opts={}){const L=layout(items),x=70,w=180;const fits=L.h<=band[1]-band[0];
 const top=band[0],ph=fits?L.h:band[1]-band[0],mr=fits?0:14,clipTop=top+mr,clipH=ph-2*mr;
 if(fits)off=0;
 let s=r(x,top,w,ph,'#fff1c9')+r(x+2,top+2,w-4,ph-4,P.plank);
 const id='c'+Math.random().toString(36).slice(2);
 s+=`<clipPath id="${id}"><rect x="${x}" y="${clipTop}" width="${w}" height="${fits?ph:clipH}"/></clipPath><g clip-path="url(#${id})">`;
 let bi=0;const base=(fits?top:clipTop)-(fits?0:6)-off+ (fits?0:0);
 L.items.forEach(it=>{const y=base+it.y;
  if(it.k=='big')s+=t(160,y+13,it.s,11,P.text,'middle');
  else if(it.k=='small')s+=t(160,y+10,it.s,8,'#ffe2a8','middle');
  else if(it.k=='pic')s+=g(2,155,y+2,journalX(155,y+2));
  else{s+=plank(x+30,y,w-60,it.s,bi==sel,26).replace(/font-size="5"/,'font-size="10"').replace(/(y=")([\d.]+)(" font-size="10")/,(m,a,b,c)=>a+(+b+3)+c);bi++}});
 s+='</g>';
 if(!fits){const more=L.h-6-clipH;if(off>0)s+=t(160,top+11,'▲',8,'#ffe2a8','middle');if(off<more)s+=t(160,top+ph-4,'▼',8,'#ffe2a8','middle')}
 if(opts.note)s+=r(0,0,320,12,'#000','opacity=".6"')+t(160,9,opts.note,6,'#ffe2a8','middle');
 return s}
