(in-package #:alloy-desktop-examples)

;;; 11 - Focus and front-window ordering.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[11] Two overlapping windows open: \"11 - Back window\" (600x360) and \"11 - Raised to front\" (500x280).~%")
  (format t "[11] The second is raised with raise-window after both are shown.~%")
  (format t "[11] Do: look at the stacking and the active title bar; then click the back window, then the front one.~%")
  (format t "[11] Expected: \"11 - Raised to front\" opens on top with the active title bar; each click brings the clicked window to the front.~%")
  (format t "[11] Must NOT happen: the back window on top at start, or a click failing to bring its window forward.~%")
  (format t "[11] Close both windows to end the example.~%")
  (finish-output)
  (multiple-value-bind (back)
      (alloy-desktop:make-window
       screen
       :title "11 - Back window"
       :x 260 :y 190 :width 600 :height 360
       :resizable-p nil)
    (multiple-value-bind (front)
        (alloy-desktop:make-window
         screen
         :title "11 - Raised to front"
         :x 520 :y 330 :width 500 :height 280
         :resizable-p nil)
      (alloy-desktop:show-window back)
      (alloy-desktop:show-window front)
      (alloy-desktop:raise-window front))))
