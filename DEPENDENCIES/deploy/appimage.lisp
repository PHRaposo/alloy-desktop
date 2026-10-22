(in-package #:org.shirakumo.deploy)

(defvar *desktop-template* (merge-pathnames "AppImage.desktop.in" *here*))
(defvar *desktop-icon* (merge-pathnames "AppImage.png" *here*))
(defvar *appimage-arch*
  #+x86-64 "x86_64"
  #+x86 "i686"
  #+(or arm64 aarch64) "aarch64"
  #+(and arm (not arm64)) "armhf"
  #-(or x86-64 x86 arm64 aarch64 arm) "")

(defclass appimage-deploy-op (deploy-op)
  ((appimage-file :initarg :appimage-file :initform NIL :accessor appimage-file)))

(defmethod deploy :before ((op appimage-deploy-op) &key)
  (let ((base (pathname-utils:subdirectory (output-file op) "AppDir"))
        (name (pathname-name (output-file op))))
    (unless (appimage-file op)
      (setf (appimage-file op) (output-file op)))
    (setf (output-file op) (make-pathname :name "AppRun" :defaults base))
    (let ((icon (merge-pathnames "icon.png" base)))
      (ensure-directories-exist icon)
      (unless (probe-file icon)
        (copy-file *desktop-icon* icon)))
    (let ((desktop (make-pathname :name name :type "desktop" :defaults base)))
      (create-template (system op) *desktop-template* desktop))
    (setf (appimage-file op) (merge-pathnames (appimage-file op) base)))
  (format *query-io* "~&
============================================================
                           NOTE

  After the image dump has completed, you need to actually
  create the appimage file by running the following
  command:

     ARCH=~a appimagetool ~s ~s

============================================================~%"
          *appimage-arch*
          (pathname-utils:native-namestring (pathname-utils:to-directory (output-file op)))
          (pathname-utils:native-namestring (appimage-file op))))

;; hook ASDF
#+asdf3
(flet ((export! (symbol package)
         (import symbol package)
         (export symbol package)))
  (export! 'appimage-deploy-op :asdf/bundle)
  (export! 'appimage-deploy-op :asdf))
