(in-package #:org.shirakumo.alloy.renderers.simple.code-palettes)

(defclass palette ()
  ((simple::patterns :initform (make-hash-table :test 'eq) :accessor simple::patterns)))

(defmethod shared-initialize :after ((palette palette) slots &key patterns)
  (loop for (k v) in patterns
        do (setf (find-pattern k palette) v)))

(defmethod simple:find-pattern ((name symbol) (palette palette) &key state (default NIL default-p))
  (declare (ignore state))
  (let ((patterns (simple::patterns palette))
        (name (case name
                (:input-foreground :foreground)
                (:input-background :background)
                (:placeholder-foreground :comment)
                (:alert-foreground :error)
                (:notice-foreground :keyword)
                (T name))))
    (or (gethash name patterns)
        (let* ((str (string name)))
          (loop for dash = (position #\- str :from-end T)
                while dash
                do (setf str (subseq str 0 dash))
                   (let ((res (gethash (intern str "KEYWORD") patterns)))
                     (when res (return res)))))
        (gethash :foreground patterns)
        (if default-p
            default
            (error "No pattern named ~s found on ~a" name palette)))))

(defmethod (setf find-pattern) ((color chroma:color) (name symbol) (palette palette))
  (setf (gethash name (simple::patterns palette)) color))

(defmethod (setf find-pattern) ((color integer) (name symbol) (palette palette))
  (setf (find-pattern name palette) (chroma:decode color)))

(defmethod (setf find-pattern) ((null null) (name symbol) (palette palette))
  (remhash name (simple::patterns palette))
  null)

(defmacro define-palette (name &body patterns)
  `(let ((palette (make-instance 'palette :patterns (list ,@(loop for item in patterns
                                                                  collect (if (listp item) `(list ,@item) item))))))
     (setf (gethash ',name simple::*palettes*) palette)
     (export ',name ,#.(package-name *package*))
     ',name))
