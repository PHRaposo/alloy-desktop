(in-package #:alloy-desktop-examples)

;;; 34 - text edit view, horizontal bar: an editable text pane whose lines are not wrapped, some far wider than
;;; the pane, with the window's vertical and horizontal scroll bars.  Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[34] One resizable window \"34 - Text edit view - horizontal bar\": an instruction line, then a framed~%")
  (format t "[34] white text pane holding 3000 numbered lines, every 100th one far wider than the pane, with a vertical~%")
  (format t "[34] bar inside its right edge and a horizontal bar inside its bottom edge. A 16 px margin separates the~%")
  (format t "[34] content from every edge of the window.~%")
  (format t "[34] Do and expect:~%")
  (format t "[34]   lines are never wrapped; the horizontal bar's handle is as long as the pane is wide against the widest~%")
  (format t "[34]   line of the whole text, even before you scroll down to it;~%")
  (format t "[34]   drag the horizontal handle or press its arrows: the text moves left and right, and at the right end~%")
  (format t "[34]   the end of the widest line stands just inside the pane;~%")
  (format t "[34]   click in a wide line, press End: the text follows the caret and the handle follows the text;~%")
  (format t "[34]   select a whole wide line and delete it: once every wide line is gone the handle grows and then goes~%")
  (format t "[34]   with the bar, within a second, with no pause in typing;~%")
  (format t "[34]   the vertical bar and the wheel work as in example 30.~%")
  (format t "[34] Must NOT happen: text under either bar; a wrapped line; a pause when typing or deleting.~%")
  (format t "[34] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "34 - Text edit view - horizontal bar" :x 180 :y 180 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :scrollbars t
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{~A~^~%~}"
                                                (loop for i from 1 to 3000
                                                      collect (if (zerop (mod i 100))
                                                                  (format nil "Line ~D of 3000, a wide one: ~{~A~^ ~}" i
                                                                          (loop for word from 1 to 40
                                                                                collect (format nil "word~D" word)))
                                                                  (format nil "Line ~D of 3000." i))))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Lines are not wrapped; scroll across with the horizontal bar.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
