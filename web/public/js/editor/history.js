export class History{
  constructor(limit=200){this.limit=limit;this.undoStack=[];this.redoStack=[]}
  execute(command){command.apply();this.undoStack.push(command);if(this.undoStack.length>this.limit)this.undoStack.shift();this.redoStack=[]}
  changes(canvas,changes){const normalized=changes.filter(c=>c.index>=0&&c.index<canvas.cells.length).map(c=>({...c,before:{...canvas.cells[c.index]},after:{...c.after}}));if(normalized.length)this.execute({apply:()=>normalized.forEach(c=>canvas.cells[c.index]={...c.after}),undo:()=>[...normalized].reverse().forEach(c=>canvas.cells[c.index]={...c.before})})}
  undo(){const c=this.undoStack.pop();if(!c)return false;c.undo();this.redoStack.push(c);return true}
  redo(){const c=this.redoStack.pop();if(!c)return false;c.apply();this.undoStack.push(c);return true}
  clear(){this.undoStack=[];this.redoStack=[]}
}
