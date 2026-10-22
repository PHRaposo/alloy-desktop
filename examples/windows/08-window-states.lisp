(in-package #:alloy-desktop-examples)

;;; 08 - Native window states: minimize, restore, maximize. The final visible state is maximized.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[08] A 620x380 window opens, is minimized, restored and then maximized by direct API calls.~%")
  (format t "[08] The console prints window-visible-p and window-maximized-p after each call.~%")
  (format t "[08] Do: look at the window once the calls are done; then use the title-bar restore button.~%")
  (format t "[08] Expected: the window ends maximized, filling the work area; restore brings it back to 620x380.~%")
  (format t "[08] Expected prints: after minimize NIL/NIL, after restore T/NIL, after maximize T/T.~%")
  (format t "[08] Must NOT happen: the window left minimized in the taskbar, or ending at its normal size.~%")
  (format t "[08] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "08 - Window states (maximized)"
       :width 620 :height 380)
    (alloy-desktop:show-window window)
    (alloy-desktop:minimize-window window)
    (format t "[08] after minimize-window: window-visible-p = ~S, window-maximized-p = ~S~%"
            (alloy-desktop:window-visible-p window)
            (alloy-desktop:window-maximized-p window))
    (alloy-desktop:restore-window window)
    (format t "[08] after restore-window: window-visible-p = ~S, window-maximized-p = ~S~%"
            (alloy-desktop:window-visible-p window)
            (alloy-desktop:window-maximized-p window))
    (alloy-desktop:maximize-window window)
    (format t "[08] after maximize-window: window-visible-p = ~S, window-maximized-p = ~S~%"
            (alloy-desktop:window-visible-p window)
            (alloy-desktop:window-maximized-p window))
    (finish-output)))
