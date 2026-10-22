(asdf:defsystem os-fonts
  :version "0.1.0"
  :license "zlib"
  :author "Paulo"
  :description "Cross-platform provider for native operating-system UI font roles."
  :serial t
  :defsystem-depends-on (:trivial-features)
  :components ((:file "package")
               (:file "protocol")
               (:file "linux" :if-feature :linux)
               (:file "macos" :if-feature :darwin)
               (:file "windows" :if-feature :windows)
               (:file "defaults"))
  ;; FLOAT-FEATURES: SBCL runs with hardware FP traps armed, but CoreText does
  ;; benign divisions that then abort the process from inside a foreign frame.
  ;; See MACOS.LISP.  Portable, so it is not gated on :darwin.
  :depends-on (:cffi :float-features :uiop)
  :in-order-to ((test-op (test-op "os-fonts/tests"))))

(asdf:defsystem os-fonts/tests
  :depends-on (:os-fonts)
  :serial t
  :components ((:file "tests"))
  :perform (test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :os-fonts.tests :run-tests)))
