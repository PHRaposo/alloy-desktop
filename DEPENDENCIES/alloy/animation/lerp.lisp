(in-package #:org.shirakumo.alloy.animation)

(defgeneric lerp (a b x))

(declaim (inline %lerp))
(defun %lerp (a b x)
  (declare (type single-float a b x))
  (declare (optimize speed))
  (+ (* a (- 1f0 x)) (* b x)))

(defmethod lerp ((a real) (b real) x)
  (%lerp (float a 0f0) (float b 0f0) (float x 0f0)))

(defmethod lerp ((a alloy:unit) (b alloy:unit) x)
  (alloy:px (%lerp (alloy:to-px a) (alloy:to-px b) (float x 0f0))))

(defmethod lerp ((a alloy:px) (b alloy:px) x)
  (alloy:px (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:vw) (b alloy:vw) x)
  (alloy:vw (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:vh) (b alloy:vh) x)
  (alloy:vh (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:pw) (b alloy:pw) x)
  (alloy:pw (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:ph) (b alloy:ph) x)
  (alloy:ph (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:un) (b alloy:un) x)
  (alloy:un (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:cm) (b alloy:cm) x)
  (alloy:cm (%lerp (alloy:unit-value a) (alloy:unit-value b) (float x 0f0))))

(defmethod lerp ((a alloy:point) (b alloy:point) x)
  (alloy:point (lerp (alloy:point-x a) (alloy:point-x b) x)
               (lerp (alloy:point-y a) (alloy:point-y b) x)))

(defmethod lerp ((a alloy:size) (b alloy:size) x)
  (alloy:size (lerp (alloy:size-w a) (alloy:size-w b) x)
              (lerp (alloy:size-h a) (alloy:size-h b) x)))

(defmethod lerp ((a alloy:margins) (b alloy:margins) x)
  (alloy:margins (lerp (alloy:margins-l a) (alloy:margins-l b) x)
                 (lerp (alloy:margins-u a) (alloy:margins-u b) x)
                 (lerp (alloy:margins-r a) (alloy:margins-r b) x)
                 (lerp (alloy:margins-b a) (alloy:margins-b b) x)))

(defmethod lerp ((a alloy:extent) (b alloy:extent) x)
  (alloy:extent (lerp (alloy:extent-x a) (alloy:extent-x b) x)
                (lerp (alloy:extent-y a) (alloy:extent-y b) x)
                (lerp (alloy:extent-w a) (alloy:extent-w b) x)
                (lerp (alloy:extent-h a) (alloy:extent-h b) x)))

(defmethod lerp ((a chroma:rgb) (b chroma:rgb) x)
  (let ((x (float x 0f0)))
    (chroma:rgb (%lerp (chroma:r a) (chroma:r b) x)
                 (%lerp (chroma:g a) (chroma:g b) x)
                 (%lerp (chroma:b a) (chroma:b b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))

(defmethod lerp ((a chroma:hsv) (b chroma:hsv) x)
  (let ((x (float x 0f0)))
    (chroma:hsv (%lerp (chroma:h a) (chroma:h b) x)
                 (%lerp (chroma:s a) (chroma:s b) x)
                 (%lerp (chroma:v a) (chroma:v b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))

(defmethod lerp ((a chroma:hsl) (b chroma:hsl) x)
  (let ((x (float x 0f0)))
    (chroma:hsl (%lerp (chroma:h a) (chroma:h b) x)
                 (%lerp (chroma:s a) (chroma:s b) x)
                 (%lerp (chroma:l a) (chroma:l b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))

(defmethod lerp ((a chroma:hsi) (b chroma:hsi) x)
  (let ((x (float x 0f0)))
    (chroma:hsi (%lerp (chroma:h a) (chroma:h b) x)
                 (%lerp (chroma:s a) (chroma:s b) x)
                 (%lerp (chroma:i a) (chroma:i b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))

(defmethod lerp ((a chroma:cmyk) (b chroma:cmyk) x)
  (let ((x (float x 0f0)))
    (chroma:cmyk (%lerp (chroma:c a) (chroma:c b) x)
                  (%lerp (chroma:m a) (chroma:m b) x)
                  (%lerp (chroma:y a) (chroma:y b) x)
                  (%lerp (chroma:k a) (chroma:k b) x)
                  (%lerp (chroma:a a) (chroma:a b) x))))

#++
(defmethod lerp ((a chroma:xyz) (b chroma:xyz) x)
  (let ((x (float x 0f0)))
    (chroma:xyz (%lerp (chroma:x* a) (chroma:x* b) x)
                 (%lerp (chroma:y* a) (chroma:y* b) x)
                 (%lerp (chroma:z* a) (chroma:z* b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))

#++
(defmethod lerp ((a chroma:lab) (b chroma:lab) x)
  (let ((x (float x 0f0)))
    (chroma:lab (%lerp (chroma:l* a) (chroma:l* b) x)
                 (%lerp (chroma:a* a) (chroma:a* b) x)
                 (%lerp (chroma:b* a) (chroma:b* b) x)
                 (%lerp (chroma:a a) (chroma:a b) x))))
