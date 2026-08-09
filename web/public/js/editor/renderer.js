export class CanvasRenderer{
  constructor(canvas,logical){this.element=canvas;this.logical=logical;this.zoom=18;this.grid=true;this.selection=null}
  setCanvas(logical){this.logical=logical;this.draw()}
  coordinates(event){const r=this.element.getBoundingClientRect();return {x:Math.floor((event.clientX-r.left)*this.element.width/r.width/this.zoom),y:Math.floor((event.clientY-r.top)*this.element.height/r.height/this.zoom)}}
  draw(){const c=this.logical,z=this.zoom,el=this.element,ctx=el.getContext("2d");el.width=c.width*z;el.height=c.height*z;ctx.fillStyle="#10141c";ctx.fillRect(0,0,el.width,el.height);ctx.font=`${Math.floor(z*.82)}px ui-monospace,monospace`;ctx.textAlign="center";ctx.textBaseline="middle";
    c.cells.forEach((v,i)=>{const x=i%c.width,y=Math.floor(i/c.width);if(v.transparent)return;if(v.background){ctx.fillStyle=v.background;ctx.fillRect(x*z,y*z,z,z)}ctx.fillStyle=v.foreground||"#e5e7eb";ctx.fillText(v.character,x*z+z/2,y*z+z/2)});
    if(this.grid&&z>=12){ctx.strokeStyle="#33415566";ctx.lineWidth=1;ctx.beginPath();for(let x=0;x<=c.width;x++){ctx.moveTo(x*z+.5,0);ctx.lineTo(x*z+.5,el.height)}for(let y=0;y<=c.height;y++){ctx.moveTo(0,y*z+.5);ctx.lineTo(el.width,y*z+.5)}ctx.stroke()}
    if(this.selection){const s=this.selection;ctx.strokeStyle="#f4b942";ctx.setLineDash([4,3]);ctx.strokeRect(s.x*z+.5,s.y*z+.5,s.width*z,s.height*z);ctx.setLineDash([])}
  }
}
