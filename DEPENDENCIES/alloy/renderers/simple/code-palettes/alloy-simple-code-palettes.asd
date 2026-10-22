(asdf:defsystem alloy-simple-code-palettes
  :version "0.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description ""
  :homepage "https://shirakumo.org/project/alloy"
  :serial T
  :components ((:file "package")
               (:file "base")
               (:file "palettes"))
  :depends-on (:documentation-utils
               :alloy-simple))

(asdf:defsystem alloy-simple-code-palettes/generator
  :version "0.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description ""
  :homepage "https://shirakumo.org/project/alloy"
  :serial T
  :components ((:file "package")
               (:file "generate"))
  :depends-on (:documentation-utils
               :alloy-simple
               :lquery
               :cl-ppcre))
