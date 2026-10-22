(in-package #:cl-user)
(defpackage #:deploy
  (:nicknames #:org.shirakumo.deploy)
  (:use #:cl)
  ;; appimage.lisp
  (:export
   #:*desktop-template*
   #:*desktop-icon*
   #:appimage-deploy-op
   #:appimage-file)
  ;; asdf.lisp
  (:export
   #:clear-asdf)
  ;; checksum.lisp
  (:export
   #:*source-checksum*
   #:*build-time*
   #:list-all-source-files
   #:source-checksum)
  ;; deploy.lisp
  (:export
   #:*compression-factor*
   #:deployed-p
   #:quit
   #:deploy-op
   #:entry-point
   #:output-file
   #:deploy
   #:output-data-directory
   #:deploy-console-op
   #:deploy-image-op)
  ;; hooks.lisp
  (:export
   #:hook
   #:hook-name
   #:hook-type
   #:hook-function
   #:hook-priority
   #:hook-enabled-p
   #:remove-hook
   #:define-hook
   #:run-hooks
   #:report-error
   #:define-resource-directory)
  ;; library.lisp
  (:export
   #:*system-source-directories*
   #:list-libraries
   #:ensure-library
   #:library
   #:library-sources
   #:library-path
   #:library-dont-open-p
   #:library-dont-deploy-p
   #:possible-directories
   #:possible-pathnames
   #:find-source-file
   #:library-name
   #:library-soname
   #:library-dependencies
   #:open-library
   #:close-library
   #:library-open-p
   #:define-library
   #:patch-soname
   #:patch-dependencies
   #:foreign-libraries
   #:patch-sonames)
  ;; osx.lisp
  (:export
   #:*info-plist-template*
   #:osx-app-deploy-op
   #:sign-app
   #:make-dmg)
  ;; source-locations.lisp
  (:export
   #:*source-location-roots*
   #:transform-source-locations)
  ;; shrinkwrap.lisp
  #+sbcl
  (:export
   #:*sbcl-source-tree*
   #:shrinkwrap
   #:shrinkwrap-op)
  ;; toolkit.lisp
  (:export
   #:*data-location*
   #:*library-location*
   #:*base-location*
   #:*status-output*
   #:runtime-directory
   #:data-directory
   #:library-directory
   #:base-directory
   #:status
   #:command-line-arguments
   #:envvar
   #:envvar-directory
   #:envvar-directories
   #:env-set-p
   #:redirect-output
   #:featurep
   #:copy-file
   #:copy-directory-tree))
