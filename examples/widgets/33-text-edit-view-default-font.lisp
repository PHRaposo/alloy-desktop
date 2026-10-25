(in-package #:alloy-desktop-examples)

;;; 33 - text edit view, default font: example 30's pane given no :font, which draws in its window's dialog face.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[33] One resizable window \"33 - Text edit view - default font\": an instruction line, then a framed white~%")
  (format t "[33] text pane holding 7000 numbered lines, with a vertical scroll bar inside its right edge. The pane is made~%")
  (format t "[33] without a font. A 16 px margin separates the content from every edge of the window.~%")
  (format t "[33] Do and expect:~%")
  (format t "[33]   the text is drawn in the same face and size as example 30 and as the instruction line above it;~%")
  (format t "[33]   the bar, the wheel, clicking and typing work as in example 30.~%")
  (format t "[33] Must NOT happen: an error about a missing font; the window not opening; a face different from example 30.~%")
  (format t "[33] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "33 - Text edit view - default font" :x 160 :y 160 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :scrollbars :v
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{Line ~D of 7000 of an editable text.~^~%~}"
                                                (loop for i from 1 to 7000 collect i))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "A text pane made without a font draws in the window's face.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
