(in-package #:alloy-desktop-examples)

;;; 01 - Minimal fixed-size window with a title.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[01] A 640x360 window titled \"01 - Window title\" opens. It cannot be resized.~%")
  (format t "[01] Expected: the title bar shows the title; the resize cursor never appears on its edges.~%")
  (format t "[01] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "01 - Window title"
       :width 640 :height 360
       :resizable-p nil)
    (alloy-desktop:show-window window)))
