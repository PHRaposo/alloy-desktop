(in-package #:org.shirakumo.fraf.imagine)

(defmacro %reflambda (args &body body)
  `(lambda ,args
     (declare (type (simple-array (unsigned-byte 8) (*)) a))
     (declare (type (unsigned-byte 32) i))
     (declare (optimize speed (safety 0)))
     ,@body))

(defmethod channel-reader ((data vector) (format (eql :unsigned-byte)))
  (%reflambda (a i) (/ (aref a i) (1- (ash 1 8)))))

(defmethod channel-reader ((data vector) (format (eql :unsigned-short)))
  (%reflambda (a i) (/ (nibbles:ub16ref/le a i) (1- (ash 1 16)))))

(defmethod channel-reader ((data vector) (format (eql :unsigned-int)))
  (%reflambda (a i) (/ (nibbles:ub32ref/le a i) (1- (ash 1 32)))))

(defmethod channel-reader ((data vector) (format (eql :unsigned-long)))
  (%reflambda (a i) (/ (nibbles:ub64ref/le a i) (1- (ash 1 64)))))

(defmethod channel-reader ((data vector) (format (eql :signed-byte)))
  (%reflambda (a i) (/ (sb-aref a i) (ash 1 7))))

(defmethod channel-reader ((data vector) (format (eql :signed-short)))
  (%reflambda (a i) (/ (nibbles:sb16ref/le a i) (ash 1 15))))

(defmethod channel-reader ((data vector) (format (eql :signed-int)))
  (%reflambda (a i) (/ (nibbles:sb32ref/le a i) (ash 1 31))))

(defmethod channel-reader ((data vector) (format (eql :signed-long)))
  (%reflambda (a i) (/ (nibbles:sb64ref/le a i) (ash 1 63))))

;; TODO: half-float

(defmethod channel-reader ((data vector) (format (eql :float)))
  (%reflambda (a i) (nibbles:ieee-single-ref/le a i)))

(defmethod channel-reader ((data vector) (format (eql :double)))
  (%reflambda (a i) (nibbles:ieee-double-ref/le a i)))

(defmethod channel-writer ((data vector) (format (eql :unsigned-byte)))
  (%reflambda (v a i) (setf (aref a i) (truncate (* v (1- (ash 1 8)))))))

(defmethod channel-writer ((data vector) (format (eql :unsigned-short)))
  (%reflambda (v a i) (setf (nibbles:ub16ref/le a i) (truncate (* v (1- (ash 1 16)))))))

(defmethod channel-writer ((data vector) (format (eql :unsigned-int)))
  (%reflambda (v a i) (setf (nibbles:ub32ref/le a i) (truncate (* v (1- (ash 1 16)))))))

(defmethod channel-writer ((data vector) (format (eql :unsigned-long)))
  (%reflambda (v a i) (setf (nibbles:ub64ref/le a i) (truncate (* v (1- (ash 1 16)))))))

;; FIXME: not correct entirely due to lack of accounting for difference in space
;;        for negative and positive numbers
(defmethod channel-writer ((data vector) (format (eql :signed-byte)))
  (%reflambda (v a i) (setf (sb-aref a i) (truncate (* v (ash 1 7))))))

(defmethod channel-writer ((data vector) (format (eql :signed-short)))
  (%reflambda (v a i) (setf (nibbles:sb16ref/le a i) (truncate (* v (ash 1 15))))))

(defmethod channel-writer ((data vector) (format (eql :signed-int)))
  (%reflambda (v a i) (setf (nibbles:sb32ref/le a i) (truncate (* v (ash 1 31))))))

(defmethod channel-writer ((data vector) (format (eql :signed-long)))
  (%reflambda (v a i) (setf (nibbles:sb64ref/le a i) (truncate (* v (ash 1 63))))))

;; TODO: half-float

(defmethod channel-writer ((data vector) (format (eql :float)))
  (%reflambda (v a i) (setf (nibbles:ieee-single-ref/le a i) (float v 0f0))))

(defmethod channel-writer ((data vector) (format (eql :double)))
  (%reflambda (v a i) (setf (nibbles:ieee-double-ref/le a i) (float v 0d0))))

(defmacro %pixreader (args &body body)
  `(lambda ,args
     (declare (type (function ((unsigned-byte 32)) (values real &optional)) f))
     (declare (type (unsigned-byte 32) i s))
     (declare (optimize speed (safety 0)))
     (declare (ignorable s))
     ,@body))

(defmethod pixel-reader ((layout (eql :r)))
  (%pixreader (f i s)
    (let ((r (funcall f i)))
      (values r r r 1))))

(defmethod pixel-reader ((layout (eql :ra)))
  (%pixreader (f i s)
    (let ((r (funcall f i))
          (a (funcall f (+ i s))))
      (values r r r a))))

(defmethod pixel-reader ((layout (eql :ar)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i s)))
          (a (funcall f i)))
      (values r r r a))))

(defmethod pixel-reader ((layout (eql :rgb)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 0))))
          (g (funcall f (+ i (* s 1))))
          (b (funcall f (+ i (* s 2)))))
      (values r g b 1))))

(defmethod pixel-reader ((layout (eql :bgr)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 2))))
          (g (funcall f (+ i (* s 1))))
          (b (funcall f (+ i (* s 1)))))
      (values r g b 1))))

(defmethod pixel-reader ((layout (eql :rgba)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 0))))
          (g (funcall f (+ i (* s 1))))
          (b (funcall f (+ i (* s 2))))
          (a (funcall f (+ i (* s 3)))))
      (values r g b a))))

(defmethod pixel-reader ((layout (eql :bgra)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 2))))
          (g (funcall f (+ i (* s 1))))
          (b (funcall f (+ i (* s 0))))
          (a (funcall f (+ i (* s 3)))))
      (values r g b a))))

(defmethod pixel-reader ((layout (eql :argb)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 1))))
          (g (funcall f (+ i (* s 2))))
          (b (funcall f (+ i (* s 3))))
          (a (funcall f (+ i (* s 0)))))
      (values r g b a))))

(defmethod pixel-reader ((layout (eql :abgr)))
  (%pixreader (f i s)
    (let ((r (funcall f (+ i (* s 3))))
          (g (funcall f (+ i (* s 2))))
          (b (funcall f (+ i (* s 1))))
          (a (funcall f (+ i (* s 0)))))
      (values r g b a))))

(defmacro %pixwriter (args &body body)
  `(lambda ,args
     (declare (type (function (real (unsigned-byte 32)) (values T &optional)) f))
     (declare (type (unsigned-byte 32) i s))
     (declare (type real r g b a))
     (declare (optimize speed (safety 1)))
     (declare (ignorable s g b a))
     ,@body))

(defmethod pixel-writer ((layout (eql :r)))
  (%pixwriter (f i s r g b a)
    (funcall f (luminance r g b) i)))

(defmethod pixel-writer ((layout (eql :ra)))
  (%pixwriter (f i s r g b a)
    (funcall f (luminance r g b) i)
    (funcall f a (+ i s))))

(defmethod pixel-writer ((layout (eql :ar)))
  (%pixwriter (f i s r g b a)
    (funcall f (luminance r g b) (+ i s))
    (funcall f a i)))

(defmethod pixel-writer ((layout (eql :rgb)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 0)))
    (funcall f g (+ i (* s 1)))
    (funcall f b (+ i (* s 2)))))

(defmethod pixel-writer ((layout (eql :bgr)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 2)))
    (funcall f g (+ i (* s 1)))
    (funcall f b (+ i (* s 0)))))

(defmethod pixel-writer ((layout (eql :rgba)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 0)))
    (funcall f g (+ i (* s 1)))
    (funcall f b (+ i (* s 2)))
    (funcall f a (+ i (* s 3)))))

(defmethod pixel-writer ((layout (eql :bgra)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 2)))
    (funcall f g (+ i (* s 1)))
    (funcall f b (+ i (* s 0)))
    (funcall f a (+ i (* s 3)))))

(defmethod pixel-writer ((layout (eql :argb)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 1)))
    (funcall f g (+ i (* s 2)))
    (funcall f b (+ i (* s 3)))
    (funcall f a (+ i (* s 0)))))

(defmethod pixel-writer ((layout (eql :abgr)))
  (%pixwriter (f i s r g b a)
    (funcall f r (+ i (* s 3)))
    (funcall f g (+ i (* s 2)))
    (funcall f b (+ i (* s 1)))
    (funcall f a (+ i (* s 0)))))
