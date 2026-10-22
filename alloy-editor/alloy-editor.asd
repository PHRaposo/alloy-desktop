(asdf:defsystem #:alloy-editor
  :description "A text editor over Alloy: a buffer, its layout and a view of it."
  :serial T
  :depends-on (#:alloy-glfw
               #:alloy-simple-presentations
               #:3b-bmfont
               ;; characters to bytes and back, strictly: already under the toolkit
               ;; through the foreign-function layer (cffi.asd: the cffi system)
               #:babel
               ;; a lock, without naming one implementation: text handed in from
               ;; other threads is queued under it
               #:bordeaux-threads
               ;; the character output stream printing goes through
               #:trivial-gray-streams)
  :components ((:file "package")
               (:file "buffer")
               (:file "document")
               (:file "layout")
               (:file "policy")
               (:file "view")
               (:file "commands")
               (:file "lisp-mode")
               (:file "output")
               (:file "input")))

(asdf:defsystem #:alloy-editor/census
  :description "The methods the editor adds to the toolkit's generics, and the
ones it would replace: taken before the editor is loaded and again after."
  :depends-on (#:alloy-glfw
               #:alloy-simple-presentations)
  :pathname "tests/"
  :components ((:file "census")))

(asdf:defsystem #:alloy-editor/example
  :description "One window over alloy-editor, to show what a host does with it.
Not part of the editor: nothing in the editor knows this system is there."
  :depends-on (#:alloy-editor
               ;; the faces the panes ask for by name are looked up before they are
               ;; asked for, so a name the system does not have is no error
               #:font-discovery)
  :pathname "example/"
  :components ((:file "application")))

(asdf:defsystem #:alloy-editor/tests
  :description "Stand-alone harness and self-checks of alloy-editor."
  :serial T
  :depends-on (#:alloy-editor
               #:alloy-editor/example
               #:cl-opengl)
  :pathname "tests/"
  :components ((:file "harness")
               (:file "commands-check")
               (:file "frame-check")
               (:file "lisp-check")
               (:file "files-check")
               (:file "io-check")
               (:file "example-check")
               (:file "classic-model")
               (:file "classic-hooks")
               (:file "classic-keys")
               (:file "classic-pointer")
               (:file "classic-clip")
               (:file "classic-undo")
               (:file "classic-scroller")
               (:file "selfcheck")))
