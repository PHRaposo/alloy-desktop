(defpackage #:float-features
  (:nicknames #:org.shirakumo.float-features)
  (:use #:cl)
  (:export
   #:short-float-positive-infinity
   #:short-float-negative-infinity
   #:short-float-nan
   #:single-float-positive-infinity
   #:single-float-negative-infinity
   #:single-float-nan
   #:double-float-positive-infinity
   #:double-float-negative-infinity
   #:double-float-nan
   #:long-float-positive-infinity
   #:long-float-negative-infinity
   #:long-float-nan
   #:float-infinity-p
   #:float-nan-p
   #:with-float-traps-masked
   #:with-rounding-mode
   #:short-float-bits
   #:single-float-bits
   #:double-float-bits
   #:long-float-bits
   #:bits-short-float
   #:bits-single-float
   #:bits-double-float
   #:bits-long-float))

(in-package #:org.shirakumo.float-features)

(when (= most-positive-short-float most-positive-single-float)
  (pushnew :short-floats-are-single-floats *features*))
(when (= most-positive-long-float most-positive-double-float)
  (pushnew :long-floats-are-double-floats *features*))

(labels ((add-feature (bittage type)
           (pushnew (intern (format NIL "~a-BIT-~aS" bittage type) "KEYWORD") *features*))
         (test-bittage (float type)
           (let ((exponent-bits (round (log float 2))))
             (cond ((= (ash 1 4) exponent-bits)
                    (add-feature 16 type))
                   ((= (ash 1 7) exponent-bits)
                    (add-feature 32 type))
                   ((= (ash 1 10) exponent-bits)
                    (add-feature 64 type))
                   ((= (ash 1 14) exponent-bits)
                    (add-feature 128 type))
                   ((= (ash 1 19) exponent-bits)
                    (add-feature 256 type))))))
  (test-bittage most-positive-short-float 'short-float)
  (test-bittage most-positive-single-float 'single-float)
  (test-bittage most-positive-double-float 'double-float)
  (test-bittage most-positive-long-float 'long-float))
