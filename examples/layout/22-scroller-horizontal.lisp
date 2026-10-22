(in-package #:alloy-desktop-examples)

;;; 22 - horizontal scroller: the field is wider than the scroller, a horizontal bar scrolls it.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[22] One fixed-size window \"22 - Horizontal scroller\" (no resize): an instruction line, a WHERE? button and~%")
  (format t "[22] a 600x200 white scroller framed by a thin grey line, with a horizontal bar over a 1600 px wide field holding~%")
  (format t "[22] twelve buttons COL 1 ... COL 12; the same 16 px margin separates the content from every edge of the window.~%")
  (format t "[22] Do: drag the thumb of the horizontal bar right and left, press WHERE? at each stop, press a few COL buttons;~%")
  (format t "[22] click the bar left and right of the thumb.~%")
  (format t "[22] Expected: the thumb stays under the pointer at the point it was grabbed for the whole drag; the columns move~%")
  (format t "[22] with it; WHERE? prints scroll-x changing (maxima (mx . 0)); a click beside the thumb moves one page toward~%")
  (format t "[22] the pointer; each COL button prints \"[22] COL n pressed\" for the column actually under the pointer.~%")
  (format t "[22] Must NOT happen: the thumb sliding away from the pointer; a vertical bar; columns drawn outside the frame;~%")
  (format t "[22] the window resizing from its edges.~%")
  (format t "[22] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "22 - Horizontal scroller"
       :x 120 :y 140 :width 632 :height 304
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 88 + 200 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 304))))
    (let ((root (alloy-desktop:window-root-layout window))
          ;; a bar-less scroller draws the frame and the white face; the scrolling one sits 1 unit inside it
          (frame (make-instance 'alloy-desktop:scroller
                                :background (alloy-desktop:rgb 1 1 1)
                                :border alloy-desktop:*tab-border* :border-width 1))
          (scroller (make-instance 'alloy-desktop:scroller :scrollbars :h :field-width 1600)))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Drag the horizontal bar; press WHERE? and the COL buttons.")
                           16 16 600 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[22] scroll at ~S, maxima ~S, viewport ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (alloy-desktop:scroll-maxima scroller)
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller)))
                                                         (finish-output)))
                           16 48 120 28)
      (alloy-desktop:place root frame 16 88 600 200 :right 16 :bottom 16)
      (alloy-desktop:place frame scroller 1 1 nil nil :right 1 :bottom 1)
      ;; twelve columns, 130 px apart; the last one ends at the field's 1600 px width
      (dotimes (i 12)
        (alloy-desktop:place scroller
                             (make-instance 'alloy-desktop:button
                                            :text (format nil "COL ~D" (1+ i))
                                            :on-activate (let ((n (1+ i)))
                                                           (lambda ()
                                                             (format t "~&[22] COL ~D pressed~%" n)
                                                             (finish-output))))
                             (+ 50 (* 130 i)) 16 120 28))
      (alloy-desktop:show-window window))))
