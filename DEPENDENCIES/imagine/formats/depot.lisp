(in-package #:org.shirakumo.fraf.imagine)

(defmethod ensure-file-type ((thing org.shirakumo.depot:entry))
  (ensure-file-type (org.shirakumo.depot:name thing)))

(defmethod load-image ((entry org.shirakumo.depot:entry) (type symbol) &rest args &key &allow-other-keys)
  (if (eql T type)
      (call-next-method)
      (org.shirakumo.depot:with-open (tx entry :input '(unsigned-byte 8))
        (apply #'load-image tx type args))))

(defmethod load-image ((tx org.shirakumo.depot:transaction) (type symbol) &rest args &key &allow-other-keys)
  (if (eql T type)
      (call-next-method)
      (apply #'load-image (org.shirakumo.depot:to-stream tx) type args)))

(defmethod save-image (source (entry org.shirakumo.depot:entry) (type symbol) &rest args &key &allow-other-keys)
  (if (eql T type)
      (call-next-method)
      (org.shirakumo.depot:with-open (tx entry :output '(unsigned-byte 8))
        (apply #'save-image source tx type args))))

(defmethod save-image (source (tx org.shirakumo.depot:transaction) (type symbol) &rest args &key &allow-other-keys)
  (if (eql T type)
      (call-next-method)
      (apply #'save-image source (org.shirakumo.depot:to-stream tx) type args)))
