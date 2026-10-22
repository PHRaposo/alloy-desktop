(in-package #:color-select.yad)

(defclass yad (backend)
  ())

(defmethod choose-color-with ((backend yad) &key title default &allow-other-keys)
  (handler-case
      (let* ((out (color-select::run "yad"
                                     "--color"
                                     (when title
                                       (format nil "--title=~A" title))
                                     (when default
                                       (format nil "--init-color=~A" (color-select::color->hex default)))))
             (color (color-select::parse-color-string out)))
        (if color (values color T) (values NIL NIL)))
    (error (c)
      (format *error-output* "[color-select.yad] ~A~%" (princ-to-string c))
      (values NIL NIL))))
