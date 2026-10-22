(in-package #:org.shirakumo.fraf.imagine)

(defun %devil-image-to-source (image decode)
  (cl-devil:with-bound-image image
    (let ((size (* (cl-devil:image-width)
                   (cl-devil:image-height)
                   (cl-devil:image-bytes-per-pixel))))
      (make-image* (when decode
                     (org.shirakumo.memory-regions:replace
                      (org.shirakumo.memory-regions:allocate NIL size)
                      (org.shirakumo.memory-regions:memory-region (cl-devil:get-data) size)))
                   (cl-devil:image-type)
                   (case (cl-devil:image-format)
                     (:luminance :r)
                     (:luminance-alpha :ra)
                     (T (cl-devil:image-format)))
                   (cl-devil:image-width)
                   (cl-devil:image-height)
                   1 (ecase (cl-devil:image-origin)
                       (:origin-lower-left :bottom-left)
                       (:origin-upper-left :top-left))))))

(defmethod load-image ((path pathname) (type symbol) &key (decode T))
  (cl-devil:with-images ((image path))
    (%devil-image-to-source image decode)))

(defmethod load-image (source (type symbol) &key (decode T))
  (org.shirakumo.memory-regions:with-memory-region (region source)
    (cl-devil:with-images ((image type
                                  (org.shirakumo.memory-regions:memory-region-pointer region)
                                  (org.shirakumo.memory-regions:memory-region-size region)))
      (%devil-image-to-source image decode))))

(defmethod save-image ((source image) (path pathname) type &key)
  (check-image-compatible source '(:r :ra :rgb :rgba) :channel-types '(:unsigned-byte :unsigned-short :unsigned-int))
  (org.shirakumo.memory-regions:with-memory-region (region (data source))
    (cl-devil:with-images (image)
      (cl-devil:with-bound-image image
        (cl-devil:tex-image (w source) (h source) (d source) (pixel-stride source)
                            (case (layout source)
                              (:r :luminance)
                              (:ra :luminance-alpha)
                              (T (layout source)))
                            (channel-type source)
                            (org.shirakumo.memory-regions:memory-region-pointer region))
        (cl-devil:save type path)))))
