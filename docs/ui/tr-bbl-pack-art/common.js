const IMG={};
function load(){return Promise.all(Object.entries(A).map(([k,v])=>new Promise(r=>{const i=new Image();i.onload=()=>{IMG[k]=i;r()};i.src=v})))}
function hex(h){return [parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)]}
function remap(ctx,x,y,w,h,pal){ if(!pal)return; const P=pal.map(hex); const d=ctx.getImageData(x,y,w,h);
  for(let i=0;i<d.data.length;i+=4){ if(!d.data[i+3])continue; let best=0,bd=1e9;
    for(let j=0;j<P.length;j++){const dr=d.data[i]-P[j][0],dg=d.data[i+1]-P[j][1],db=d.data[i+2]-P[j][2];const dd=2*dr*dr+4*dg*dg+3*db*db; if(dd<bd){bd=dd;best=j}}
    d.data[i]=P[best][0];d.data[i+1]=P[best][1];d.data[i+2]=P[best][2]; }
  ctx.putImageData(d,x,y)}
// draw a crop, optionally recoloured to a palette
function put(ctx,key,sx,sy,sw,sh,dx,dy,pal){ const c=document.createElement('canvas');c.width=sw;c.height=sh;const k=c.getContext('2d');
  k.drawImage(IMG[key],sx,sy,sw,sh,0,0,sw,sh); remap(k,0,0,sw,sh,pal); ctx.drawImage(c,dx,dy)}
function tile(ctx,key,sx,sy,x0,y0,x1,y1,pal){for(let y=y0;y<y1;y+=16)for(let x=x0;x<x1;x+=16)put(ctx,key,sx,sy,16,16,x,y,pal)}
function bbox(key,fx,fw,fh){const c=document.createElement('canvas');c.width=fw;c.height=fh;const k=c.getContext('2d');k.drawImage(IMG[key],fx,0,fw,fh,0,0,fw,fh);
  const d=k.getImageData(0,0,fw,fh).data;let x0=fw,y0=fh,x1=0,y1=0;for(let y=0;y<fh;y++)for(let x=0;x<fw;x++)if(d[(y*fw+x)*4+3]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}
  return {x0,y0,x1,y1}}
function canvas(el,w,h,scale){const c=document.createElement('canvas');c.width=w;c.height=h;c.style.width=w*scale+'px';c.style.height=h*scale+'px';el.appendChild(c);const x=c.getContext('2d');x.imageSmoothingEnabled=false;return x}
