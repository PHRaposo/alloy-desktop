(in-package #:org.shirakumo.fraf.imagine)

(defmethod channel-reader ((data org.shirakumo.memory-regions:memory-region) format)
  (channel-reader (org.shirakumo.memory-regions:memory-region-pointer data) format))

(defmethod channel-writer ((data org.shirakumo.memory-regions:memory-region) format)
  (channel-reader (org.shirakumo.memory-regions:memory-region-pointer data) format))

(defmethod org.shirakumo.memory-regions:call-with-memory-region ((function function) (image image) &rest args &key &allow-other-keys)
  (apply #'org.shirakumo.memory-regions:call-with-memory-region function (data image) args))
