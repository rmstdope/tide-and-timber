// drawPad(el, {A:'Use',B:'Back',...}, highlight=[keys]) — Xbox-style positions: A south, B east, X west, Y north
function drawPad(id, m, hi){hi=hi||[];
 const b=(k,x,y,r,lab,side)=>{const on=m[k];const h=hi.includes(k);
  let s=`<g><circle cx="${x}" cy="${y}" r="${r}" fill="${on?(h?'#e0873a':'#c98a4a'):'#4a3f4f'}" stroke="${h?'#fff1c9':'#0d0a10'}" stroke-width="3"/><text x="${x}" y="${y+5}" text-anchor="middle" font-size="13" font-weight="700" fill="#1b1420">${k.length<3?k:''}</text></g>`;
  if(false){const tx=side=='l'?x-r-8:x+r+8;s+=`<text x="${tx}" y="${y+5}" text-anchor="${side=='l'?'end':'start'}" font-size="13" fill="${h?'#ffd27a':'#f4e3c1'}">${on}</text>`}return s};
 const rect=(k,x,y,w,hh,lab,lx,ly,anchor)=>{const on=m[k],h=hi.includes(k);return `<rect x="${x}" y="${y}" width="${w}" height="${hh}" rx="6" fill="${on?(h?'#e0873a':'#c98a4a'):'#4a3f4f'}" stroke="${h?'#fff1c9':'#0d0a10'}" stroke-width="3"/><text x="${x+w/2}" y="${y+hh/2+5}" text-anchor="middle" font-size="11" font-weight="700" fill="#1b1420">${lab}</text>`+(on?`<text x="${lx}" y="${ly}" text-anchor="${anchor}" font-size="13" fill="${h?'#ffd27a':'#f4e3c1'}">${on}</text>`:'')};
 let s=`<svg class="pad" viewBox="0 0 560 340" xmlns="http://www.w3.org/2000/svg">`;
 s+=`<path d="M150 90 Q280 60 410 90 Q470 100 490 200 Q505 290 450 300 Q410 305 380 250 L180 250 Q150 305 110 300 Q55 290 70 200 Q90 100 150 90Z" fill="#6d4527" stroke="#0d0a10" stroke-width="4"/>`;
 s+=rect('LB',120,52,70,20,'LB',120,40,'start')+rect('RB',370,52,70,20,'RB',440,40,'end');
 s+=rect('LT',130,18,50,26,'LT',125,32,'end')+rect('RT',380,18,50,26,'RT',435,32,'start');
 s+=rect('Back',235,120,30,16,'◂',235,112,'end')+rect('Start',295,120,30,16,'▸',325,112,'start');
 // left stick
 const ls=m.LS,h1=hi.includes('LS');s+=`<circle cx="150" cy="160" r="30" fill="${ls?(h1?'#e0873a':'#c98a4a'):'#4a3f4f'}" stroke="${h1?'#fff1c9':'#0d0a10'}" stroke-width="3"/><text x="150" y="165" text-anchor="middle" font-size="11" font-weight="700" fill="#1b1420">L</text>`;
 if(ls)s+=`<text x="10" y="235" font-size="13" fill="${h1?'#ffd27a':'#f4e3c1'}">stick: ${ls}</text>`;
 // dpad
 const dp=m.DP,h2=hi.includes('DP');const c=dp?(h2?'#e0873a':'#c98a4a'):'#4a3f4f';
 s+=`<path d="M210 205h20v-20h20v20h20v20h-20v20h-20v-20h-20z" fill="${c}" stroke="${h2?'#fff1c9':'#0d0a10'}" stroke-width="3"/>`;
 s+=`<text x="10" y="325" font-size="13" fill="${h2?'#ffd27a':'#f4e3c1'}">d-pad: ${dp||'nothing'}</text>`;
 const rs=m.RS;s+=`<circle cx="340" cy="215" r="24" fill="${rs?'#c98a4a':'#4a3f4f'}" stroke="#0d0a10" stroke-width="3"/><text x="340" y="220" text-anchor="middle" font-size="11" font-weight="700" fill="#1b1420">R</text>`;
 s+=`<text x="330" y="325" font-size="13" fill="#f4e3c1">right stick: ${rs||'nothing'}</text>`;
 s+=b('Y',410,125,15,'','r')+b('X',380,155,15,'','l')+b('B',440,155,15,'','r')+b('A',410,185,15,'','r');
 s+=`</svg>`;document.getElementById(id).innerHTML=s}
