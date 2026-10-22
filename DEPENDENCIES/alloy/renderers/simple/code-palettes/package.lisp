(defpackage #:org.shirakumo.alloy.renderers.simple.code-palettes
  (:use #:cl)
  (:local-nicknames
   (#:alloy #:org.shirakumo.alloy)
   (#:simple #:org.shirakumo.alloy.renderers.simple)
   (#:chroma #:org.shirakumo.alloy.chroma)
   (#:colors #:org.shirakumo.alloy.chroma.colors))
  (:export
   #:palette
   #:define-palette))
