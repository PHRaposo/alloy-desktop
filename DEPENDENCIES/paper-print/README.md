# paper-print

`paper-print` sends raster pages to the operating system's native printing
services from Common Lisp. It provides printer selection and page-setup
dialogs, printable-page geometry, persistent printer settings, and multi-page
print jobs.

## API

Create raster pages from straight-alpha RGBA data:

```lisp
(paper-print:make-raster-page width height data)
```

Read or choose printer settings:

```lisp
(paper-print:default-printer-settings)
(paper-print:select-printer :settings settings)
(paper-print:page-setup :owner native-owner :settings settings)
```

Settings own native resources. Pass every retained settings object to
`paper-print:close-settings` when it is no longer needed.

Query the printable area or print pages:

```lisp
(paper-print:paper-geometry settings)

(paper-print:print-image-pages
 page-count
 (lambda (page-number) ...)
 :title "Document"
 :settings settings)
```

`print-image-pages` returns a status of `:printed`, `:cancelled`, or `:failed`.
Backend failures are returned with `:failed`; invalid caller arguments signal
`paper-print:paper-print-argument-error`.

## Platforms

The Windows backend uses the native Page Setup and Print dialogs and the GDI
printing pipeline. Raster pages are sent directly to the printer device context
with `StretchDIBits`.

The Linux backend uses GTK3's native Unix printing API. `GtkPrintUnixDialog` and
`GtkPageSetupUnixDialog` provide printer/page selection; `GtkPrintJob` supplies a
Cairo print surface and owns the spool handoff. Raster pages are flattened once
to opaque ARGB32 and painted directly onto that native surface. `paper-print`
does not generate PDF/PostScript itself. If GTK's native `Print to File` printer
is selected, that backend decides the document format just like a Windows
printer driver does.

Both backends keep printer settings opaque and owned by `paper-print`; callers
only retain or close `printer-settings` objects through the public API.
