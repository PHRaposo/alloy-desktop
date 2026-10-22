(in-package #:alloy-desktop-examples)

;;; 21 - vertical scroller: the field is taller than the scroller, a vertical bar scrolls it.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[21] One fixed-size window \"21 - Vertical scroller\" (no resize): an instruction line, a WHERE? button and~%")
  (format t "[21] a 400x250 white scroller framed by a thin grey line, with a vertical bar over a 1200 px tall field holding~%")
  (format t "[21] twelve buttons ROW 1 ... ROW 12; the same 16 px margin separates the content from every edge of the window.~%")
  (format t "[21] Do: drag the thumb of the vertical bar down and up, press WHERE? at each stop, press a few ROW buttons;~%")
  (format t "[21] click the bar above and below the thumb.~%")
  (format t "[21] Expected: the thumb stays under the pointer at the point it was grabbed for the whole drag; the rows move with~%")
  (format t "[21] it; WHERE? prints scroll-y changing (maxima (0 . my)); a click beside the thumb moves one page toward the~%")
  (format t "[21] pointer; each ROW button prints \"[21] ROW n pressed\" for the row actually under the pointer.~%")
  (format t "[21] Must NOT happen: the thumb sliding away from the pointer; a horizontal bar; rows drawn outside the frame;~%")
  (format t "[21] the window resizing from its edges.~%")
  (format t "[21] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "21 - Vertical scroller"
       :x 120 :y 140 :width 432 :height 354
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 88 + 250 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 354))))
    (let ((root (alloy-desktop:window-root-layout window))
          ;; a bar-less scroller draws the frame and the white face; the scrolling one sits 1 unit inside it
          (frame (make-instance 'alloy-desktop:scroller
                                :background (alloy-desktop:rgb 1 1 1)
                                :border alloy-desktop:*tab-border* :border-width 1))
          (scroller (make-instance 'alloy-desktop:scroller :scrollbars :v :field-height 1200)))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Drag the vertical bar; press WHERE? and the ROW buttons.")
                           16 16 400 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[21] scroll at ~S, maxima ~S, viewport ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (alloy-desktop:scroll-maxima scroller)
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller)))
                                                         (finish-output)))
                           16 48 120 28)
      (alloy-desktop:place root frame 16 88 400 250 :right 16 :bottom 16)
      (alloy-desktop:place frame scroller 1 1 nil nil :right 1 :bottom 1)
      ;; twelve rows, 100 px apart; the last one ends at the field's 1200 px height
      (dotimes (i 12)
        (alloy-desktop:place scroller
                             (make-instance 'alloy-desktop:button
                                            :text (format nil "ROW ~D" (1+ i))
                                            :on-activate (let ((n (1+ i)))
                                                           (lambda ()
                                                             (format t "~&[21] ROW ~D pressed~%" n)
                                                             (finish-output))))
                             16 (+ 72 (* 100 i)) 160 28))
      (alloy-desktop:show-window window))))
