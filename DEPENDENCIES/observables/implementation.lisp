(in-package #:org.shirakumo.alloy.observables)

(defvar *static-observers* (make-hash-table :test 'eql))
(defvar *activities* (make-hash-table :test 'eql))

(defmethod direct-activities ((class standard-class))
  (gethash class *activities*))

(defmethod (setf direct-activities) (activities (class standard-class))
  (setf (gethash class *activities*) activities))

(defmethod observers ((class class)) NIL)

(defmethod observers ((class standard-class))
  (or (gethash class *static-observers*)
      (setf (gethash class *static-observers*) (make-hash-table :test 'eql))))

(defmethod list-activities ((class standard-class))
  (loop for class in (c2mop:class-precedence-list class)
        append (direct-activities class)
        until (eq class (find-class 'observable))))

(defmethod list-activities ((name symbol))
  (list-activities (find-class name T)))

(defmethod find-activity (name observable &optional errorp)
  (or (find name (list-activities observable) :key #'activity-name)
      (when errorp (error "No activity with name ~s on ~a" name observable))))

(defstruct (activity (:constructor make-activity (domain name &optional arglist documentation)))
  (domain NIL :type T)
  (name NIL :type symbol)
  (arglist NIL :type list)
  (documentation NIL :type (or null string)))

(defmethod print-object ((activity activity) stream)
  (print-unreadable-object (activity stream :type T)
    (format stream "~s (~{~a~^ ~})"
            (activity-name activity)
            (activity-arglist activity))))

(defmethod documentation ((activity activity) (doc-type (eql T)))
  (activity-documentation activity))

(defmethod (setf documentation) (documentation (activity activity) (doc-type (eql T)))
  (setf (activity-documentation activity) documentation))

(defun valid-arglist-p (arglist activity)
  (let ((len (length arglist))
        (exp (length (activity-arglist activity))))
    (cond ((< len exp) (values NIL (format NIL "The argument list~%  ~a~%is too short to match the expected~%  ~a"
                                           arglist (activity-arglist activity))))
          ((< exp len) (values NIL (format NIL "The argument list~%  ~a~%is too long to match the expected~%  ~a"
                                           arglist (activity-arglist activity))))
          (T arglist))))

(defun check-arglist (arglist activity)
  (multiple-value-bind (valid-p message) (valid-arglist-p arglist activity)
    (unless valid-p (error message))))

(defstruct (observer (:constructor make-observer (name function specialization test))
                     (:predicate NIL)
                     (:copier NIL))
  (name NIL :type T)
  (function NIL :type function)
  (specialization NIL :type list)
  (test NIL :type function))

(defun specialization-test (specialization)
  (if specialization
      (let ((args (loop for spec in specialization
                        for i from 0
                        collect (gensym (princ-to-string i)))))
        (compile NIL `(lambda ,args
                        (declare (ignore ,@(loop for spec in specialization
                                                 for arg in args
                                                 when (eql spec T) collect arg)))
                        (declare (optimize speed))
                        (and ,@(loop for spec in specialization
                                     for arg in args
                                     unless (eql spec T) collect `(typep ,arg ',spec))))))
      (lambda (&rest args) (declare (ignore args)) T)))

(defmethod describe-object ((observable observable) stream)
  (call-next-method)
  (let* ((activities (list-activities observable))
         (observers (observers observable))
         (names (sort (union (mapcar #'activity-name activities)
                             (loop for k being the hash-keys of observers collect k))
                      #'string<)))
    (when names
      (format stream "~&~%Activities:~%")
      (loop for name in names
            for activity = (find name activities :key #'activity-name)
            do (format stream "  ~a ~:[?~*~;~{~a~}~]~@[~%    ~a~]~%"
                       name
                       activity (when activity (activity-arglist activity))
                       (when activity (activity-documentation activity)))
               (loop for observer in (gethash name observers)
                     do (format stream "  - ~a~@[ ~a~]~%"
                                (observer-name observer)
                                (observer-specialization observer)))))))

(defmethod list-activities ((observable observable))
  (list-activities (class-of observable)))

(defmethod direct-activities ((observable observable))
  (direct-activities (class-of observable)))

(defmethod (setf direct-activities) (values (observable observable))
  (setf (direct-activities (class-of observable)) values))

(defmethod register-activity (name observable args &key (documentation NIL documentation-p))
  (let ((activity (find name (direct-activities observable) :key #'activity-name)))
    (cond (activity
           (setf (activity-domain activity) observable)
           (setf (activity-arglist activity) args)
           (when documentation-p
             (setf (activity-documentation activity) documentation)))
          (T
           (push (make-activity observable name args documentation)
                 (direct-activities observable))))
    name))

(defmethod observe (activity observable observer-function &key (name observer-function) specialize)
  (let ((observer (find name (gethash activity (observers observable)) :key #'observer-name))
        (test (specialization-test specialize)))
    (cond (observer
           (setf (observer-function observer) observer-function)
           (setf (observer-specialization observer) specialize)
           (setf (observer-test observer) test))
          (T
           (push (make-observer name observer-function specialize test)
                 (gethash activity (observers observable)))))
    name))

(defmethod remove-observers (activity observable)
  (if (eql T activity)
      (clrhash (observers observable))
      (remhash activity (observers observable))))

(defmethod remove-observer (activity observable name)
  (setf (gethash activity (observers observable))
        (remove name (gethash activity (observers observable)) :key #'observer-name)))

(defmethod list-observers (activity observable)
  (loop for observer in (gethash activity (observers observable))
        collect (observer-name observer)))

(defmethod notify-observers (activity (observable observable) &rest args)
  (loop for observer in (gethash activity (observers observable))
        when (apply (observer-test observer) args)
        do (apply (observer-function observer) args))
  (loop for class in (c2mop:class-precedence-list (class-of observable))
        for observers = (observers class)
        while observers
        do (loop for observer in (gethash activity observers)
                 when (apply (observer-test observer) args)
                 do (apply (observer-function observer) args))))

(defmethod make-observable (function lambda-list &key (class 'observable) (invoke :before) activity)
  (unless activity
    (setf activity (if (listp function) (second function) function)))
  (let ((arglist (copy-list lambda-list))
        (argvars ()))
    (unless (member 'observable lambda-list)
      (error "Cannot make ~s observable: the LAMBDA-LIST~%  ~s~%does not contain ~s"
             function lambda-list 'observable))
    (loop for cons on arglist
          do (case (car cons)
               ((&key &rest)
                (setf (car cons) '&rest)
                (setf (cdr cons) (list (gensym "REST"))))
               ((&optional &allow-other-keys))
               (observable
                (push 'observable argvars))
               (T
                (when (listp (car cons))
                  (setf (car cons) (caar cons)))
                (push (car cons) argvars)))
          finally (setf argvars (nreverse argvars)))
    (register-activity activity (find-class class) argvars)
    (let ((method `(defmethod ,function ,@(when invoke (list invoke))
                     ,(loop for arg in arglist
                            collect (if (eql 'observable arg)
                                        `(,arg ,class)
                                        arg))
                     (,(if (find '&rest arglist) 'apply 'funcall)
                      #'notify-observers ',activity observable ,@argvars))))
      (funcall (compile NIL `(lambda () ,method))))))

(defclass observable-object (observable)
  ())

(define-activity slot-value observable-object (value object slot-name)
  "Fired when a slot value is set.")

(defmethod (setf c2mop:slot-value-using-class) :after (value class (object observable-object) slot)
  (when (slot-boundp object 'observers)
    (notify-observers 'slot-value object value object (c2mop:slot-definition-name slot))))
