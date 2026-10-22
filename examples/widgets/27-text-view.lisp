(in-package #:alloy-desktop-examples)

;;; 27 - text view: read-only multi-line text, scrolled by a scroller when it is taller than its frame, and a text
;;; view whose text a button replaces (widget-text).
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[27] One fixed-size window \"27 - Text view\" (no resize), top to bottom: an instruction line; a white~%")
  (format t "[27] frame with a vertical bar showing a long read-only text of 24 numbered lines; a one-line text view on~%")
  (format t "[27] white; a NEXT button. The same 16 px margin separates the content from every edge.~%")
  (format t "[27] Do: drag the bar or roll the wheel over the long text; try to type into either text; press NEXT three times.~%")
  (format t "[27] Expected: the 24 lines scroll inside the frame; typing changes nothing (the texts are read-only); each NEXT~%")
  (format t "[27] replaces the one-line text (1 of 3, 2 of 3, 3 of 3, then 1 of 3 again) and prints the new text here.~%")
  (format t "[27] Must NOT happen: lines drawn outside the frame; a caret in either text; text cut at the bottom of a widget;~%")
  (format t "[27] the window resizing from its edges.~%")
  (format t "[27] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "27 - Text view"
       :x 120 :y 140 :width 432 :height 340
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 308 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 340))))
    (let* ((root (alloy-desktop:window-root-layout window))
           ;; a bar-less scroller draws the frame and the white face; the scrolling one sits 1 unit inside it
           (frame (make-instance 'alloy-desktop:scroller
                                 :background (alloy-desktop:rgb 1 1 1)
                                 :border alloy-desktop:*tab-border* :border-width 1))
           (scroller (make-instance 'alloy-desktop:scroller :scrollbars :v :field-height 312))
           (texts '("Text 1 of 3: a text view shows text it never lets the user edit."
                    "Text 2 of 3: its text is replaced by the program, never by typing."
                    "Text 3 of 3: the next press shows the first text again."))
           (shown 0)
           (short (make-instance 'alloy-desktop:text-view
                                 :text (first texts)
                                 :background (alloy-desktop:rgb 1 1 1))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Scroll the long text; press NEXT to replace the short one.")
                           16 16 400 24)
      (alloy-desktop:place root frame 16 48 400 200)
      (alloy-desktop:place frame scroller 1 1 nil nil :right 1 :bottom 1)
      (alloy-desktop:place scroller
                           (make-instance 'alloy-desktop:text-view
                                          :text (format nil "~{Line ~D of 24 of a read-only text view.~^~%~}"
                                                        (loop for i from 1 to 24 collect i)))
                           0 0 380 312)
      (alloy-desktop:place root short 16 264 400 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "NEXT"
                                          :on-activate (lambda ()
                                                         (setf shown (mod (1+ shown) 3))
                                                         (setf (alloy-desktop:widget-text short) (nth shown texts))
                                                         (format t "~&[27] NEXT: ~A~%" (alloy-desktop:widget-text short))
                                                         (finish-output)))
                           16 296 120 28)
      (alloy-desktop:show-window window))))
