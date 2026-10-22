(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :svg)) &key (decode T))
  (let ((str (with-output-to-string (out)
               (loop with buf = (make-string 4096)
                     for read = (read-sequence buf stream)
                     while (< 0 read)
                     do (write-sequence buf out :end read)))))
    (org.shirakumo.fraf.resvg:with-image (svg str)
      (cond (decode
             (multiple-value-bind (pixels width height) (org.shirakumo.fraf.resvg:render svg)
               (make-image* pixels :unsigned-byte :rgba width height)))
            (T
             (destructuring-bind (w . h) (org.shirakumo.fraf.resvg:size svg)
               (make-image* NIL :unsigned-byte :rgba (round w) (round h))))))))

