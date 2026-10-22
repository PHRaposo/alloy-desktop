(in-package #:org.shirakumo.alloy.observables)

(defclass tester (observable)
  ())

(define-activities tester
  (slot-value (value slot-name) "Fired when a slot value is set.")
  (finish () "Fires when the tester finishes testing."))
