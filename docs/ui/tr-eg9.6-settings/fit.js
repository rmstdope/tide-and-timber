// ---- too-wide rows at Large / Largest (tr-eg9.6.3)
const HI='#fff1c9',HIf='#c98a4a',QUIET='#d9c7a3',DIMA='#a08060';
const box=(x,y,w,h,sel)=>r(x,y,w,h,sel?HI:P.plankDk)+r(x+1,y+1,w-2,h-2,sel?HIf:P.plank);
// everything in a 160x90 local space, drawn twice as big (Largest)
const big=inner=>g(2,0,0,inner);
const bigHint=()=>g(2,4,179,hint([['ENTER','Select'],['ESC','Back']]));
const arrows=(cx,y,val,first,last)=>t(cx,y,val,5,P.text,'middle')+t(cx-val.length*3-8,y,'◀',5,first?DIMA:P.text,'middle')+t(cx+val.length*3+8,y,'▶',5,last?DIMA:P.text,'middle');
// side by side, as at Normal
function rowSide(x,y,w,label,val,sel,first,last){return box(x,y,w,14,sel)+t(x+6,y+9.5,label,5)+(val===null?t(x+w-6,y+10,'›',6,P.text,'end'):arrows(x+w-6-val.length*3-10,y+9.5,val,first,last))}
// stacked: name on top, value underneath
function rowStack(x,y,w,label,val,sel,first,last){return box(x,y,w,23,sel)+t(x+6,y+9,label,5)+(val===null?t(x+w-6,y+10,'›',6,P.text,'end'):arrows(x+w/2,y+19,val,first,last))}
const scrollMark=(y,up)=>t(80,y,up?'▲':'▼',5,QUIET,'middle');
const sky=()=>r(0,0,320,180,'#2c1d16');
const ROWS=[['UI size','Largest',0,1],['Text size','Normal',1,0],['Colour cues','Standard',1,0],['Controls',null,0,0]];
function settingsSide(scale=2,off=0){const w=180,x=(160/scale*1)-w/2;return g(scale,0,0,t(160/scale,14,'Settings',8,P.text,'middle')+ROWS.map((R,i)=>rowSide(x,22+i*17,w,R[0],R[1],i==0,R[2],R[3])).join(''))}
function settingsStack(sel=0,top=0){let s=t(80,12-top,'Settings',8,P.text,'middle');ROWS.forEach((R,i)=>{s+=rowStack(5,18+i*26-top,150,R[0],R[1],i==sel,R[2],R[3])});
 const D=['Makes the clock, item bar, hints and menus bigger.','Makes every word bigger.','Adds shapes to warnings shown in colour.','Change any key or controller button.'];
 return sky()+big(s+r(0,0,160,17,'#2c1d16')+(top?scrollMark(15,1):t(80,12,'Settings',8,P.text,'middle'))+r(0,72,160,18,'#2c1d16')+scrollMark(78,0))+bigHint()}
const slot=(x,y,k,sel,empty)=>{const w=34;return r(x,y,w,11,sel?HI:'#6d4527')+r(x+1,y+1,w-2,9,sel?HIf:'#6d4527')+t(x+w/2,y+8,empty?'—':k,4.5,empty?'#e8903a':P.text,'middle')};
function controlsStack(){let s=t(80,12,'Controls',8,P.text,'middle');
 [['Walk right','D','→',1],['Use','E',null,0]].forEach((R,i)=>{const y=18+i*26;s+=box(5,y,150,23,0)+t(11,y+9,R[0],5)+slot(40,y+11,R[1],R[3])+slot(86,y+11,R[2],0,R[2]===null)});
 return sky()+big(s+scrollMark(78,0))+bigHint()}
function controlsSide(){const w=210,x=-25;let s=t(80,12,'Controls',8,P.text,'middle');
 [['Walk right','D','→',1],['Walk left','A','←',0],['Use','E',null,0]].forEach((R,i)=>{const y=20+i*16;s+=box(x,y,w,14,0)+t(x+6,y+9.5,R[0],5)+slot(x+w-80,y+2,R[1],R[3])+slot(x+w-40,y+2,R[2],0,R[2]===null)});
 return sky()+big(s)+bigHint()}
function boxStack(){return beach()+dim(.55)+big(r(10,4,140,72,HI)+r(11,5,138,70,P.plank)+t(80,16,'Quit to title?',6,P.text,'middle')+t(80,27,'Anything since this morning',4,'#ffe2a8','middle')+t(80,33,'will be lost.',4,'#ffe2a8','middle')+plank(30,41,100,'Try again',1,13)+plank(30,58,100,'Keep playing',0,13))+bigHint()}
function boxSide(){return beach()+dim(.55)+big(r(-15,20,190,52,HI)+r(-14,21,188,50,P.plank)+t(80,32,'Quit to title?',6,P.text,'middle')+t(80,42,'Anything since this morning will be lost.',4,'#ffe2a8','middle')+plank(-5,52,85,'Try again',1,13)+plank(85,52,85,'Keep playing',0,13))+bigHint()}
const BUILD=[['Lean-to','3 Driftwood'],['Fire','Needs a lean-to'],['Water still','2 Stone, 1 Leaf']];
function buildStack(){let s=t(80,12,'Build',8,P.text,'middle');BUILD.forEach((B,i)=>{const y=18+i*24;s+=box(5,y,150,21,i==1)+t(11,y+9,B[0],5)+t(11,y+17,B[1],4,i==1?'#fff6e0':QUIET)});return beach()+dim(.55)+big(s.replace('Water still','')+scrollMark(71,0))+bigHint()}
function buildSide(){let s=t(80,12,'Build',8,P.text,'middle');BUILD.forEach((B,i)=>{const y=20+i*16;s+=box(-5,y,170,14,i==1)+t(1,y+9.5,B[0],5)+t(159,y+9.5,B[1],4,QUIET,'end')});return beach()+dim(.55)+big(s)+bigHint()}
function hudBig(){return g(2,6,4,dial(.55,'16:30','DAY 2'))+g(2,160,178,bar())}

// which rows stack
const MIX=[['UI size','Largest',0,1],['Text size','Normal',1,0],['Controls',null,0,0]];
function stackAll(){let s=t(80,12,'Settings',8,P.text,'middle');MIX.forEach((R,i)=>{s+=rowStack(5,18+i*26,150,R[0],R[1],i==2,R[2],R[3])});return sky()+big(s+r(0,72,160,18,'#2c1d16'))+bigHint()}
function stackEach(){let s=t(80,12,'Settings',8,P.text,'middle');const y=[18,44,70];MIX.forEach((R,i)=>{s+=(R[1]===null?rowSide(5,y[i],150,R[0],null,i==2,0,0):rowStack(5,y[i],150,R[0],R[1],0,R[2],R[3]))});return sky()+big(s)+bigHint()}
