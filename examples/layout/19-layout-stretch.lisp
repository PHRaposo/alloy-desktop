(in-package #:alloy-desktop-examples)

;;; 19 - stretch between two edges during window resize.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[19] One resizable 640x360 window \"19 - Layout stretch\": an instruction line at the top and~%")
  (format t "[19] three buttons, each named after the axis it stretches along.~%")
  (format t "[19] Do: press each button, resize the window by its edges (larger, then smaller), press each button again.~%")
  (format t "[19] Expected: WIDTH grows and shrinks in width keeping its distances to the left and right edges, HEIGHT~%")
  (format t "[19] in height keeping its distances to the top and bottom edges, BOTH in both; the instruction line does not~%")
  (format t "[19] move; each press prints the button's position and size.~%")
  (format t "[19] Must NOT happen: a stretched button keeping its size, or moving away from the edge it is stretched to.~%")
  (format t "[19] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "19 - Layout stretch"
       :x 120 :y 140 :width 640 :height 360
       :resizable-p t)
    (multiple-value-bind (root width height both)
        (values (alloy-desktop:window-root-layout window) nil nil nil)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Resize the window: each button stretches between its edges.")
                           16 16 480 24)
      ;; X with RIGHT (Y with BOTTOM) stretches the button between the two edges; W (H) is then ignored
      (setf width
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "WIDTH (x :right)"
                                                :on-activate (lambda ()
                                                               (format t "~&[19] WIDTH at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position width))
                                                                       (multiple-value-list (alloy-desktop:element-size width)))
                                                               (finish-output)))
                                 16 60 nil 28 :right 16)
            height
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "HEIGHT (y :bottom)"
                                                :on-activate (lambda ()
                                                               (format t "~&[19] HEIGHT at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position height))
                                                                       (multiple-value-list (alloy-desktop:element-size height)))
                                                               (finish-output)))
                                 16 104 180 nil :bottom 16)
            both
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "BOTH (x :right y :bottom)"
                                                :on-activate (lambda ()
                                                               (format t "~&[19] BOTH at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position both))
                                                                       (multiple-value-list (alloy-desktop:element-size both)))
                                                               (finish-output)))
                                 212 104 nil nil :right 16 :bottom 16))
      (alloy-desktop:show-window window))))
