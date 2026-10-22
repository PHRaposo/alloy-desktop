(in-package #:org.shirakumo.alloy.observables)

(defclass observable ()
  ((observers :initform (make-hash-table :test 'eql) :accessor observers)))

(defgeneric list-activities (observable))
(defgeneric find-activity (name observable &optional errorp))
(defgeneric register-activity (name observable arglist &key))
(defgeneric observe (activity observable observer &key))
(defgeneric remove-observers (activity observable))
(defgeneric remove-observer (activity observable name))
(defgeneric list-observers (activity observable))
(defgeneric notify-observers (activity observable &rest args))
(defgeneric make-observable (thing arglist &key activity))

(defmacro define-activity (activity observable args &body body)
  (when (stringp (car body))
    (setf body `(:documentation ,@body)))
  `(register-activity ',activity (find-class ',observable) ',args ,@body))

(defmacro define-activities (observable &body activities)
  `(progn
     ,@(loop for (activity args . options) in activities
             collect `(define-activity ,activity ,observable ,args ,@options))))

(defun gather-declarations (body)
  (let* ((docstring (when (stringp (car body)) (pop body)))
         (declarations (loop for item = (car body)
                             while (and (listp item) (eql 'declare (car item)))
                             collect (pop body)))
         (normalized (loop for declaration in declarations
                           append (loop for part in (rest declaration)
                                        collect `(declare ,part)))))
    (when (stringp (car body)) (setf docstring (car body)))
    (values normalized body (if docstring (list docstring)))))

(defmacro on ((activity observable) args &body body)
  (multiple-value-bind (declarations body docstring) (gather-declarations body)
    (let* ((specialization ())
           (args (if args
                     (loop for arg in args
                           collect (cond ((not (listp arg))
                                          (push T specialization)
                                          arg)
                                         ((eql 'eql (first arg))
                                          (push `(list 'eql ,(second arg)) specialization)
                                          (gensym "SPECIALIZED"))
                                         (T
                                          (push `',(second arg) specialization)
                                          (first arg))))
                     `(&rest ,(gensym "REST"))))
           (name (or (second (second (find 'name declarations :key #'caadr :test #'string=)))
                     (gensym (format NIL "~a-~a" 'on activity))))
           (declarations (remove 'name declarations :key #'caadr :test #'string=)))
      (push `(declare (ignore ,@(loop for arg in args unless (symbol-package arg) collect arg))) declarations)
      `(flet ((,name ,args
                ,@docstring
                ,@declarations
                ,@body))
         (observe ',activity ,observable #',name
                  :name ',name
                  :specialize (list ,@(nreverse specialization)))))))

(defmacro define-observation (name args &body body)
  (multiple-value-bind (declarations body docstring) (gather-declarations body)
    `(progn
       (defun ,name ,args
         ,@docstring
         ,@(remove 'observe declarations :key #'caadr)
         ,@body)
       ,@(loop for decl in declarations
               when (eql 'observe (car (second decl)))
               append (destructuring-bind (activity &rest classes) (rest (second decl))
                        (destructuring-bind (activity &rest specialization) (if (listp activity) activity (list activity))
                          (loop for class in classes
                                do (handler-case
                                       (let ((activity (find-activity activity class T)))
                                         (when specialization (check-arglist specialization activity))
                                         (check-arglist args activity))
                                     (error (e)
                                       (warn "~a" e)))
                                collect `(observe ',activity (find-class ',class) #',name :name ',name :specialize ',specialization))))))))

(defmacro define-observable (function-name lambda-list &body options)
  (flet ((key (key &optional default)
           (let ((cons (assoc key options)))
             (if cons (second cons) default))))
    (let ((name (if (listp function-name) (second function-name) function-name)))
      `(progn
         (defgeneric ,function-name ,lambda-list
           ,@(loop for (k v . args) in options
                   unless (member k '(:activity :class :invoke))
                   collect (list* k v args)))
         (make-observable ',function-name ',lambda-list
                          :class ',(key :class 'observable)
                          :invoke ,(key :invoke :before)
                          :activity ',(key :activity name))
         (define-activity ,name ,(key :class 'observable) ,lambda-list
           :documentation ,(key :documentation))))))
