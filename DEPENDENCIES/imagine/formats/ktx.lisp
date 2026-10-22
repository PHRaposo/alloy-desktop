(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :ktx)) &key (decode T))
  (let ((ktx (org.shirakumo.ktx:read-file stream)))
    (loop for mip across (org.shirakumo.ktx:mipmaps ktx)
          collect (make-image* (org.shirakumo.ktx:data mip)
                               (org.shirakumo.ktx:gl-type ktx)
                               (org.shirakumo.ktx:gl-format ktx)
                               (org.shirakumo.ktx:width ktx)
                               (org.shirakumo.ktx:height ktx)))))

(defmethod save-image ((source image) (stream stream) (type (eql :ktx)) &key)
  (let ((ktx (org.shirakumo.ktx:create-file
              (data source)
              (channel-type source)
              (layout source)
              :width (w source) :height (h source) :depth (d source))))
    (org.shirakumo.ktx:write-file ktx stream)))
