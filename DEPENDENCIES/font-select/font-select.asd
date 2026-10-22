(asdf:defsystem font-select
  :version "1.0.0"
  :license "zlib"
  :author "Paulo"
  :description "A library to invoke the native font selection dialogs."
  :serial T
  :defsystem-depends-on (:trivial-features)
  :components ((:file "package")
               (:file "protocol")
               (:file "yad" :if-feature :linux)
               (:file "gtk" :if-feature :linux)
               (:file "macos" :if-feature :darwin)
               (:file "win32" :if-feature :windows)
               (:file "defaults"))
  :depends-on (:cffi
               :float-features
               (:feature :darwin :trivial-main-thread)
               (:feature :windows :com-on)
               :uiop))
