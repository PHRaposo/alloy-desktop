(in-package #:org.shirakumo.alloy)

(defclass label (value-component)
  ((wrap :initarg :wrap :initform NIL :accessor wrap)))

(defmethod component-class-for-object ((string string))
  (find-class 'label))

(defclass label* (label direct-value-component) ())

(defmethod enter ((string string) (layout layout) &rest args)
  (apply #'enter (make-instance 'label* :value string) layout args))

(defclass notice (label*)
  ((wrap :initform T)))

(defmethod suggest-size (size (notice notice))
  ;; Make us zero size if there is no value to display.
  (if (value notice)
      (call-next-method)
      (px-size)))

(defclass alert (notice) ())
