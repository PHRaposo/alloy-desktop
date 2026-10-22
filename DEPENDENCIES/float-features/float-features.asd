(asdf:defsystem float-features
  :version "1.1.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "A portability library for IEEE float features not covered by the CL standard."
  :homepage "https://shinmera.com/project/float-features"
  :serial T
  :components ((:file "package")
               (:file "infinity")
               (:file "float-features")
               (:file "nan")
               (:file "documentation"))
  :in-order-to ((asdf:test-op (asdf:test-op :float-features/tests)))
  :depends-on (:trivial-features :documentation-utils))

(asdf:defsystem float-features/tests
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "Tests for Float Features"
  :perform (asdf:test-op (op c) (uiop:symbol-call :parachute :test :float-features/tests))
  :homepage "https://shinmera.com/project/float-features"
  :serial T
  :components ((:file "test-float-features"))
  :depends-on (:float-features :parachute))
