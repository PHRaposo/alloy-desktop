(in-package #:alloy-desktop-examples)

;;; 14 - Light and dark window palettes.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[14] Two 500x280 windows open side by side: \"14 - Light palette\" (left) and \"14 - Dark palette\" (right).~%")
  (format t "[14] Do: compare the two content areas; drag one window over the other and away.~%")
  (format t "[14] Expected: the left content is light grey (0.94), the right one dark grey (0.12), both uniform and repainted after the drag.~%")
  (format t "[14] Must NOT happen: both windows the same colour, a white/black flash, or unpainted strips.~%")
  (format t "[14] Close both windows to end the example.~%")
  (finish-output)
  (multiple-value-bind (light)
      (alloy-desktop:make-window
       screen
       :title "14 - Light palette"
       :x 140 :y 180 :width 500 :height 280
       :palette :light
       :background-color (alloy-desktop:rgb 0.94 0.94 0.94 1.0)
       :resizable-p nil)
    (multiple-value-bind (dark)
        (alloy-desktop:make-window
         screen
         :title "14 - Dark palette"
         :x 710 :y 180 :width 500 :height 280
         :palette :dark
         :background-color (alloy-desktop:rgb 0.12 0.12 0.12 1.0)
         :resizable-p nil)
      (alloy-desktop:show-window light)
      (alloy-desktop:show-window dark))))
