(in-package #:alloy-desktop-examples)

;;; 02 - Basic resizable window.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[02] A 640x360 resizable window opens.~%")
  (format t "[02] Do: drag any edge or corner; maximize and restore from the title bar.~%")
  (format t "[02] Expected: the window follows the drag, repaints without black strips, and keeps its title.~%")
  (format t "[02] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "02 - Resizable window: drag an edge or a corner"
       :width 640 :height 360
       :resizable-p t)
    (alloy-desktop:show-window window)))
