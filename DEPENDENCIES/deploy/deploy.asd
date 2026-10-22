(asdf:defsystem deploy
  :version "3.1.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "Your one-stop-shop for automating builds of Common Lisp systems to standalone, deployable applications."
  :homepage "https://shinmera.com/docs/deploy/"
  :bug-tracker "https://shinmera.com/project/deploy/issues"
  :source-control (:git "https://shinmera.com/project/deploy.git")
  :serial T
  :components ((:file "package")
               (:file "toolkit")
               (:file "hooks")
               (:file "library")
               (:file "checksum")
               (:file "source-locations")
               (:file "deploy")
               (:file "template")
               (:file "asdf" :if-feature :asdf3)
               (:file "osx")
               (:file "appimage")
               (:file "nx" :if-feature (:and :sbcl :nx))
               (:file "shrinkwrap" :if-feature :sbcl)
               (:file "documentation"))
  :depends-on ((:feature (:not :mezzano) :cffi)
               :sha3
               :documentation-utils
               :pathname-utils
               :trivial-features))
