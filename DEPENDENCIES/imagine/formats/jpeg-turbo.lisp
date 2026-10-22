(in-package #:org.shirakumo.fraf.imagine)

(defun load-jpeg (source bottom-up)
  (org.shirakumo.memory-regions:with-memory-region (region source)
    (multiple-value-bind (buffer width height)
        (let ((jpeg (make-instance 'org.shirakumo.fraf.turbojpeg:decompressor :bottom-up bottom-up)))
          (unwind-protect (org.shirakumo.fraf.turbojpeg:load-image
                           (org.shirakumo.memory-regions:memory-region-pointer region) jpeg
                           :size (org.shirakumo.memory-regions:memory-region-size region)
                           :pixel-format :rgb
                           :buffer :vector)
            (org.shirakumo.fraf.turbojpeg:free jpeg)))
      (make-image* buffer :unsigned-byte :rgb width height 1 (if bottom-up :bottom-left :top-left)))))

(defun tell-jpeg (source)
  (org.shirakumo.memory-regions:with-memory-region (region source)
    (org.shirakumo.fraf.turbojpeg:init)
    (let ((jpeg (org.shirakumo.fraf.turbojpeg.cffi:make-handle :decompress)))
      (unwind-protect
           (let ((result (org.shirakumo.fraf.turbojpeg.cffi:decompress-header
                          jpeg (org.shirakumo.memory-regions:memory-region-pointer region) (org.shirakumo.memory-regions:memory-region-size region))))
             (if (< result 0)
                 (error "Not a valid jpeg file.")
                 (make-image* NIL
                              :unsigned-byte :rgb
                              (org.shirakumo.fraf.turbojpeg.cffi:get-parameter jpeg :width)
                              (org.shirakumo.fraf.turbojpeg.cffi:get-parameter jpeg :height))))
        (org.shirakumo.fraf.turbojpeg.cffi:free jpeg)))))

(defmethod load-image ((source pathname) (type (eql :jpeg)) &key (decode T) bottom-up)
  (if decode
      (load-jpeg source bottom-up)
      (tell-jpeg source)))

(defmethod load-image ((source vector) (type (eql :jpeg)) &key (decode T) bottom-up)
  (if decode
      (load-jpeg source bottom-up)
      (tell-jpeg source)))

(defmethod load-image (source (type (eql :jpeg)) &key (decode T) bottom-up)
  (if decode
      (load-jpeg source bottom-up)
      (tell-jpeg source)))

(defmethod load-image :around (path (type (eql :jpg)) &rest args &key &allow-other-keys)
  (apply #'load-image path :jpeg args))

(defmethod save-image ((source image) (stream stream) (type (eql :jpeg)) &key)
  (check-image-compatible source '(:r :ra :rgb :rgba :bgr :abgr :bgra :argb) :channel-types '(:unsigned-byte :unsigned-short))
  (org.shirakumo.fraf.turbojpeg:save-image
   stream (data source)
   (w source) (h source) T
   :pixel-format (layout source)
   :bit-depth (ecase (channel-type source)
                (:unsigned-byte 8)
                (:unsigned-short 16))))

(defmethod save-image :around (source target (type (eql :jpg)) &rest args &key &allow-other-keys)
  (apply #'save-image source target :jpeg args))
