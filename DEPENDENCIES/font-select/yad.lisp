(in-package #:font-select.yad)

(defun %run (program args)
  (handler-case
      (multiple-value-bind (output status) (apply #'font-select::run program args)
        (when (and output (or (null status) (zerop status)))
          (font-select::%pango-string->plist output)))
    (error (c)
      (format *error-output* "[font-select.yad] ~A~%" (princ-to-string c))
      nil)))

(defclass yad (backend)
  ((program-name :initform "yad" :initarg :program-name :accessor program-name)))

(defmethod select-with ((backend yad) &key default (variant :full) &allow-other-keys)
  "VARIANT is accepted for API parity but ignored: yad's --font dialog has no
flag for hiding widgets (debian manpage)."
  (declare (ignore variant))
  (let* ((init (when (and default (getf default :family))
                 (format nil "~A ~A"
                         (getf default :family)
                         (or (getf default :size) 12))))
         (args (append (list "--font")
                       (when init (list (format nil "--fontname=~A" init))))))
    (let ((plist (%run (program-name backend) args)))
      (if plist
          (values plist T)
          (values NIL NIL)))))
