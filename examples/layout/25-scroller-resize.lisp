(in-package #:alloy-desktop-examples)

;;; 25 - a scroller stretched with the window: bars appear and disappear axis by axis, the corner square follows.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[25] One resizable 640x360 window \"25 - Scroller resize\": an instruction line, a WHERE? button and~%")
  (format t "[25] a white scroller framed by a thin grey line, stretched with the window at a 16 px margin from its right and~%")
  (format t "[25] bottom edges, over a 900x600 field holding a 4x4 grid of buttons.~%")
  (format t "[25] Do: press WHERE?; widen the window until the scroller is wider than the field, press WHERE?; make it taller~%")
  (format t "[25] than the field, press WHERE?; shrink it back, press WHERE?; scroll a little and resize again.~%")
  (format t "[25] Expected: the frame keeps its 16 px margin from the window's right and bottom edges at every size; the~%")
  (format t "[25] horizontal bar disappears once the scroller is wider than the field and the vertical one once it is taller,~%")
  (format t "[25] each coming back on shrinking; the corner square shows inside the frame's bottom-right corner while both bars~%")
  (format t "[25] show and follows it in the same frame as the resize; no size grip is drawn there, since the scroller does not~%")
  (format t "[25] reach the window's corner (WHERE? prints grip visible NIL); grid buttons print \"[25] ROW r COL c pressed\".~%")
  (format t "[25] Must NOT happen: a grid button changing position relative to the scroller's top-left corner on resize;~%")
  (format t "[25] the corner square left behind at the old corner until a bar is touched; a bar visible while its axis does~%")
  (format t "[25] not overflow; the frame or a bar cut by the window's edge.~%")
  (format t "[25] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "25 - Scroller resize"
       :x 120 :y 140 :width 640 :height 360
       :resizable-p t)
    ;; make-window takes px and PLACE logical units: 640 x 360 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 640)) (round (* scale 360))))
    (let ((root (alloy-desktop:window-root-layout window))
          ;; a bar-less scroller draws the frame and the white face; the scrolling one sits 1 unit inside it
          (frame (make-instance 'alloy-desktop:scroller
                                :background (alloy-desktop:rgb 1 1 1)
                                :border alloy-desktop:*tab-border* :border-width 1))
          (scroller (make-instance 'alloy-desktop:scroller :scrollbars t :field-width 900 :field-height 600)))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Resize the window: the bars follow the overflow, the corner the frame.")
                           16 16 600 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHERE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[25] scroll at ~S, maxima ~S, viewport ~S, size ~S, bars ~S, grip visible ~S~%"
                                                                 (list (alloy-desktop:scroll-x scroller)
                                                                       (alloy-desktop:scroll-y scroller))
                                                                 (alloy-desktop:scroll-maxima scroller)
                                                                 (multiple-value-list (alloy-desktop:scroll-viewport scroller))
                                                                 (multiple-value-list (alloy-desktop:element-size scroller))
                                                                 (multiple-value-list (alloy-desktop:scrollbar-axes scroller))
                                                                 (alloy-desktop:scroll-grip-visible-p scroller))
                                                         (finish-output)))
                           16 48 120 28)
      ;; X with RIGHT and Y with BOTTOM stretch the frame with the window, 16 units from each edge
      (alloy-desktop:place root frame 16 88 nil nil :right 16 :bottom 16)
      (alloy-desktop:place frame scroller 1 1 nil nil :right 1 :bottom 1)
      ;; 4x4 grid, 220 px by 150 px apart; the last cell ends at the field's 900x600 corner
      (dotimes (r 4)
        (dotimes (c 4)
          (alloy-desktop:place scroller
                               (make-instance 'alloy-desktop:button
                                              :text (format nil "R~D C~D" (1+ r) (1+ c))
                                              :on-activate (let ((row (1+ r)) (col (1+ c)))
                                                             (lambda ()
                                                               (format t "~&[25] ROW ~D COL ~D pressed~%" row col)
                                                               (finish-output))))
                               (+ 120 (* 220 c)) (+ 122 (* 150 r)) 120 28)))
      (alloy-desktop:show-window window))))
