(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((path pathname) (type (eql :tga)) &key (decode T))
  ;; This library blows and requires a file interface for no good reason.
  (let ((tga (tga:read-tga path)))
    (make-image* (tga:image-data tga)
                 (infer-channel-type (/ (tga:image-bpp tga) (tga:image-channels tga)))
                 (ecase (tga:image-channels tga)
                   (1 :r)
                   (2 :gr)
                   (3 :bgr)
                   (4 :bgra))
                 (tga:image-width tga)
                 (tga:image-height tga))))
