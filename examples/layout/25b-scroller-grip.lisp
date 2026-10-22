(in-package #:alloy-desktop-examples)

;;; 25b - a scroller flush with the window's right and bottom edges, like a document window: where its two bars
;;; meet is the window's own corner, so the corner square carries the six dots of the size grip.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[25b] One resizable 600x400 window \"25b - Corner grip\": an instruction line, a WHERE? button and~%")
  (format t "[25b] a scroller from y 88 to the window's left, right and bottom edges (no margin, no border), over a~%")
  (format t "[25b] 1200x900 field holding a 4x4 grid of buttons.~%")
  (format t "[25b] Do: look at the bottom-right corner; press WHERE?; drag the window's right and bottom edges, maximize,~%")
  (format t "[25b] restore; scroll to the end and shrink the window, press WHERE?.~%")
  (format t "[25b] Expected: from the first frame both bars show and the grey corner square where they meet carries six~%")
  (format t "[25b] grip dots (3-2-1 staircase) in the window's bottom-right corner; on every resize the bars, the corner and~%")
  (format t "[25b] the grip follow in the same frame; WHERE? prints scroll, field and viewport, the scroll never beyond~%")
  (format t "[25b] field minus viewport; grid buttons print \"[25b] ROW r COL c pressed\".~%")
  (format t "[25b] Must NOT happen: the corner square without the dots; the dots left behind at the old corner after a~%")
  (format t "[25b] resize; a gap between the bars and the window's edges; a bar cut by the window's edge.~%")
  (format t "[25b] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "25b - Corner grip"
       :x 120 :y 140 :width 600 :height 400
       :resizable-p t)
    ;; make-window takes px and PLACE logical units: 600 x 400 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 600)) (round (* scale 400))))
    (let ((root (alloy-desktop:window-root-layout window))
          (scroller (make-instance 'alloy-desktop:scroller :scrollbars t :field-width 1200 :field-height 900)))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Resize the window: the grip sits in the corner where the bars meet.")
                           16 16 560 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[25b] scroll at ~S, field ~S, viewport ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (multiple-value-list (alloy-desktop:field-size scroller))
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller)))
                                                         (finish-output)))
                           16 48 120 28)
      ;; RIGHT 0 and BOTTOM 0: the scroller's corner is the window's corner, as in a document window
      (alloy-desktop:place root scroller 0 88 nil nil :right 0 :bottom 0)
      ;; 4x4 grid, 320 px by 250 px apart; the last cell ends at the field's 1200x900 corner
      (dotimes (r 4)
        (dotimes (c 4)
          (alloy-desktop:place scroller
                               (make-instance 'alloy-desktop:button
                                              :text (format nil "R~D C~D" (1+ r) (1+ c))
                                              :on-activate (let ((row (1+ r)) (col (1+ c)))
                                                             (lambda ()
                                                               (format t "~&[25b] ROW ~D COL ~D pressed~%" row col)
                                                               (finish-output))))
                               (+ 120 (* 320 c)) (+ 122 (* 250 r)) 120 28)))
      (alloy-desktop:show-window window))))
