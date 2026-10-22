(in-package #:alloy-desktop-examples)

;;; 03 - Fixed-size (non-resizable) window.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[03] A 520x300 window titled \"03 - Fixed-size window: try to resize it\" opens.~%")
  (format t "[03] Do: hover the edges and corners and try to drag them; double-click the title bar.~%")
  (format t "[03] Expected: the size stays 520x300.~%")
  (format t "[03] Must NOT happen: a resize cursor on the edges, or the window changing size.~%")
  (format t "[03] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "03 - Fixed-size window: try to resize it"
       :width 520 :height 300
       :resizable-p nil)
    (alloy-desktop:show-window window)))
