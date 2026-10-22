(defpackage #:org.shirakumo.fraf.imagine.test
  (:use #:cl #:parachute)
  (:local-nicknames
   (#:im #:org.shirakumo.fraf.imagine))
  (:export
   #:imagine))

(in-package #:org.shirakumo.fraf.imagine.test)

(defvar *here* #.(make-pathname :name NIL :type NIL :defaults (or *compile-file-truename* *load-truename* (error "COMPILE-FILE or LOAD this file."))))

(define-test imagine)

(defun img (w h layout &rest data)
  (let* ((l (length data)))
    (im:make-image* (make-array l :element-type '(unsigned-byte 8) :initial-contents data)
                    :unsigned-byte layout w h)))

(defun img* (w h channel-type layout &rest data)
  (let* ((l (length data)))
    (im:make-image* (make-array l :element-type '(unsigned-byte 8) :initial-contents data)
                    channel-type layout w h)))

(defmethod parachute:print-object-oneline :after ((object im:image) output)
  (let ((i 0))
    (im:with-image-pixels (src object)
      (dotimes (z (im:d object))
        (dotimes (y (im:h object))
          (format output "~%~16t")
          (dotimes (x (im:w object))
            (dotimes (c (im:pixel-stride (im:layout object)))
              (format output " ~a" (* 255 (src i)))
              (incf i))
            (format output " ")))
        (when (< z (1- (im:d object)))
          (format output "~% "))))))

(defun file (a)
  (merge-pathnames a (merge-pathnames "test/" *here*)))

(defun im= (a b)
  (and (= (im:w a) (im:w b))
       (= (im:h a) (im:h b))
       (= (im:d a) (im:d b))
       (eql (im:channel-type a) (im:channel-type b))
       (eql (im:layout a) (im:layout b))
       (eql (im:origin a) (im:origin b))
       (every #'= (im:data a) (im:data b))))

(defun im~= (a b)
  (when (and (= (im:w a) (im:w b))
             (= (im:h a) (im:h b))
             (= (im:d a) (im:d b)))
    (let ((a (im:copy-image a)))
      (parachute:print-object-oneline a T) (terpri)
      (im:adjust a :layout (im:layout b)
                   :channel-type (im:channel-type b)
                   :origin (im:origin b))
      (parachute:print-object-oneline a T)
      (every #'= (im:data a) (im:data b)))))

(define-test ops
  :parent imagine
  (finish (img 0 0 :r))
  (finish (img 2 2 :r 0 1 2 3))
  (is im= (img 2 2 :r 2 3 0 1) (im:mirror (img 2 2 :r 0 1 2 3) :vertical))
  (is im= (img 2 2 :r 1 0 3 2) (im:mirror (img 2 2 :r 0 1 2 3) :horizontal))
  (is im= (img 2 2 :r 3 2 1 0) (im:rotate (img 2 2 :r 0 1 2 3) 180))
  (is im= (img 2 2 :r 2 0 3 1) (im:rotate (img 2 2 :r 0 1 2 3) +90))
  (is im= (img 2 2 :r 1 3 0 2) (im:rotate (img 2 2 :r 0 1 2 3) -90))
  (is im= (img 3 2 :r 0 1 0 2 3 0) (im:resize (img 2 2 :r 0 1 2 3) :w 3))
  (is im= (img 2 3 :r 0 1 2 3 0 0) (im:resize (img 2 2 :r 0 1 2 3) :h 3))
  (is im= (img 4 2 :r 0 0 1 1 2 2 3 3) (im:scale (img 2 2 :r 0 1 2 3) :w 4 :interpolation :nearest))
  (is im= (img 2 2 :r 0 1 2 3) (im:scale (img 4 2 :r 0 0 1 1 2 2 3 3) :w 2 :interpolation :nearest))
  (is im= (img 2 2 :ra 2 2 3 3 0 0 1 1) (im:mirror (img 2 2 :ra 0 0 1 1 2 2 3 3) :vertical))
  (is im= (img 2 2 :ra 1 1 0 0 3 3 2 2) (im:mirror (img 2 2 :ra 0 0 1 1 2 2 3 3) :horizontal))
  (is im= (img 2 2 :ra 3 3 2 2 1 1 0 0) (im:rotate (img 2 2 :ra 0 0 1 1 2 2 3 3) 180))
  (is im= (img 2 2 :ra 2 2 0 0 3 3 1 1) (im:rotate (img 2 2 :ra 0 0 1 1 2 2 3 3) +90))
  (is im= (img 2 2 :ra 1 1 3 3 0 0 2 2) (im:rotate (img 2 2 :ra 0 0 1 1 2 2 3 3) -90)))

(define-test adjust
  :parent imagine
  (let ((a (img 0 0 :r)))
    (is eq a (im:adjust a)))
  (is im= (img 2 2 :r 0 1 2 3) (im:adjust (img 2 2 :r 0 1 2 3)))
  (is im= (img 2 2 :rgb 0 0 0 1 1 1 2 2 2 3 3 3) (im:adjust (img 2 2 :r 0 1 2 3) :layout :rgb))
  (is im= (img 1 1 :bgr 3 2 1) (im:adjust (img 1 1 :rgb 1 2 3) :layout :bgr))
  (is im= (img* 2 2 :unsigned-short :r 0 0 1 0 2 0 3 0) (im:adjust (img 2 2 :r 0 1 2 3) :channel-type :unsigned-short)))

(define-test formats
  :parent imagine
  (let ((ref (img 2 2 :rgba 0 0 0 0 255 0 0 80 0 255 0 160 0 0 255 255)))
    (is im~= ref (im:load-image (file "ub8-rgba.png") T))
    (is im~= ref (im:load-image (file "ub8-rgba.bmp") T))
    (is im~= ref (im:load-image (file "ub8-rgba.gif") T))
    (is im~= ref (im:load-image (file "ub8-rgba.qoi") T))
    (is im~= ref (im:load-image (file "ub8-rgba.sf3") T))
    (is im~= ref (im:load-image (file "ub8-rgba.tga") T))
    (is im~= ref (im:load-image (file "ub8-rgba.tif") T))
    (is im~= ref (im:load-image (file "ub8-rgba.raw") T))))
