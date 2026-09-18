// ---- fullscreen additions (tr-1tj)
// rows: [{label, val|null, first, last}], desc: line under list
function fsScreen(rows,sel,desc,sc=1){const w=200*sc,x=160-w/2,h=14*sc,gap=18*sc,y0=92-gap*rows.length/2;
 return settingsBg()+t(160,y0-14*sc,'Settings',8*sc,P.text,'middle')+
 rows.map((rw,i)=>vrow(x,y0+gap*i,w,rw.label,rw.val,sel==i,rw.first,rw.last,sc,h)).join('')+
 t(160,y0+gap*rows.length+10*sc,desc,4*sc,'#d9c7a3','middle')+g(sc,4,179,hint([['ENTER','Select'],['ESC','Back']]))}
const R={ui:{label:'UI size',val:'Normal',first:1,last:0},tx:{label:'Text size',val:'Normal',first:1,last:0},cc:{label:'Colour cues',val:'Standard',first:1,last:0},ct:{label:'Controls',val:null}};
// a desktop with the game either in a window or filling the screen; inner is a 320x180 game picture
function desk(full,inner,note){let s=r(0,0,320,180,'#3b4a63')+r(0,0,320,7,'#d7dbe2')+t(6,5.5,'  File  Edit  View',4,'#333');
 if(full) return r(0,0,320,180,'#000')+`<g transform="translate(0 0) scale(1)">${inner}</g>`+(note||'');
 s+=r(40,18,240,146,'#c9ccd3')+r(40,18,240,9,'#e6e8ec')+`<circle cx="46" cy="22.5" r="2" fill="#e0443e"/><circle cx="53" cy="22.5" r="2" fill="#dea123"/><circle cx="60" cy="22.5" r="2" fill="#1aab29"/>`+t(160,25,'Tide and Timber',4,'#333','middle');
 s+=`<g transform="translate(40 27) scale(0.75)">${inner}</g>`;return s+(note||'')}
function titleScr(){return r(0,0,320,180,'#f2a65a')+r(0,90,320,90,'#1f6a8a')+r(0,90,320,3,'#ffd9a0')+`<circle cx="230" cy="92" r="22" fill="#ffd24a"/>`+r(0,120,320,60,'#e7c07a')+r(40,98,6,26,P.woodDk)+r(24,90,40,10,P.palm)+t(160,40,'Tide and Timber',10,P.text,'middle')+plank(115,64,90,'New Game',1)+plank(115,82,90,'Settings',0)+plank(115,100,90,'Quit',0)+hint([['ENTER','Select']])}
function waitBox(line2){let s=settingsBg()+t(160,30,'Controls',8,P.text,'middle');['Walk up','Walk down','Use','Build'].forEach((a,i)=>s+=r(50,44+i*16,220,13,i==2?'#c98a4a':P.plank)+t(56,53+i*16,a,5)+t(262,53+i*16,i==2?(line2||'E'):['W','S','E','B'][i],5,P.text,'end'));
 if(line2)return s;return s+dim(.55)+r(80,62,160,56,'#fff1c9')+r(82,64,156,52,P.plank)+t(160,80,'Use',6,P.text,'middle')+t(160,94,'Press a new key',5,'#ffe2a8','middle')+t(160,108,'Hold [Esc] to cancel',4,'#ffe2a8','middle')}
