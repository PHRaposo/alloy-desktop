(in-package #:alloy-desktop-examples)

;;; 17 - Direct fixed placement of several existing widgets.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[17] One resizable 640x320 window \"17 - Fixed layout\": an instruction line at the top,~%")
  (format t "[17] the buttons MOVE and RESIZE on the left and a TARGET button to their right.~%")
  (format t "[17] Do: press MOVE twice, press RESIZE twice, then resize the window by its edges.~%")
  (format t "[17] Expected: MOVE moves the TARGET button down 60 and back; RESIZE makes the TARGET larger and back; each press prints~%")
  (format t "[17] the TARGET's position and size; on resize every widget keeps its distance to the top-left corner.~%")
  (format t "[17] Must NOT happen: widgets following the window edges, or a press leaving the TARGET where it was.~%")
  (format t "[17] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "17 - Fixed layout"
       :x 120 :y 140 :width 640 :height 320
       :resizable-p t)
    (multiple-value-bind (root target)
        (values (alloy-desktop:window-root-layout window)
                (make-instance 'alloy-desktop:button
                               :text "TARGET"
                               :on-activate (lambda ()
                                              (format t "~&[17] TARGET pressed~%")
                                              (finish-output))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "MOVE / RESIZE the TARGET button; resizing moves nothing.")
                           16 16 440 24)
      (alloy-desktop:place root target 200 60 200 28)
      ;; the TARGET's placed geometry, in the px that element-position / element-size answer
      (multiple-value-bind (x0 y0) (alloy-desktop:element-position target)
        (multiple-value-bind (w0 h0) (alloy-desktop:element-size target)
          (alloy-desktop:add-element
           root
           (make-instance 'alloy-desktop:button
                          :text "MOVE"
                          :on-activate (lambda ()
                                         (multiple-value-bind (x y) (alloy-desktop:element-position target)
                                           (declare (ignore x))
                                           (alloy-desktop:set-element-position target x0 (if (= y y0) (+ y0 60) y0)))
                                         (format t "~&[17] MOVE: TARGET position ~S~%"
                                                 (multiple-value-list (alloy-desktop:element-position target)))
                                         (finish-output)))
           :x 16 :y 60 :w 100 :h 28)
          (alloy-desktop:add-element
           root
           (make-instance 'alloy-desktop:button
                          :text "RESIZE"
                          :on-activate (lambda ()
                                         (multiple-value-bind (w h) (alloy-desktop:element-size target)
                                           (declare (ignore h))
                                           (if (= w w0)
                                               (alloy-desktop:set-element-size target (+ w0 80) (+ h0 20))
                                               (alloy-desktop:set-element-size target w0 h0)))
                                         (format t "~&[17] RESIZE: TARGET size ~S~%"
                                                 (multiple-value-list (alloy-desktop:element-size target)))
                                         (finish-output)))
           :x 16 :y 100 :w 100 :h 28)))
      (alloy-desktop:show-window window))))
