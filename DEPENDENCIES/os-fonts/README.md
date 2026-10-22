# os-fonts

`os-fonts` is a small Common Lisp provider for operating-system UI font roles.

The public contract is intentionally small:

```lisp
(os-fonts:system-font)
(os-fonts:system-fixed-font)
(os-fonts:font-for-role :menu)
(os-fonts:logical-dpi)
(os-fonts:snapshot)
(os-fonts:poll)        ; event-loop friendly, default 0.5 s
(os-fonts:generation (os-fonts:default-backend))
```

A `font-spec` contains the native role, resolved family, native/generic family,
point size, weight, slant and source. The native logical DPI is stored separately
in the `font-state`.

## Dynamic updates

`poll` performs no work until its interval expires. It then re-reads the native
state and compares it with the previous snapshot. When a family, point size,
weight, slant or logical DPI changes, the backend generation is incremented and
registered listeners are called synchronously on the caller's thread.

This is deliberate: GTK/AppKit calls remain on the UI thread and the library does
not introduce a foreign event thread. A GUI application can call `poll`
from its normal event pump and react by invalidating native-role font objects,
reflowing text and redrawing existing windows.

## Backends

* Linux: GtkSettings (`gtk-font-name`, `gtk-xft-dpi`) through CFFI; fontconfig is
  queried through CFFI to resolve generic `Sans`/`monospace` families. 
* Windows: `SystemParametersInfoW(SPI_GETNONCLIENTMETRICS)`, `GetDpiForSystem`
  and the GDI fixed stock font.
* macOS: AppKit `NSFont` default-by-role methods with size 0.

No Linux numeric value is a generic Windows/macOS default.
