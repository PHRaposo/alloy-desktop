(in-package #:org.shirakumo.fraf.imagine)

(defmethod load-image ((source stream) (type (eql :qoi)) &key (decode T))
  (cond (decode
         (multiple-value-bind (image width height channels) (qoi:decode source)
           (make-image* image
                        :unsigned-byte
                        (ecase channels
                          (1 :r)
                          (2 :ra)
                          (3 :rgb)
                          (4 :rgba))
                        width
                        height)))
        (T
         (assert (= (nibbles:read-ub32/be source) qoi::+qoi-magic+))
         (make-image*
          NIL
          :unsigned-byte
          (ecase (read-byte source)
            (1 :red)
            (2 :ra)
            (3 :rgb)
            (4 :rgba))
          (nibbles:read-ub32/be source)
          (nibbles:read-ub32/be source)))))

(defmethod save-image ((source image) (stream stream) (type (eql :qoi)) &key)
  (check-image-compatible source '(:r :ra :rgb :rgba))
  (qoi:encode stream (data source)
              (w source) (h source)
              (ecase (layout source)
                (1 :r)
                (2 :ra)
                (3 :rgb)
                (4 :rgba))
              1))
