(in-package #:alloy-desktop-examples)

;;; 09 - Always-on-top window over a normal window.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[09] Two windows open: \"09 - Normal window\" (620x380) and \"09 - Always on top\" (420x220), overlapping.~%")
  (format t "[09] The normal window is raised last, yet the always-on-top window must stay above it.~%")
  (format t "[09] Do: click the normal window; also open another application's window over the area.~%")
  (format t "[09] Expected: \"09 - Always on top\" stays above the normal window and above other applications.~%")
  (format t "[09] Must NOT happen: the always-on-top window hidden behind any other window.~%")
  (format t "[09] Close both windows to end the example.~%")
  (finish-output)
  (multiple-value-bind (normal)
      (alloy-desktop:make-window
       screen
       :title "09 - Normal window"
       :x 220 :y 190 :width 620 :height 380
       :resizable-p nil)
    (multiple-value-bind (floating)
        (alloy-desktop:make-window
         screen
         :title "09 - Always on top"
         :x 520 :y 330 :width 420 :height 220
         :always-on-top-p t
         :resizable-p nil)
      (alloy-desktop:show-window normal)
      (alloy-desktop:show-window floating)
      (alloy-desktop:raise-window normal))))
