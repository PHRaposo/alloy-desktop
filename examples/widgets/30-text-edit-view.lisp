(in-package #:alloy-desktop-examples)

;;; 30 - text edit view: an editable text pane over 7000 numbered lines, with the window's vertical scroll bar.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[30] One resizable window \"30 - Text edit view\": an instruction line, then a framed white text pane~%")
  (format t "[30] holding 7000 numbered lines, with a vertical scroll bar inside its right edge. A 16 px margin~%")
  (format t "[30] separates the content from every edge of the window.~%")
  (format t "[30] Do and expect:~%")
  (format t "[30]   rest: the bar is a light grey track with a thin grey handle near its top, no arrows;~%")
  (format t "[30]   hover the bar: the handle widens and the two arrows fade in; leave it: it narrows again;~%")
  (format t "[30]   press the bottom arrow: the text moves one step (20 px) up; hold it: after a short pause it keeps moving;~%")
  (format t "[30]   press the track below the handle: the text moves one page; nothing is dragged;~%")
  (format t "[30]   drag the handle: the point you pressed stays under the pointer and the text follows;~%")
  (format t "[30]   roll the wheel over the text: 40 px a notch, and the handle follows;~%")
  (format t "[30]   click in the text and type, or press Tab: the text does not jump; the keyboard stays in the text~%")
  (format t "[30]   while you use the bar; resize the window: the pane and its bar follow the window's edges.~%")
  (format t "[30] Must NOT happen: text drawn under the bar; the bar taking the keyboard; a second (horizontal) bar.~%")
  (format t "[30] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window screen :title "30 - Text edit view" :x 120 :y 120 :width 632 :height 436)
    ;; make-window takes px and PLACE logical units: 16 + 600 + 16 by 16 + 24 + 8 + 372 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 632)) (round (* scale 436))))
    (let ((root (alloy-desktop:window-root-layout window))
          ;; the window's own dialog face: a text pane is handed the face it draws in
          (pane (make-instance 'alloy-desktop:text-edit-view
                               :font (alloy-desktop:font-entry-font
                                      (alloy-desktop:role-font-entry window :dialog-default))
                               :scrollbars :v
                               :frame-color alloy-desktop:*tab-border*
                               :buffer (alloy-editor:make-buffer
                                        (format nil "~{Line ~D of 7000 of an editable text.~^~%~}"
                                                (loop for i from 1 to 7000 collect i))))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Scroll with the bar or the wheel; click in the text to type.")
                           16 16 600 24)
      (alloy-desktop:place root pane 16 48 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
