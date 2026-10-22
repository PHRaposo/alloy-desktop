(in-package #:color-select.kdialog)

(defclass kdialog (backend)
  ())

(defmethod choose-color-with ((backend kdialog) &key title default &allow-other-keys)
  (handler-case
      (let* ((out (color-select::run "kdialog"
                                     "--getcolor"
                                     (when title "--title")
                                     title
                                     (when default "--default")
                                     (when default (color-select::color->hex default))))
             (color (color-select::parse-color-string out)))
        (if color (values color T) (values NIL NIL)))
    (error (c)
      (format *error-output* "[color-select.kdialog] ~A~%" (princ-to-string c))
      (values NIL NIL))))
