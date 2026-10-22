(in-package #:alloy-desktop-examples)

;;; 12 - Show a secondary window without taking focus.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[12] \"12 - Primary window\" (620x380) opens and takes the focus; a quarter second later~%")
  (format t "[12] \"12 - Show without focus\" (420x220) appears through show-window-without-focus.~%")
  (format t "[12] Do: look at which title bar is active once both are on screen.~%")
  (format t "[12] Expected: the primary keeps the active title bar; the secondary one is shown but inactive.~%")
  (format t "[12] The console prints window-focused-p of both windows.~%")
  (format t "[12] Must NOT happen: the secondary window taking the focus when it appears.~%")
  (format t "[12] Close both windows to end the example.~%")
  (finish-output)
  (multiple-value-bind (primary)
      (alloy-desktop:make-window
       screen
       :title "12 - Primary window"
       :x 220 :y 180 :width 620 :height 380
       :resizable-p nil)
    (multiple-value-bind (satellite)
        (alloy-desktop:make-window
         screen
         :title "12 - Show without focus"
         :x 650 :y 350 :width 420 :height 220
         :resizable-p nil)
      (alloy-desktop:show-window primary)
      ;; the timer fires on its own thread; the window is shown on the UI thread
      (alloy-desktop:start-timer
       (alloy-desktop:default-timer-service) 0.25
       (lambda ()
         (alloy-desktop:post-to-ui-thread
          (lambda ()
            (when (alloy-desktop:window-alive-p satellite)
              (alloy-desktop:show-window-without-focus satellite)
              (format t "[12] after show-window-without-focus: window-focused-p primary = ~S, satellite = ~S~%"
                      (alloy-desktop:window-focused-p primary)
                      (alloy-desktop:window-focused-p satellite))
              (finish-output)))))))))
