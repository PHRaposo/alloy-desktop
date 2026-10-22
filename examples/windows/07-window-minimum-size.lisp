(in-package #:alloy-desktop-examples)

;;; 07 - Minimum size only (set-window-min-size).
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[07] A 640x420 resizable window opens with a minimum size of 500x320 and no maximum.~%")
  (format t "[07] Do: drag the bottom-right corner inwards as far as it goes, then drag it far outwards.~%")
  (format t "[07] Expected: the content stops shrinking at 500x320; growing is not limited.~%")
  (format t "[07] Must NOT happen: the window going below 500x320, or a maximum size being enforced.~%")
  (format t "[07] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "07 - Minimum size: 500x320"
       :width 640 :height 420)
    (alloy-desktop:set-window-min-size window 500 320)
    (alloy-desktop:show-window window)))
