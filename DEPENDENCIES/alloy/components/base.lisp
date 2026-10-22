(in-package #:org.shirakumo.alloy)

(defclass value-component (component)
  ((value-function :initarg :value-function :initform 'value :reader value-function)
   ;; Avoid allocating new strings for the same value by using a
   ;; cache.
   (cached-value :initform 0)
   (cached-text :initform "0")))

(defmethod initialize-instance :after ((component value-component) &key)
  (observe (value-function component) (data component)
           (lambda (value observable)
             (declare (ignore value observable))
             (value-changed component))
           :name component))

(defmethod print-object ((element value-component) stream)
  (print-unreadable-object (element stream :type T :identity T)
    (handler-case
        (let ((*print-pretty* t)
              (*print-circle* t)
              (*print-length* 3)
              (*print-level* 3)
              (*print-lines* 3))
          (princ (value element) stream))
      (error ()
        (write-string "<error printing component value>" stream)))
    (format stream " ~a~@[ focus ~a~]" (bounds element) (focus element))))

(defmethod value-changed ((component value-component))
  (mark-for-render component))

(defmethod value ((component value-component))
  (access (data component) (value-function component)))

(defmethod (setf value) (new-value (component value-component))
  (setf (access (data component) (value-function component)) new-value))

(defmethod refresh ((component value-component))
  (setf (value component) (value component)))

(defmethod text ((component value-component))
  (let ((value (value component)))
    (cond ((eql value (slot-value component 'cached-value))
           (slot-value component 'cached-text))
          (t
           (setf (slot-value component 'cached-value) value)
           (setf (slot-value component 'cached-text)
                 (princ-to-string value))))))

(defclass direct-value-component (value-component)
  ((value :initarg :value :accessor value)
   (data :initform ())))

(defmethod initialize-instance ((component direct-value-component) &key data)
  (call-next-method)
  (if data
      (setf (slot-value component 'value) (value data))
      (setf (slot-value component 'data) component)))

(defclass progress (value-component)
  ((maximum :initarg :maximum :initform 100 :accessor maximum)))

(defclass icon (value-component)
  ())

(defmethod register ((icon icon) (renderer renderer))
  (register (value icon) renderer))

(defmethod refresh ((icon icon))
  (mark-for-render icon))

(defclass icon* (icon direct-value-component) ())
