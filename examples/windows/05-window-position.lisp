(in-package #:alloy-desktop-examples)

;;; 05 - Requested initial position and size.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[05] One window opens with its outer frame's top-left corner at x=240 y=180 of the screen and a 560x320 content area.~%")
  (format t "[05] Do: check where the frame's top-left corner sits on the screen.~%")
  (format t "[05] Expected: the frame starts 240 px from the left and 180 px from the top of the screen; the content area is 560x320.~%")
  (format t "[05] Must NOT happen: the window centred, cascaded by the OS, or with its title bar off-screen.~%")
  (format t "[05] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "05 - Position x=240 y=180, size 560x320"
       :x 240 :y 180 :width 560 :height 320
       :resizable-p nil)
    (alloy-desktop:show-window window)))
