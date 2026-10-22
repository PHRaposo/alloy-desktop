(defpackage #:org.shirakumo.alloy.renderers.simple.presentations
  (:use #:cl)
  (:local-nicknames
   (#:alloy #:org.shirakumo.alloy)
   (#:simple #:org.shirakumo.alloy.renderers.simple)
   (#:animation #:org.shirakumo.alloy.animation)
   (#:chroma #:org.shirakumo.alloy.chroma)
   (#:colors #:org.shirakumo.alloy.chroma.colors))
  (:import-from #:org.shirakumo.alloy #:arg!)
  ;; default.lisp
  (:export
   #:default-look-and-feel
   #:fit-to-shapes)
  ;; protocol.lisp
  (:export
   #:renderer
   #:name
   #:composite-mode
   #:z-index
   #:offset
   #:scale
   #:rotation
   #:pivot
   #:hidden-p
   #:shapes
   #:update-overrides
   #:shape-overrides
   #:realize-renderable
   #:update-shape
   #:clear-shapes
   #:find-shape
   #:define-realization
   #:define-update
   #:tracked-shapes
   #:define-animated-shapes))
