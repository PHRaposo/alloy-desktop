(asdf:defsystem paper-print
  :version "0.1.0"
  :license "MIT"
  :author "Paulo"
  :description "Native paper printing for Common Lisp raster pages."
  :serial t
  :defsystem-depends-on (:trivial-features)
  :components ((:file "package")
               (:file "protocol")
               (:file "win32" :if-feature :windows)
               (:file "linux" :if-feature :linux)
               (:file "macos" :if-feature :darwin))
  ;; The macOS backend masks the FPU traps SBCL arms by default before entering
  ;; AppKit, exactly as the Linux backend does before entering GTK.  Kept gated
  ;; rather than made unconditional so the Windows dependency set is untouched.
  :depends-on (:cffi
               #+(or linux darwin) :float-features
               :uiop))