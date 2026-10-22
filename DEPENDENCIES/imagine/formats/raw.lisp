(in-package #:org.shirakumo.fraf.imagine)

;;;; Minimal ad-hoc float pixel format:
;; FORMAT ::= TYPE CHANNELS WIDTH HEIGHT DEPTH PIXEL*
;; TYPE     ::= ub16
;;          --- Integer designating the pixel type:
;;            1 ub8
;;            2 ub16
;;            4 f32
;;            8 f64
;; CHANNELS ::= ub16
;;          --- Integer in [1,4]
;; WIDTH    ::= ub16
;; HEIGHT   ::= ub16
;; DEPTH    ::= ub16
;; PIXEL    ::= type

(defmethod load-image ((stream stream) (type (eql :raw)) &key (decode T))
  (let ((header (make-array (* 2 5) :element-type '(unsigned-byte 8))))
    (declare (dynamic-extent header))
    (read-sequence header stream)
    (let ((f (nibbles:ub16ref/le header 0))
          (c (nibbles:ub16ref/le header 2))
          (w (nibbles:ub16ref/le header 4))
          (h (nibbles:ub16ref/le header 6))
          (d (nibbles:ub16ref/le header 8)))
      (make-image* (when decode
                     (let ((data (make-array (* f c w (max 1 h) (max 1 d)) :element-type '(unsigned-byte 8))))
                       (read-sequence data stream)
                       data))
                   (ecase f
                     (1 :unsigned-byte)
                     (2 :unsigned-short)
                     (3 :unsigned-int)
                     (4 :float)
                     (5 :unsigned-long)
                     (6 :signed-byte)
                     (7 :signed-short)
                     (8 :double)
                     (9 :signed-long)
                     (10 :half-float))
                   (ecase c
                     (1 :r) (2 :ra) (3 :rgb) (4 :rgba)
                     (5 :ar) (6 :argb) (7 :bgr) (8 :abgr) (9 :bgra))
                   w h d :bottom-left))))

(defmethod save-image ((source view) (stream stream) (type (eql :raw)) &key)
  (check-image-compatible source '(:r :ra :rgb :rgba :ar :argb :bgr :abgr :bgra)
                          :channel-types '(:unsigned-byte :unsigned-short :unsigned-int :unsigned-long
                                           :signed-byte :signed-short :signed-int :signed-long
                                           :float :double :half-float)
                          :origin :bottom-left)
  (let ((header (make-array (* 2 5) :element-type '(unsigned-byte 8))))
    (declare (dynamic-extent header))
    (setf (nibbles:ub16ref/le header 0)
          (ecase (channel-type source)
            (:unsigned-byte 1)
            (:unsigned-short 2)
            (:unsigned-int 3)
            (:float 4)
            (:unsigned-long 5)
            (:signed-byte 6)
            (:signed-short 7)
            (:double 8)
            (:signed-long 9)
            (:half-float 10)))
    (setf (nibbles:ub16ref/le header 2)
          (ecase (layout source)
            (:r 1) (:ra 2) (:rgb 3) (:rgba 4)
            (:ar 5) (:argb 6) (:bgr 7) (:abgr 8) (:bgra 9)))
    (setf (nibbles:ub16ref/le header 4) (w source))
    (setf (nibbles:ub16ref/le header 6) (h source))
    (setf (nibbles:ub16ref/le header 8) (d source))
    (write-sequence header stream))
  (let* ((data (data source))
         (ls (layer-stride source))
         (rs (row-stride source))
         (ps (pixel-stride source))
         (d (max 1 (d source)))
         (h (max 1 (h source)))
         (w (max 1 (w source)))
         (i (+ (* ls (z source))
               (* rs (y source))
               (* ps (x source)))))
    (dotimes (z d)
      (let ((i i))
        (dotimes (y h)
          (write-sequence data stream :start i :end (+ i (* w ps)))
          (incf i rs)))
      (incf i ls))))

(defmethod save-image ((source image) (stream stream) (type (eql :raw)) &key)
  (let ((view (make-view source)))
    (save-image view stream type)))
