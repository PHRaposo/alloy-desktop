(in-package #:org.shirakumo.fraf.imagine)

(defmethod pixel-stride ((_ (eql :unsigned-int-5-9-9-9-rev))) 4)

(defmethod load-image ((stream stream) (type (eql :hdr)) &key (decode T) bottom-up)
  (cond (decode
         (let ((file (3b-hdr:read-hdr-stream stream :y-up bottom-up)))
           (make-image* (3b-hdr:data file)
                        (3b-hdr:gl-pixel-type file)
                        (3b-hdr:gl-pixel-format file)
                        (3b-hdr:width file)
                        (3b-hdr:height file)
                        1 (if bottom-up :bottom-left :top-left))))
        (T
         (let* ((file (make-instance '3b-hdr::buf :stream stream))
                (header (3b-hdr::read-hdr-header file)))
           (make-image* NIL
                        :unsigned-int-5-9-9-9-rev
                        :rgb
                        (getf header :width)
                        (getf header :height)
                        1 (if bottom-up :bottom-left :top-left))))))

(defmethod save-image ((source image) (stream stream) (type (eql :hdr)) &key exposure)
  (check-image-compatible source '(:rgb) :channel-types '(:float :unsigned-int-5-9-9-9-rev))
  (let ((file (make-instance '3b-hdr:hdr-file :width (w source) :height (h source) 
                                              :pixel-type (channel-type source)
                                              :pixel-format (layout source)
                                              :data (data source)
                                              :exposure exposure)))
    (3b-hdr:write-hdr-stream stream file)))
