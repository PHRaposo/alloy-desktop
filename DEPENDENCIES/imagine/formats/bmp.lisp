(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :bmp)) &key (decode T))
  (let ((bmp (org.shirakumo.bmp:read-bmp stream)))
    (cond (decode
           (multiple-value-bind (data width height channels) (org.shirakumo.bmp:decode-pixels bmp)
             (make-image* data
                          :unsigned-byte
                          (ecase channels
                            (1 :r)
                            (2 :ra)
                            (3 :bgr)
                            (4 :bgra))
                          width
                          height
                          1 :bottom-left)))
          (T
           (make-image* NIL
                        :unsigned-byte
                        (ecase (org.shirakumo.bmp:bytes/color bmp)
                          (1 :r)
                          (2 :ra)
                          (3 :bgr)
                          (4 :bgra))
                        (org.shirakumo.bmp:width bmp)
                        (org.shirakumo.bmp:height bmp)
                        1 :bottom-left)))))

(defmethod save-image ((source image) (stream stream) (type (eql :bmp)) &key)
  (check-image-compatible source '(:r :ra :bgr :bgra))
  (let ((bmp (org.shirakumo.bmp:make-bmp)))
    (org.shirakumo.bmp:encode-pixels
     bmp (data source) (w source) (h source)
     (ecase (layout source)
       (:r 1)
       (:ra 2)
       (:bgr 3)
       (:bgra 4)))
    (org.shirakumo.bmp:write-bmp bmp stream)))
