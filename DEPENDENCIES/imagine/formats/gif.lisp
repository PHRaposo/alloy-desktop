(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :gif)) &key (decode T))
  (cond (decode
         (let* ((stream (skippy:read-data-stream stream))
                (w (skippy:width stream))
                (h (skippy:height stream)))
           (make-image* (first (skippy-renderer:render stream :byte-order :bgra)) :unsigned-byte :bgra w h)))
        (T
         (skippy::check-gif-signature stream)
         (make-image* NIL :unsigned-byte :bgra
                      (skippy::read-uint16 stream)
                      (skippy::read-uint16 stream)))))

(defmethod save-image ((source image) (stream stream) (type (eql :gif)) &key)
  (check-image-compatible source '(:rgba))
  (let ((canvas (skippy:make-canvas :width (w source) :height (h source) :image-data (data source))))
    (skippy:write-canvas canvas stream)))

