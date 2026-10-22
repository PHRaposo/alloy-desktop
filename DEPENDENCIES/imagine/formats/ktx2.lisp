(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :ktx2)) &key (decode T))
  (let ((ktx (if decode
                 (org.shirakumo.ktx2:read-file stream)
                 (org.shirakumo.ktx2:tell-file stream))))
    (loop for i from 0 below (org.shirakumo.ktx2:level-count ktx)
          collect (make-image* (when decode
                                 (aref (org.shirakumo.ktx2:level-images ktx) i))
                               (org.shirakumo.ktx2:gl-type ktx)
                               (org.shirakumo.ktx2:gl-format ktx)
                               (org.shirakumo.ktx2:width ktx)
                               (org.shirakumo.ktx2:height ktx)
                               (org.shirakumo.ktx2:depth ktx)))))

#++
(defmethod save-image ((source image) (stream stream) (type (eql :ktx2)) &key)
  (let ((ktx (org.shirakumo.ktx2:create-file
              (data source)
              (channel-type source)
              (layout source)
              :width (w source) :height (h source) :depth (d source))))
    (org.shirakumo.ktx:write-file ktx stream)))
