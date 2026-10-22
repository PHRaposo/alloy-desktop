# font-select

Invoke the operating system's native font-selection dialog and get back an
a font description. Standalone library; mirrors the structure of file-select ([SOURCE CODE](https://codeberg.org/shinmera/file-select)).

## API

```
(font-select:select :default font :variant variant)
```

DEFAULT and the returned FONT-PLIST share one shape:

```
(:family STRING :size INTEGER :weight (:regular|:bold) :slant (:roman|:italic)).
;;; => (values (FONT-PLIST) SUCCESS)
```
On macOS the system font is returned as '(:family :system ...) (the literal
".AppleSystemUIFont" is not name-resolvable; the caller re-resolves).

VARIANT is one of :FULL (default), :COMPACT, :MINIMAL — selects how many widgets
the native dialog exposes. Honoured by the win32 backend; ignored by yad (and
by macos for now, until the validModesForFontPanel: bridge is implemented)."

EXAMPLE:

```
(font-select:select)
;;; (:FAMILY "Verdana" :SIZE 12 :WEIGHT :REGULAR :SLANT :ROMAN)
;;;  T
```

## TODO

Not tested on Linux.

