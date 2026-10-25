(in-package #:alloy-desktop-examples)

;;; 35 - text edit view, editor family: an editable text pane under the editor's own gesture family (:editor),
;;; which scrolls by whole rows, with the window's vertical scroll bar.  Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[35] One resizable window \"35 - Text edit view - editor family\": an instruction line, then a framed~%")
  (format t "[35] white text pane holding 7000 numbered lines, with a vertical scroll bar inside its right edge.~%")
  (format t "[35] A 16 px margin separates the content from every edge of the window.~%")
  (format t "[35] Do and expect:~%")
  (format t "[35]   the top row on screen is always whole: the text moves by whole rows, never by part of one;~%")
  (format t "[35]   drag the handle to the bottom: the last line stands at the top of the pane, the rest of the pane~%")
  (format t "[35]   empty below it;~%")
  (format t "[35]   roll the wheel or press the arrows: the text moves by whole rows and the handle follows;~%")
  (format t "[35]   click in the text and type: the text does not jump; the keyboard stays in the text while you use the bar.~%")
  (format t "[35] Must NOT happen: a row cut at the top of the pane; text under the bar; a horizontal bar.~%")
  (format t "[35] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "35 - Text edit view - editor family" :x 200 :y 200 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :gesture-policy :editor
                               :scrollbars :v
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{Line ~D of 7000 of an editable text.~^~%~}"
                                                (loop for i from 1 to 7000 collect i))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "The editor's family scrolls by whole rows; the bar follows it.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
