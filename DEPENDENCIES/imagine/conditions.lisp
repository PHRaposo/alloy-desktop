(in-package #:org.shirakumo.fraf.imagine)

(define-condition imagine-error (error)
  ())

(define-condition invalid-view (imagine-error)
  ((view :initarg :view :initform NIL :reader view))
  (:report (lambda (c s) (format s "The view~%  ~a~%is invalid for the image it is backing as its bounds lie outside~%  ~a"
                                 (view c) (image (view c))))))

(define-condition pixel-data-incompatible (imagine-error)
  ((source :initarg :source :initform NIL :reader source)
   (target :initarg :target :initform NIL :reader target))
  (:report (lambda (c s) (format s "The pixel data between the source~%  ~a~%and the target~%  ~a~%are incompatible."
                                 (source c) (target c)))))

(define-condition unsupported-format (imagine-error)
  ((source :initarg :source :initform NIL :reader source)
   (format-type :initarg :format-type :initform NIL :reader format-type)
   (supported-formats :initarg :supported-formats :initform NIL :reader supported-formats))
  (:report (lambda (c s) (if (find (format-type c) (supported-formats c))
                             (format s "Don't know how to handle the ~a format for the container~%  ~a"
                                     (format-type c) (source c))
                             (format s "Don't know the format ~a.~%Known formats are:~%  ~a"
                                     (format-type c) (supported-formats c))))))
