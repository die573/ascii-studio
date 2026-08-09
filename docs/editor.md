# Editor

The editor has three separate concerns:

- `model.js` owns AAF-compatible projects, frames, layers, canvases, and cells.
- `history.js` applies bounded before/after cell deltas.
- `renderer.js` draws the flattened logical canvas, grid, and selection on one browser Canvas.
- `editor.js` translates pointer/keyboard actions into model mutations.

Tools are pencil, transparent eraser, keyboard text, Bresenham line, outline and filled rectangles, four-neighbor bucket fill, eyedropper, and rectangular selection. Selections copy styled internal cells and also write plain multiline text to the browser clipboard when permission permits. Cut, paste, and Delete are reversible cell changes.

Layers can be added, duplicated, selected, hidden, locked, deleted, and merged down. Frames can be added, duplicated, selected, deleted, assigned durations, and played. AAF open/save keeps all cell colors and transparency.
