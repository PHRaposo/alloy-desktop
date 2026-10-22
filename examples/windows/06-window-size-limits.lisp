(in-package #:alloy-desktop-examples)

;;; 06 - Minimum and maximum size limits.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[06] A 600x400 resizable window opens with size limits min 420x260 and max 760x520.~%")
  (format t "[06] Do: drag the bottom-right corner inwards as far as it goes, then outwards as far as it goes.~%")
  (format t "[06] Expected: the content stops shrinking at 420x260 and stops growing at 760x520.~%")
  (format t "[06] Must NOT happen: the window going below or beyond those sizes, or flickering at the limit.~%")
  (format t "[06] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "06 - Size limits: min 420x260 / max 760x520"
       :width 600 :height 400)
    (alloy-desktop:set-window-size-limits window 420 260 760 520)
    (alloy-desktop:show-window window)))
