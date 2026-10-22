(asdf:defsystem color-select
  :version "0.1.0"
  :description "Invoke the native colour selection dialog to pick a colour."
  :serial T
  :defsystem-depends-on (:trivial-features)
  :components ((:file "package")
               (:file "protocol")
               (:file "zenity" :if-feature :linux)
               (:file "yad" :if-feature :linux)
               (:file "kdialog" :if-feature :linux)
               (:file "gtk" :if-feature :linux)
               (:file "macos" :if-feature :darwin)
               (:file "win32" :if-feature :windows)
               (:file "defaults"))
  :depends-on (:cffi
               :float-features
               (:feature :darwin :trivial-main-thread)
               :uiop))
