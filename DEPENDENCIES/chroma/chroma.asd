(asdf:defsystem chroma
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "System for colour representation, conversion, and operation."
  :homepage "https://shinmera.com/docs/chroma"
  :bug-tracker "https://shinmera.com/project/chroma/issues"
  :source-control (:git "https://shinmera.com/project/chroma.git")
  :serial T
  :components ((:file "package")
               (:file "whitepoints")
               (:file "conversion-matrices")
               (:file "type")
               (:file "ops")
               (:file "constants")
               (:file "documentation"))
  :depends-on (:documentation-utils)
  :in-order-to ((asdf:test-op (asdf:test-op :chroma/test))))

(asdf:defsystem chroma/test
  :version "0.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "Tests for the Chroma colour library."
  :homepage "https://shinmera.com/project/chroma"
  :serial T
  :components ((:file "test"))
  :depends-on (:chroma
               :parachute)
  :perform (asdf:test-op (op c) (uiop:symbol-call :parachute :test :org.shirakumo.alloy.chroma.test)))
