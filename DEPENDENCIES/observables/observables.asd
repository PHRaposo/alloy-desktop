(asdf:defsystem observables
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "A library for defining activity/changes on objects that can be observed by remote trigger functions"
  :homepage "https://shinmera.com/docs/observables/"
  :bug-tracker "https://shinmera.com/project/observables/issues"
  :source-control (:git "https://shinmera.com/project/observables.git")
  :serial T
  :components ((:file "package")
               (:file "protocol")
               (:file "implementation")
               (:file "documentation"))
  :depends-on (:documentation-utils
               :closer-mop))
