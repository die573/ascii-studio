# Webcam modes

Browser mode is local-only:

```text
getUserMedia → video → small Canvas → ImageData → JS glyph loop → pre
```

Ruby/Puma mode is intentionally educational:

```text
camera → reduced Canvas → bounded JPEG → WebSocket → temporary file
       → shared ImageImporter → plain renderer → WebSocket → pre
```

The browser keeps at most one Ruby frame in flight, and the server rejects frames over 1 MiB and reports dropped work rather than building an unbounded queue. Messages carry IDs and browser timestamps; responses report server render milliseconds and the UI calculates round-trip/effective FPS. Temporary images are securely created and automatically removed.

Browser mode is normally faster and private because it avoids JPEG encoding, transport, server decoding, and response bandwidth. Permission errors are shown in the camera output, streams are stopped explicitly, and normal mode transmits nothing.
