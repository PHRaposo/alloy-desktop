(asdf:defsystem imagine
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "A general image decoding and manipulation library"
  :homepage "https://shirakumo.org/docs/imagine/"
  :bug-tracker "https://shirakumo.org/project/imagine/issues"
  :source-control (:git "https://shirakumo.org/project/imagine.git")
  :serial T
  :components ((:file "package")
               (:file "conditions")
               (:file "toolkit")
               (:file "protocol")
               (:file "io")
               (:file "ops")
               (:file "documentation"))
  :depends-on (:closer-mop
               :nibbles
               :documentation-utils)
  :in-order-to ((asdf:test-op (asdf:test-op :imagine/test))))

(asdf:defsystem imagine/foreign-pointer
  :description "Support for using foreign pointers for image data storage."
  :components ((:file "formats/cffi"))
  :depends-on (:imagine :cffi))

(asdf:defsystem imagine/memory-region
  :description "Support for using memory regions for image data storage."
  :components ((:file "formats/memory-region"))
  :depends-on (:imagine/foreign-pointer :memory-regions/pathname))

(asdf:defsystem imagine/raw
  :description "Support for a simple raw image format."
  :components ((:file "formats/raw"))
  :depends-on (:imagine :nibbles))

(asdf:defsystem imagine/depot
  :description "Support for using depots for image data storage."
  :components ((:file "formats/depot"))
  :depends-on (:imagine :depot))

(asdf:defsystem imagine/bmp
  :description "Support for Microsoft BMP image files."
  :components ((:file "formats/bmp"))
  :depends-on (:imagine :cl-bmp))

(asdf:defsystem imagine/devil
  :description "Support for various image formats using libIL."
  :components ((:file "formats/devil"))
  :depends-on (:imagine/memory-region :cl-devil))

(asdf:defsystem imagine/gif
  :description "Support for GIF image files."
  :components ((:file "formats/gif"))
  :depends-on (:imagine :skippy-renderer))

(asdf:defsystem imagine/hdr
  :description "Support for HDR image files."
  :components ((:file "formats/hdr"))
  :depends-on (:imagine :3b-hdr))

(asdf:defsystem imagine/jpeg
  :description "Support for JPEG image files."
  :components ((:file "formats/jpeg"))
  :depends-on (:imagine :cl-jpeg))

(asdf:defsystem imagine/jpeg-turbo
  :description "Support for JPEG image files using libjpeg-turbo"
  :components ((:file "formats/jpeg-turbo"))
  :depends-on (:imagine/memory-region :cl-turbojpeg))

(asdf:defsystem imagine/ktx
  :description "Support for Khronos KTX image files."
  :components ((:file "formats/ktx"))
  :depends-on (:imagine :cl-ktx))

(asdf:defsystem imagine/ktx2
  :description "Support for Khronos KTX2 image files."
  :components ((:file "formats/ktx2"))
  :depends-on (:imagine :cl-ktx2))

(asdf:defsystem imagine/png
  :description "Support for PNG image files."
  :components ((:file "formats/png"))
  :depends-on (:imagine :pngload :zpng :memory-regions :3bz))

(asdf:defsystem imagine/qoi
  :description "Support for QOI image files."
  :components ((:file "formats/qoi"))
  :depends-on (:imagine :qoi))

(asdf:defsystem imagine/sf3
  :description "Support for SF3 image files."
  :components ((:file "formats/sf3"))
  :depends-on (:imagine :cl-sf3/image))

(asdf:defsystem imagine/svg
  :description "Support for SVG image files."
  :components ((:file "formats/svg"))
  :depends-on (:imagine :cl-resvg))

(asdf:defsystem imagine/terragen
  :description "Support for Terragen TER heightmap files."
  :components ((:file "formats/ter"))
  :depends-on (:imagine :terrable))

(asdf:defsystem imagine/tga
  :description "Support for Targa TGA image files."
  :components ((:file "formats/tga"))
  :depends-on (:imagine :cl-tga))

(asdf:defsystem imagine/tiff
  :description "Support for TIFF image files."
  :components ((:file "formats/tiff"))
  :depends-on (:imagine :retrospectiff))

(asdf:defsystem imagine/formats
  :description "Support for all image formats in Imagine."
  :depends-on (:imagine/raw
               :imagine/depot
               :imagine/bmp
               :imagine/gif
               :imagine/hdr
               :imagine/jpeg-turbo
               :imagine/ktx
               :imagine/png
               :imagine/qoi
               :imagine/sf3
               :imagine/svg
               :imagine/terragen
               :imagine/tga
               :imagine/tiff))

(asdf:defsystem imagine/test
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "Tests for the imagine system."
  :homepage "https://shirakumo.org/docs/imagine/"
  :bug-tracker "https://shirakumo.org/project/imagine/issues"
  :source-control (:git "https://shirakumo.org/project/imagine.git")
  :serial T
  :components ((:file "test"))
  :depends-on (:imagine :imagine/formats :parachute)
  :perform (asdf:test-op (op c) (uiop:symbol-call :parachute :test :org.shirakumo.fraf.imagine.test)))
