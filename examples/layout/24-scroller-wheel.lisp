(in-package #:alloy-desktop-examples)

;;; 24 - the mouse wheel scrolls a scroller by *wheel-step* px per notch.
;;; Public alloy-desktop API only.

(defclass wheel-step-window (alloy-desktop:window)
  ((saved-step :initform alloy-desktop:*wheel-step* :reader saved-step))
  (:documentation "A window that puts *wheel-step* back as it found it once it closes."))

(defmethod alloy-desktop:window-closing ((window wheel-step-window))
  (setf alloy-desktop:*wheel-step* (saved-step window))
  (when (next-method-p) (call-next-method)))

(define-example (screen)
  (format t "~&[24] One fixed-size window \"24 - Scroller wheel\" (no resize): an instruction line, WHERE? and~%")
  (format t "[24] STEP 40 / STEP 120 buttons, and a 600x250 white scroller framed by a thin grey line over a 1600x1200 field~%")
  (format t "[24] holding an 8x8 grid of buttons; the same 16 px margin separates the content from every edge of the window.~%")
  (format t "[24] Do: with the pointer over the scroller, turn the wheel one notch at a time and press WHERE? after each;~%")
  (format t "[24] use the horizontal wheel / trackpad; press STEP 40 / STEP 120 and repeat; turn the wheel over WHERE?.~%")
  (format t "[24] Expected: one vertical notch moves scroll-y by the printed step (~D now), the horizontal wheel moves scroll-x;~%"
          alloy-desktop:*wheel-step*)
  (format t "[24] STEP 40 / STEP 120 prints the new step, alternating 40 and 120; grid buttons print \"[24] ROW r COL c pressed\".~%")
  (format t "[24] Must NOT happen: the wheel over the WHERE? button (outside the scroller) scrolling the scroller;~%")
  (format t "[24] a notch moving by anything other than the current step (except when clamped at an end); the window resizing.~%")
  (format t "[24] Close the window from its title bar to end; the step goes back to its value before the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :class 'wheel-step-window
       :title "24 - Scroller wheel"
       :x 120 :y 140 :width 632 :height 354
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 88 + 250 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 354))))
    (let ((root (alloy-desktop:window-root-layout window))
          ;; a bar-less scroller draws the frame and the white face; the scrolling one sits 1 unit inside it
          (frame (make-instance 'alloy-desktop:scroller
                                :background (alloy-desktop:rgb 1 1 1)
                                :border alloy-desktop:*tab-border* :border-width 1))
          (scroller (make-instance 'alloy-desktop:scroller :scrollbars t :field-width 1600 :field-height 1200)))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Turn the wheel over the scroller; STEP switches *wheel-step*.")
                           16 16 600 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[24] scroll at ~S, maxima ~S, viewport ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (alloy-desktop:scroll-maxima scroller)
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller)))
                                                         (finish-output)))
                           16 48 120 28)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "STEP 40 / STEP 120"
                                          :on-activate (lambda ()
                                                         (setf alloy-desktop:*wheel-step*
                                                               (if (= alloy-desktop:*wheel-step* 40) 120 40))
                                                         (format t "~&[24] *wheel-step* is now ~D px per notch~%"
                                                                 alloy-desktop:*wheel-step*)
                                                         (finish-output)))
                           150 48 180 28)
      (alloy-desktop:place root frame 16 88 600 250 :right 16 :bottom 16)
      (alloy-desktop:place frame scroller 1 1 nil nil :right 1 :bottom 1)
      ;; 8x8 grid, 200 px by 150 px apart; the last cell ends at the field's 1600x1200 corner
      (dotimes (r 8)
        (dotimes (c 8)
          (alloy-desktop:place scroller
                               (make-instance 'alloy-desktop:button
                                              :text (format nil "R~D C~D" (1+ r) (1+ c))
                                              :on-activate (let ((row (1+ r)) (col (1+ c)))
                                                             (lambda ()
                                                               (format t "~&[24] ROW ~D COL ~D pressed~%" row col)
                                                               (finish-output))))
                               (+ 80 (* 200 c)) (+ 122 (* 150 r)) 120 28)))
      (alloy-desktop:show-window window))))
