# ASCII Art Format v1

AAF v1 is UTF-8 JSON with `.aaf` extension. Readers must reject unknown magic/version values and validate dimensions before allocating cell matrices.

```json
{
  "magic": "ASCII-STUDIO",
  "version": 1,
  "project": {
    "name": "Untitled", "author": null,
    "created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-01T00:00:00Z",
    "width": 80, "height": 30, "palette": "classic", "settings": {}
  },
  "animation": {"default_fps": 10, "loop": true},
  "frames": [{
    "duration_ms": 100,
    "layers": [{
      "name": "Layer 1", "visible": true, "locked": false, "opacity": 1.0,
      "cells": [[{"character":"A","foreground":"#FFFFFF","background":null,"transparent":false}]]
    }]
  }]
}
```

`cells` is a height-sized array of width-sized rows. A character is exactly one Unicode scalar/grapheme as accepted by the implementation. Colors are null or `#RRGGBB`. Transparent cells do not affect compositing. Layer order is bottom-to-top; frame order is playback order. Duration is a positive integer in milliseconds.

Unknown keys must be ignored for forward-compatible additions. A new incompatible schema requires a new numeric version. v1 does not use Ruby object serialization or executable content.
