(in-package #:alloy-desktop-examples)

;;; 04 - Decorated and undecorated windows.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[04] Two 420x240 windows open side by side: on the left \"04 - Decorated\", on the right \"04 - Undecorated\".~%")
  (format t "[04] Do: compare the two frames.~%")
  (format t "[04] Expected: the left window has a title bar and system border; the right one is a bare rectangle with neither,~%")
  (format t "[04] with a CLOSE button at its centre.~%")
  (format t "[04] Must NOT happen: a title bar or border on the right window.~%")
  (format t "[04] Close the decorated window from its title bar; close the undecorated one with its CLOSE button.~%")
  (finish-output)
  (multiple-value-bind (decorated)
      (alloy-desktop:make-window
       screen
       :title "04 - Decorated"
       :x 120 :y 140 :width 420 :height 240
       :resizable-p nil
       :decorated-p t)
    (multiple-value-bind (undecorated)
        (alloy-desktop:make-window
         screen
         :title "04 - Undecorated"
         :x 650 :y 140 :width 420 :height 240
         :resizable-p nil
         :decorated-p nil)
      (alloy-desktop:add-element (alloy-desktop:window-root-layout undecorated)
                                 (make-instance 'alloy-desktop:button
                                                :text "CLOSE"
                                                :on-activate (lambda () (alloy-desktop:close-window undecorated)))
                                 :x 160 :y 106 :w 100 :h 28)
      (alloy-desktop:show-window decorated)
      (alloy-desktop:show-window undecorated))))
