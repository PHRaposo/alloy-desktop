(in-package #:org.shirakumo.alloy)

(defvar *input-maps* (make-hash-table :test 'equal))

(defclass input-map ()
  ((name :initarg :name :initform NIL :accessor name)
   (mappings :initform () :initarg :mappings :accessor mappings)))

(define-print-object input-map "~@[~a~]" name)

(defmethod shared-initialize :after ((map input-map) slots &key inherit)
  (when inherit
    (merge-input-maps (input-map inherit) map :if-exists :supersede)))

(defgeneric add-mapping (mapping map &key if-exists))
(defgeneric input-map (designator))
(defgeneric merge-input-maps (src dst &key if-exists))

(defmethod input-map ((map input-map))
  map)

(defmethod input-map ((name (eql T)))
  (input-map "default"))

(defmethod input-map ((name symbol))
  (input-map (string-downcase name)))

(defmethod input-map ((name string))
  (gethash name *input-maps*))

(defmethod (setf input-map) (map (name string))
  (setf (gethash name *input-maps*) map))

(defmethod (setf input-map) (map (name symbol))
  (setf (input-map (string-downcase name)) map))

(defmethod (setf input-map) ((map null) (name string))
  (remhash name *input-maps*)
  map)

(defun list-input-maps ()
  (loop for v being the hash-values of *input-maps* collect v))

(defmethod merge-input-maps ((src input-map) (dst input-map) &key if-exists)
  (dolist (mapping (mappings src) dst)
    (add-mapping mapping dst :if-exists if-exists)))

(defmethod add-mapping ((mapping input-mapping) (map input-map) &key (if-exists :error))
  (let ((old (find mapping (mappings map) :test #'event-mapping-equal-p)))
    (if (null old)
        (push mapping (mappings map))
        (ecase if-exists
          ((:supersede :replace :overwrite)
           (setf (mappings map) (list* mapping (remove old (mappings map)))))
          (:error
           (error "Cannot add the new mapping~%  ~a~%because a matching input mapping already exists:~%  ~a"
                  mapping old))
          ((NIL)
           NIL)))))

(defmethod add-mapping (mapping (map string) &rest args &key &allow-other-keys)
  (apply #'add-mapping mapping (input-map map) args))

(defmethod add-mapping (mapping (map symbol) &rest args &key &allow-other-keys)
  (apply #'add-mapping mapping (input-map map) args))

(defmethod map-event ((event event) (map input-map) ui)
  (dolist (mapping (mappings map))
    (map-event event mapping ui)))

(defmacro define-input-map (name &body mappings)
  (let ((name (string-downcase name)))
    (form-fiddle:with-body-options (mappings initargs (class ''input-map)) mappings
      `(progn
         (if (input-map ,name)
             (reinitialize-instance (input-map ,name) ,@initargs)
             (setf (input-map ,name) (make-instance ,class :name ,name ,@initargs)))

         ,@(loop for mapping in mappings
                 collect `(define-input-mapping ,@mapping
                              :input-map ,name))))))

(define-input-map default)
(define-input-map emacs)
