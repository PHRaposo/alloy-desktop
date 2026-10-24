(in-package #:alloy-desktop-examples)

;;; 31 - text edit view, wrap: an editable text pane whose long lines wrap into several rows, with the window's
;;; vertical scroll bar.  Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[31] One resizable window \"31 - Text edit view - wrap\": an instruction line, then a framed white text~%")
  (format t "[31] pane holding 2000 long numbered lines, each wrapped over several rows, with a vertical scroll bar inside~%")
  (format t "[31] its right edge. A 16 px margin separates the content from every edge of the window.~%")
  (format t "[31] Do and expect:~%")
  (format t "[31]   every line breaks at a word and goes on in the next row; no row reaches under the bar;~%")
  (format t "[31]   no horizontal bar; the bar, the arrows, the track and the wheel work as in example 30;~%")
  (format t "[31]   click in the text: the caret blinks (0.5 s on, 0.5 s off) and stays solid while you type;~%")
  (format t "[31]   make the window narrower or wider: the lines wrap again at once, the first line on screen stays where~%")
  (format t "[31]   it was, and the handle settles over the next second or so while the rows of the whole text are counted.~%")
  (format t "[31] Must NOT happen: text under the bar; a line cut at the right edge instead of wrapped; the text jumping~%")
  (format t "[31] while the window is resized; a resize that freezes the window.~%")
  (format t "[31] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "31 - Text edit view - wrap" :x 140 :y 140 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :font (alloy-desktop:font-entry-font
                                      (alloy-desktop:role-font-entry window :dialog-default))
                               :wrap-p t
                               :scrollbars :v
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{~A~^~%~}"
                                                (loop for i from 1 to 2000
                                                      collect (format nil "Line ~D of 2000: this line is long enough to wrap over several rows of the pane, and every row after the first goes on where the row before it stopped, at a word, as the width of the window allows." i)))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Long lines wrap; resize the window to wrap them again.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
