export const cell = (character=" ", foreground="#e5e7eb", background="#10141c", transparent=false) => ({character,foreground,background,transparent});
export const canvas = (width=80,height=30,fill=cell(" ",null,null,true)) => ({width,height,cells:Array.from({length:width*height},()=>({...fill}))});
export const cloneCanvas = c => ({width:c.width,height:c.height,cells:c.cells.map(v=>({...v}))});
export const layer = (width,height,name="Layer") => ({name,visible:true,locked:false,opacity:1,canvas:canvas(width,height)});
export const frame = (width,height) => ({duration_ms:100,layers:[layer(width,height)]});
export const project = (width=80,height=30) => ({magic:"ASCII-STUDIO",version:1,project:{name:"Untitled",author:null,created_at:new Date().toISOString(),updated_at:new Date().toISOString(),width,height,palette:"classic",settings:{}},animation:{default_fps:10,loop:true},frames:[frame(width,height)]});
export const clone = value => structuredClone(value);
export function flatten(frame){
  const first=frame.layers[0].canvas,out=canvas(first.width,first.height);
  for(const l of frame.layers) if(l.visible) l.canvas.cells.forEach((c,i)=>{if(!c.transparent)out.cells[i]={...c}});
  return out;
}
export function text(c){let lines=[];for(let y=0;y<c.height;y++)lines.push(c.cells.slice(y*c.width,(y+1)*c.width).map(v=>v.transparent?" ":v.character).join(""));return lines.join("\n")}
export function validate(p){
  if(p?.magic!=="ASCII-STUDIO"||p.version!==1||!Array.isArray(p.frames)||!p.frames.length)throw Error("Unsupported or malformed AAF");
  const {width,height}=p.project||{};if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width*height>1e6)throw Error("Invalid project dimensions");
  for(const f of p.frames){if(!Array.isArray(f.layers)||!f.layers.length)throw Error("Frame has no layers");for(const l of f.layers)if(l.canvas?.width!==width||l.canvas?.height!==height||l.canvas.cells?.length!==width*height)throw Error("Layer dimensions mismatch")}
  return p;
}
