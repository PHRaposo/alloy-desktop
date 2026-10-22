(in-package #:org.shirakumo.fraf.imagine)

(defun %png-source (png decode bottom-up)
  (let ((data (when decode (pngload:data png))))
    (when (and data (eql :greyscale (pngload:color-type png))
               (< (pngload:bit-depth png) 8))
      (let ((maxv (1- (ash 1 (pngload:bit-depth png)))))
        (dotimes (i (length data))
          (setf (aref data i) (round (* 255 (aref data i)) maxv)))))
    (make-image* data
               (infer-channel-type (max 8 (pngload:bit-depth png)))
               (ecase (pngload:color-type png)
                 (:greyscale :r)
                 (:greyscale-alpha :ra)
                 (:truecolour :rgb)
                 (:truecolour-alpha :rgba)
                 (:indexed-colour
                  ;; This fucking sucks, man.
                  (ecase (truncate (length (pngload:data png))
                                   (* (pngload:width png) (pngload:height png)))
                    (4 :rgba)
                    (3 :rgb)
                    (2 :ra)
                    (1 :red)
                    (0 :rgb))))
               (pngload:width png) (pngload:height png)
               1 (if bottom-up :bottom-left :top-left))))

(defmethod load-image ((source stream) (typ (eql :png)) &key (decode T) bottom-up)
  (handler-bind ((pngload::png-warning #'muffle-warning))
    (%png-source (pngload:load-stream source :flatten T :decode decode :flip-y bottom-up) decode bottom-up)))

(defmethod load-image ((source org.shirakumo.memory-regions:memory-region) (type (eql :png)) &key (decode T) bottom-up)
  (let ((png (pngload::make-png))
        (state (pngload::make-state :decode-data decode
                                    :flip-y bottom-up
                                    :flatten T
                                    :use-static-vector NIL
                                    :unknown-chunk-warnings NIL)))
    (setf (pngload::state png) state)
    (3bz:with-octet-pointer (pointer-binding (org.shirakumo.memory-regions:memory-region-pointer source)
                                             (org.shirakumo.memory-regions:memory-region-size source))
      (let ((source (make-instance 'pngload::octet-pointer-source
                                   :data (org.shirakumo.memory-regions:memory-region-pointer source)
                                   :end (org.shirakumo.memory-regions:memory-region-size source))))
        (handler-bind ((pngload::png-warning #'muffle-warning))
          (setf (pngload::state-source state) source
                (pngload::state-mmap-pointer state) pointer-binding
                (pngload::parse-tree png) (pngload::parse-datastream png)))))
    (%png-source png decode bottom-up)))

(defmethod save-image ((source image) (stream stream) (type (eql :png)) &key)
  (check-image-compatible source '(:r :ra :rgb :rgba))
  (let ((channels (ecase (layout source) (:rgba 4) (:rgb 3) (:ra 2) (:r 1))))
    (zpng:write-png-stream (make-instance 'zpng:png
                                          :color-type (ecase channels
                                                        (4 :truecolor-alpha)
                                                        (3 :truecolor)
                                                        (2 :grayscale-alpha)
                                                        (1 :grayscale))
                                          :width (w source) :height (h source)
                                          :image-data (data source))
                           stream)))
