(in-package #:alloy-desktop-examples)

;;; 10 - Registered owner and owned window.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[10] Two windows open: \"10 - Owner window\" (620x380) and \"10 - Owned window\" (420x220),~%")
  (format t "[10] the second owned by the first through (setf window-owner).~%")
  (format t "[10] Do: click the owner window; minimize the owner; restore it; then close the owner.~%")
  (format t "[10] Expected: the owned window stays above its owner when the owner is clicked, and follows it when minimized and restored.~%")
  (format t "[10] Expected when the owner is closed: the owned window closes with it.~%")
  (format t "[10] Must NOT happen: the owned window falling behind its owner.~%")
  (format t "[10] Close the windows to end the example.~%")
  (finish-output)
  (multiple-value-bind (owner)
      (alloy-desktop:make-window
       screen
       :title "10 - Owner window"
       :x 220 :y 170 :width 620 :height 380
       :resizable-p nil)
    (multiple-value-bind (owned)
        (alloy-desktop:make-window
         screen
         :title "10 - Owned window"
         :x 610 :y 360 :width 420 :height 220
         :resizable-p nil)
      (setf (alloy-desktop:window-owner owned) owner)
      (alloy-desktop:show-window owner)
      (alloy-desktop:show-window owned))))
