// Controls page at Largest UI (everything x2), keyboard tab, title screen.
// Content is laid out in screen pixels; the band between the tabs and the Select/Back strip is 108 px tall.
const BAND=[46,136],BH=BAND[1]-BAND[0];
const ROWS=[['Walk up','W','↑'],['Walk down','S','↓'],['Walk left','A','←'],['Walk right','D','→'],['Run (hold)','SHIFT',null],['Use / take','E',null],['Build list','B',null],['Pause','ESC',null]];
const QUIET='#d9c7a3',ORANGE='#f09a3a';
function cap(x,y,k,sel){if(k===null)return t(x+14,y+12,'—',10,ORANGE,'middle');const w=Math.max(28,k.length*9+8);return r(x,y,w,16,'none',`stroke="${sel?'#2b2230':'#fff6e0'}" stroke-width="2"`)+t(x+w/2,y+12,k,8,sel?'#2b2230':P.text,'middle')}
function content(sel){let s='',y=0;
 ROWS.forEach((R,i)=>{const on=sel==i;s+=r(20,y,280,40,on?'#fff1c9':P.plankDk)+r(22,y+2,276,36,on?'#c98a4a':P.plank)+t(30,y+15,R[0],10)+cap(60,y+20,R[1],false)+cap(160,y+20,R[2],false);y+=44});
 const on=sel==8;s+=r(20,y,280,44,on?'#fff1c9':P.plankDk)+r(22,y+2,276,40,on?'#c98a4a':P.plank)+t(160,y+17,'Reset keyboard',10,P.text,'middle')+t(160,y+36,'to defaults',10,P.text,'middle');y+=48;
 s+=t(160,y+12,'Walk up has no key',9,ORANGE,'middle');y+=18;
 ['Menus always use the','arrow keys, Enter','and Esc'].forEach(l=>{s+=t(160,y+12,l,9,QUIET,'middle');y+=16});
 return [s,y]}
function controls(sel,off,note){const [c,h]=content(sel);const id='b'+Math.random().toString(36).slice(2);
 let s=settingsBg()+t(160,13,'Controls',11,P.text,'middle');
 s+=r(58,18,96,15,'#fff1c9')+r(59,19,94,13,P.plank)+t(106,30,'Keyboard',8,P.text,'middle')+r(166,18,104,15,P.plankDk)+r(167,19,102,13,'#6d4527')+t(218,30,'Controller',8,'#d9c7a3','middle');
 s+=`<clipPath id="${id}"><rect x="0" y="${BAND[0]}" width="320" height="${BH}"/></clipPath><g clip-path="url(#${id})"><g transform="translate(0 ${BAND[0]-off})">${c}</g></g>`;
 if(off>0)s+=t(160,BAND[0]-2,'▲',10,'#ffe2a8','middle');
 if(off<h-BH)s+=t(160,BAND[1]+10,'▼',10,'#ffe2a8','middle');
 s+=g(2,4,179,hint([['ENTER','Select'],['ESC','Back']]));
 if(note)s+=r(0,BAND[1]-24,320,0,'none');
 return s}
const RESET_TOP=8*44,BOTTOM=content(8)[1]-BH;
