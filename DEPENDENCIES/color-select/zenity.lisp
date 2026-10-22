(in-package #:color-select.zenity)

(defclass zenity (backend)
  ((program-name :initform "zenity" :initarg :program-name :accessor program-name)))

(defmethod choose-color-with ((backend zenity) &key title default &allow-other-keys)
  (handler-case
      (let* ((out (color-select::run (program-name backend)
                                     "--color-selection"
                                     (when title
                                       (format nil "--title=~A" title))
                                     (when default
                                       (format nil "--color=~A" (color-select::color->hex default)))))
             (color (color-select::parse-color-string out)))
        (if color (values color T) (values NIL NIL)))
    (error (c)
      (format *error-output* "[color-select.zenity] ~A~%" (princ-to-string c))
      (values NIL NIL))))
