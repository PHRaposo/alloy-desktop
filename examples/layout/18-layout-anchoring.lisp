(in-package #:alloy-desktop-examples)

;;; 18 - :right / :bottom anchoring during window resize.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[18] One resizable 640x360 window \"18 - Layout anchoring\": an instruction line at the top and~%")
  (format t "[18] four buttons, each named after the corner it is anchored to.~%")
  (format t "[18] Do: press each button, resize the window by its edges (larger, then smaller), press each button again.~%")
  (format t "[18] Expected: TOP-RIGHT keeps its distance to the right edge, BOTTOM-LEFT to the bottom edge, BOTTOM-RIGHT~%")
  (format t "[18] to both; TOP-LEFT and the instruction line do not move; each press prints the button's position and size.~%")
  (format t "[18] Must NOT happen: an anchored button keeping its distance to the top-left corner; a button changing size.~%")
  (format t "[18] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "18 - Layout anchoring"
       :x 120 :y 140 :width 640 :height 360
       :resizable-p t)
    (multiple-value-bind (root top-left top-right bottom-left bottom-right)
        (values (alloy-desktop:window-root-layout window) nil nil nil nil)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Resize the window: each anchored button follows its edges.")
                           16 16 480 24)
      ;; each button is placed with fixed W H; X (Y) or RIGHT (BOTTOM) picks the edge it keeps its distance to
      (setf top-left
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "TOP-LEFT (x y)"
                                                :on-activate (lambda ()
                                                               (format t "~&[18] TOP-LEFT at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position top-left))
                                                                       (multiple-value-list (alloy-desktop:element-size top-left)))
                                                               (finish-output)))
                                 16 60 180 28)
            top-right
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "TOP-RIGHT (:right y)"
                                                :on-activate (lambda ()
                                                               (format t "~&[18] TOP-RIGHT at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position top-right))
                                                                       (multiple-value-list (alloy-desktop:element-size top-right)))
                                                               (finish-output)))
                                 nil 60 180 28 :right 16)
            bottom-left
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "BOTTOM-LEFT (x :bottom)"
                                                :on-activate (lambda ()
                                                               (format t "~&[18] BOTTOM-LEFT at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position bottom-left))
                                                                       (multiple-value-list (alloy-desktop:element-size bottom-left)))
                                                               (finish-output)))
                                 16 nil 180 28 :bottom 16)
            bottom-right
            (alloy-desktop:place root
                                 (make-instance 'alloy-desktop:button
                                                :text "BOTTOM-RIGHT (:right :bottom)"
                                                :on-activate (lambda ()
                                                               (format t "~&[18] BOTTOM-RIGHT at ~S size ~S~%"
                                                                       (multiple-value-list (alloy-desktop:element-position bottom-right))
                                                                       (multiple-value-list (alloy-desktop:element-size bottom-right)))
                                                               (finish-output)))
                                 nil nil 220 28 :right 16 :bottom 16))
      (alloy-desktop:show-window window))))
