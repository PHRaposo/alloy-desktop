(in-package #:alloy-desktop-examples)

;;; 13 - Hide/show lifecycle.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[13] A 600x340 window is shown, hidden with hide-window, then shown again with show-window.~%")
  (format t "[13] The console prints window-visible-p after the hide and after the second show.~%")
  (format t "[13] Do: look at the window once it is on screen.~%")
  (format t "[13] Expected: the window is visible and painted, with its title, at the end.~%")
  (format t "[13] Expected prints: after hide NIL, after show T.~%")
  (format t "[13] Must NOT happen: the window staying hidden, or coming back black/unpainted.~%")
  (format t "[13] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "13 - Hidden, then shown again"
       :width 600 :height 340
       :resizable-p nil)
    (alloy-desktop:show-window window)
    (alloy-desktop:hide-window window)
    (format t "[13] after hide-window: window-visible-p = ~S~%"
            (alloy-desktop:window-visible-p window))
    (alloy-desktop:show-window window)
    (format t "[13] after show-window: window-visible-p = ~S~%"
            (alloy-desktop:window-visible-p window))
    (finish-output)))
