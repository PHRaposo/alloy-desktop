(in-package #:alloy-desktop-examples)

;;; 23 - two-axis scroller: two bars, the corner square, and set-scroll clamped to the field.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[23] One fixed-size window \"23 - Two-axis scroller\" (no resize): an instruction line, WHERE?, GO TO END and~%")
  (format t "[23] GO HOME buttons, and a 600x250 white scroller framed by a thin grey line over a 1600x1200 field holding an~%")
  (format t "[23] 8x8 grid of buttons R1 C1 ... R8 C8; its two bars meet in a corner square inside the frame; the same 16 px~%")
  (format t "[23] margin separates the content from every edge of the window.~%")
  (format t "[23] Do: drag both bars, press WHERE?; press GO TO END, then WHERE?; press GO HOME, then WHERE?; press a few grid~%")
  (format t "[23] buttons; click each bar beside its thumb.~%")
  (format t "[23] Expected: each thumb stays under the pointer at the point it was grabbed for the whole drag; two bars~%")
  (format t "[23] meeting in a corner square (WHERE? prints corner visible T); GO TO END prints the CLAMPED position, equal to~%")
  (format t "[23] the maxima, and shows R8 C8; GO HOME prints (0 0) and shows R1 C1; a click beside a thumb moves one page toward~%")
  (format t "[23] the pointer; each grid button prints \"[23] ROW r COL c pressed\" for the button actually under the pointer.~%")
  (format t "[23] Must NOT happen: a thumb sliding away from the pointer; GO TO END printing a position above the maxima;~%")
  (format t "[23] a missing corner square; grid buttons drawn outside the frame or over the bars; the window resizing.~%")
  (format t "[23] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "23 - Two-axis scroller"
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
                                          :text "Drag both bars; GO TO END / GO HOME call set-scroll; WHERE? prints the state.")
                           16 16 600 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[23] scroll at ~S, maxima ~S, viewport ~S, corner visible ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (alloy-desktop:scroll-maxima scroller)
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller))
                                                                 (alloy-desktop:scroll-corner-visible-p scroller))
                                                         (finish-output)))
                           16 48 120 28)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "GO TO END"
                                          :on-activate (lambda ()
                                                         (format t "~&[23] set-scroll (99999 99999) -> clamped ~S, maxima ~S~%"
                                                                 (multiple-value-list
                                                                  (alloy-desktop:set-scroll scroller 99999 99999))
                                                                 (alloy-desktop:scroll-maxima scroller))
                                                         (finish-output)))
                           150 48 130 28)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "GO HOME"
                                          :on-activate (lambda ()
                                                         (format t "~&[23] set-scroll (0 0) -> ~S~%"
                                                                 (multiple-value-list
                                                                  (alloy-desktop:set-scroll scroller 0 0)))
                                                         (finish-output)))
                           294 48 130 28)
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
                                                               (format t "~&[23] ROW ~D COL ~D pressed~%" row col)
                                                               (finish-output))))
                               (+ 80 (* 200 c)) (+ 122 (* 150 r)) 120 28)))
      (alloy-desktop:show-window window))))
