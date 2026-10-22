(in-package #:org.shirakumo.deploy)

(defvar *source-location-roots*
  (macrolet ((s (pkg name)
               `(find-symbol ,(string name) ,(string pkg))))
    (append (when (find-package :quicklisp)
              (append
               (loop for dist in (funcall (s ql-dist all-dists))
                     collect (merge-pathnames "software/" (funcall (s ql-dist base-directory) dist)))
               (symbol-value (s quicklisp *local-project-directories*))))
            (when (find-package :asdf)
              (symbol-value (s asdf *central-registry*))))))

;; Need to do this to avoid a bad source transform firing.
#+sbcl
(defun %frob-source-location (loc namestring)
  (setf (slot-value loc 'namestring) namestring))

(defun transform-source-locations (function)
  #+sbcl
  (flet ((thunk (object _c _s)
           (declare (ignore _c _s))
           (when (typep object 'sb-c::definition-source-location)
             (let* ((namestring (sb-c::definition-source-location-namestring object))
                    (path (when namestring (parse-namestring namestring))))
               (cond ((null namestring))
                     ((typep path 'logical-pathname))
                     (T
                      (let* ((new (funcall function path))
                             (path (etypecase new
                                     (string new)
                                     (pathname (namestring new))
                                     (null NIL))))
                        (%frob-source-location object path))))))))
    (sb-vm:map-allocated-objects #'thunk :all)))

(define-hook (:build transform-source-locations -2 :enabled-p NIL) ()
  (transform-source-locations
   (lambda (path)
     (or (dolist (base *source-location-roots*)
           (when (pathname-utils:subpath-p path base)
             (return (pathname-utils:relative-pathname base path))))
         path)))
  (setf *source-location-roots* NIL))

(define-hook (:boot transform-source-locations -2) (directory)
  (let ((base (merge-pathnames "sources/" directory)))
    (transform-source-locations
     (lambda (path)
       (if (pathname-utils:relative-p path)
           (merge-pathnames path base)
           path)))))
