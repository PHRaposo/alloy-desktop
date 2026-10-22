(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((stream stream) (type (eql :ter)) &key (decode T))
  (let ((terrain (terrable:read-terrain stream)))
    (tg:cancel-finalization terrain)
    (make-image* (terrable:data terrain)
                 :signed-short :r
                 (terrable:width terrain)
                 (terrable:height terrain))))

(defmethod save-image ((source image) (stream stream) (type (eql :ter)) &rest args)
  (check-image-compatible source '(:r) :channel-types '(:signed-short))
  (let ((terrain (apply #'make-instance 'terrable:terrain
                        :width (w source) :height (h source)
                        :data (data source) args)))
    (terrable:write-terrain terrain stream)))
