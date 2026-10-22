(in-package #:org.shirakumo.file-select)

(defvar *backend-cache* (make-hash-table :test 'eq))
(defvar *default-backend*)

(define-condition file-select-error (error)
  ())

(defun default-backend ()
  (if (boundp '*default-backend*)
      *default-backend*
      (setf *default-backend* (determine-default-backend))))

(defun as-directory-pathname (path)
  "Return PATH in directory pathname form.

If PATH carries a name or type, fold that final component into the
directory list and clear NAME and TYPE. Already directory-shaped
pathnames are returned unchanged."
  (if (or (pathname-name path) (pathname-type path))
      (make-pathname
       :host (pathname-host path)
       :device (pathname-device path)
       :directory
       (append
        (or (pathname-directory path) '(:relative))
        (list
         (if (pathname-type path)
             (format NIL "~a.~a"
                     (pathname-name path)
                     (pathname-type path))
             (pathname-name path))))
       :name NIL
       :type NIL)
      path))

(defun normalize-selection (selection filter)
  "Normalize backend SELECTION according to FILTER.

In particular, :DIRECTORY selections are guaranteed to be returned as
directory-shaped pathnames, independently of the backend. This also
handles multiple selections when the backend returns a list."
  (if (and selection (eq filter :directory))
      (if (listp selection)
          (mapcar #'as-directory-pathname selection)
          (as-directory-pathname selection))
      selection))

(defun existing (&rest args &key title default filter multiple backend)
  (restart-case (apply #'existing-with (or backend (default-backend)) args)
    (continue ()
      :report "Cancel the call by returning NIL"
      (values NIL NIL))))

(defun new (&rest args &key title default filter multiple backend)
  (restart-case (apply #'new-with (or backend (default-backend)) args)
    (continue ()
      :report "Cancel the call by returning NIL"
      (values NIL NIL))))

(defclass backend () ())

(defun get-backend (class)
  (or (gethash class *backend-cache*)
      (setf (gethash class *backend-cache*)
            (make-instance class))))

(defgeneric finalize (backend))
(defgeneric new-with (backend &key title default filter &allow-other-keys))
(defgeneric existing-with (backend &key title default filter multiple &allow-other-keys))

(defmethod new-with :around ((backend backend) &rest args &key filter &allow-other-keys)
  (declare (ignore args))
  (multiple-value-bind (selection ok) (call-next-method)
    (values (normalize-selection selection filter) ok)))

(defmethod existing-with :around ((backend backend) &rest args &key filter &allow-other-keys)
  (declare (ignore args))
  (multiple-value-bind (selection ok) (call-next-method)
    (values (normalize-selection selection filter) ok)))

(defmethod finalize ((backend symbol))
  (finalize (find-class backend)))

(defmethod new-with ((backend symbol) &rest args)
  (apply #'new-with (find-class backend) args))

(defmethod existing-with ((backend symbol) &rest args)
  (apply #'existing-with (find-class backend) args))

(defmethod finalize ((backend class))
  (let ((instance (gethash backend *backend-cache*)))
    (when instance (finalize instance))))

(defmethod new-with ((backend class) &rest args &key (title "New File"))
  (apply #'new-with (get-backend backend) :title title args))

(defmethod existing-with ((backend class) &rest args &key (title "Select File"))
  (apply #'existing-with (get-backend backend) :title title args))

(defmethod finalize ((backend backend)))

(defmethod finalize :after ((backend backend))
  (remhash (class-of backend) *backend-cache*))

(defmethod finalize ((all (eql T)))
  (mapc #'finalize (loop for v being the hash-values of *backend-cache* collect v)))

(defun native-namestring (path &rest args)
  (apply #'pathname-utils:native-namestring path args))

(defun parse-native-namestring (path &rest args)
  (apply #'pathname-utils:parse-native-namestring path args))

(defun run (program &rest args)
  (handler-case
      (multiple-value-bind (output error status)
          (uiop:run-program (list* program (remove NIL args))
                            :output :string
                            :ignore-error-status T
                            :external-format :utf-8)
        (declare (ignore error))
        (values output status))
    (error ()
      (error 'file-select-error))))
