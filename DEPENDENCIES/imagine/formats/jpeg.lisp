(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((path pathname) (type (eql :jpeg)) &key (decode T))
  (multiple-value-bind (image height width components) (jpeg:decode-image path)
    (make-image* image
                 :unsigned-byte
                 (ecase components
                   (1 :r)
                   (2 :ar)
                   (3 :bgr)
                   (4 :bgra))
                 width height)))

(defmethod load-image ((stream stream) (type (eql :jpeg)) &key (decode T))
  (multiple-value-bind (image height width components) (jpeg:decode-stream stream)
    (make-image* image
                 :unsigned-byte
                 (ecase components
                   (1 :r)
                   (2 :ar)
                   (3 :bgr)
                   (4 :bgra))
                 width height)))

(defmethod load-image :around (path (type (eql :jpg)) &rest args &key &allow-other-keys)
  (apply #'load-image path :jpeg args))

(defmethod save-image ((source image) (stream stream) (type (eql :jpeg)) &key)
  (check-image-compatible source '(:r :ra :bgr :bgra))
  (jpeg:encode-image-stream stream (data source)
                            (ecase (layout source)
                              (:bgra 4) (:bgr 3) (:ra 2) (:r 1))
                            (h source) (w source)))

(defmethod save-image (source target (type (eql :jpg)) &rest args)
  (apply #'save-image source target :jpeg args))
