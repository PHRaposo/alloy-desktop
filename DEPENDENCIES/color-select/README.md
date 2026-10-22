# color-select

Invoke the operating system's native colour-selection dialog and get back an
(r g b) colour. Standalone library; mirrors the structure of file-select ([SOURCE CODE](https://codeberg.org/shinmera/file-select)).

## API

color-select:choose-color:

Open the native colour picker. Returns (values COLOR SUCCESS).

COLOR is a list (R G B) of single-floats in [0,1], or NIL.
DEFAULT, when given, is a list (R G B) to preselect.
FULL-OPEN T shows the expanded picker; NIL shows the basic palette only.
PREVENT-FULL-OPEN T hides the expand button (palette-only).
FULL-OPEN/PREVENT-FULL-OPEN apply to the win32 and macos backends.
If no BACKEND is specified, *DEFAULT-BACKEND* is used."

```
(color-select:choose-color &key title default backend full-open prevent-full-open)
  ;; => (values COLOR SUCCESS)
```

## TODO 

Not tested on Linux. 

