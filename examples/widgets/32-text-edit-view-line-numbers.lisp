(in-package #:alloy-desktop-examples)

;;; 32 - text edit view, line numbers: the 7000-line text of example 30 with a column of line numbers on the left
;;; and the window's vertical scroll bar.  Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[32] One resizable window \"32 - Text edit view - line numbers\": an instruction line, then a framed text~%")
  (format t "[32] pane holding 7000 numbered lines, a grey column of line numbers on its left and a vertical scroll bar~%")
  (format t "[32] inside its right edge. A 16 px margin separates the content from every edge of the window.~%")
  (format t "[32] Do and expect:~%")
  (format t "[32]   the number at the left of each row is that row's line; the column scrolls with the text;~%")
  (format t "[32]   the bar, the arrows, the track and the wheel work as in example 30;~%")
  (format t "[32]   click in the text: the caret blinks (0.5 s on, 0.5 s off) and stays solid while you type; Return adds a~%")
  (format t "[32]   line and every number below it goes up by one.~%")
  (format t "[32] Must NOT happen: text under the line numbers or under the bar; a number out of step with its row.~%")
  (format t "[32] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "32 - Text edit view - line numbers" :x 160 :y 160 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :font (alloy-desktop:font-entry-font
                                      (alloy-desktop:role-font-entry window :dialog-default))
                               :gutter-p t
                               :scrollbars :v
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{Line ~D of 7000 of an editable text.~^~%~}"
                                                (loop for i from 1 to 7000 collect i))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Line numbers on the left; scroll with the bar or the wheel.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
