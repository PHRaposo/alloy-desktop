(in-package #:org.shirakumo.fraf.imagine)

(defun list-eql-specializers (function &rest args)
  (delete-duplicates
   (loop for method in (c2mop:generic-function-methods function)
         for spec = (loop for arg in args
                          collect (nth arg (c2mop:method-specializers method)))
         when (loop for arg in spec
                    thereis (typep arg 'c2mop:eql-specializer))
         append (loop for arg in spec
                      collect (if (typep arg 'c2mop:eql-specializer) (c2mop:eql-specializer-object arg) arg)))))

(defun kw (thing)
  (intern (string-upcase thing) "KEYWORD"))

(defmethod ensure-file-type ((thing string))
  (let* ((slash (position #\/ thing :from-end T))
         (backslash (position #\\ thing :from-end T))
         (sep (max (or slash -1) (or backslash -1)))
         (dot (position #\. thing :from-end T)))
    (cond ((and dot (> dot (1+ sep)) (< dot (1- (length thing))))
           (kw (subseq thing (1+ dot))))
          ((and slash (null dot) (< slash (1- (length thing))))
           (kw (subseq thing (1+ slash))))
          (T (error "No known file type for ~a" thing)))))

(defmethod ensure-file-type ((thing stream))
  (ensure-file-type (file-namestring thing)))

(defmethod ensure-file-type ((thing pathname))
  (ensure-file-type (file-namestring thing)))

(defun infer-channel-type (bits/channel &optional (type :unsigned))
  (ecase type
    (:unsigned
     (ecase bits/channel
       (8 :unsigned-byte)
       (16 :unsigned-short)
       (32 :unsigned-int)
       (64 :unsigned-long)))
    (:signed
     (ecase bits/channel
       (8 :signed-byte)
       (16 :signed-short)
       (32 :signed-int)
       (64 :signed-long)))
    (:float
     (ecase bits/channel
       (16 :half-float)
       (32 :float)
       (64 :double)))))

(declaim (inline sb-aref (setf sb-aref)))
(defun sb-aref (array index)
  (let ((byte (aref array index)))
    (logior byte (- (mask-field (byte 1 7) byte)))))

(defun (setf sb-aref) (value array index)
  (setf (aref array index) (logand #xFF value)))

(defun luminance (r g b)
  (+ (* r 0.299)
     (* g 0.587)
     (* b 0.114)))
