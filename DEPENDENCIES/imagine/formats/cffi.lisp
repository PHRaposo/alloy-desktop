(in-package #:org.shirakumo.fraf.imagine)

(defmacro %ffifun (args &body body)
  `(lambda ,args
     (declare (type cffi:foreign-pointer a))
     (declare (type (unsigned-byte 32) i))
     (declare (optimize speed (safety 0)))
     ,@body))

(defmethod channel-reader ((data T) (format (eql :unsigned-byte)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :uint8 i) (1- (ash 1 8)))))

(defmethod channel-reader ((data T) (format (eql :unsigned-short)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :uint16 i) (1- (ash 1 16)))))

(defmethod channel-reader ((data T) (format (eql :unsigned-int)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :uint32 i) (1- (ash 1 32)))))

(defmethod channel-reader ((data T) (format (eql :unsigned-long)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :uint64 i) (1- (ash 1 64)))))

(defmethod channel-reader ((data T) (format (eql :signed-byte)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :int8 i) (ash 1 7))))

(defmethod channel-reader ((data T) (format (eql :signed-short)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :int16 i) (ash 1 15))))

(defmethod channel-reader ((data T) (format (eql :signed-int)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :int32 i) (ash 1 31))))

(defmethod channel-reader ((data T) (format (eql :signed-long)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (/ (cffi:mem-ref a :int64 i) (ash 1 63))))

;; TODO: half-float

(defmethod channel-reader ((data T) (format (eql :float)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (cffi:mem-ref a :float i)))

(defmethod channel-reader ((data T) (format (eql :double)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (a i) (cffi:mem-ref a :double i)))

(defmethod channel-writer ((data T) (format (eql :unsigned-byte)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-aref a :uint8 i) (truncate (* v (1- (ash 1 8)))))))

(defmethod channel-writer ((data T) (format (eql :unsigned-short)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :uint16 i) (truncate (* v (1- (ash 1 16)))))))

(defmethod channel-writer ((data T) (format (eql :unsigned-int)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :uint32 i) (truncate (* v (1- (ash 1 16)))))))

(defmethod channel-writer ((data T) (format (eql :unsigned-long)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :uint64 i) (truncate (* v (1- (ash 1 16)))))))

;; FIXME: not correct entirely due to lack of accounting for difference in space
;;        for negative and positive numbers
(defmethod channel-writer ((data T) (format (eql :signed-byte)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :int8 i) (truncate (* v (ash 1 7))))))

(defmethod channel-writer ((data T) (format (eql :signed-short)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :int16 i) (truncate (* v (ash 1 15))))))

(defmethod channel-writer ((data T) (format (eql :signed-int)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :int32 i) (truncate (* v (ash 1 31))))))

(defmethod channel-writer ((data T) (format (eql :signed-long)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :int64 i) (truncate (* v (ash 1 63))))))

;; TODO: half-float

(defmethod channel-writer ((data T) (format (eql :float)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :float i) (float v 0f0))))

(defmethod channel-writer ((data T) (format (eql :double)))
  (check-type data cffi:foreign-pointer)
  (%ffifun (v a i) (setf (cffi:mem-ref a :double i) (float v 0d0))))
