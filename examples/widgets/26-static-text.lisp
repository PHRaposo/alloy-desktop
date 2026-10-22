(in-package #:alloy-desktop-examples)

;;; 26 - static text: short and wrapped labels, colour, background, border, font and disabled state, all set by
;;; initargs and setters of the widgets themselves (static-text, text-view, button).
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[26] One fixed-size window \"26 - Static text\" (no resize), top to bottom: an instruction line; a short~%")
  (format t "[26] label; a long paragraph on a white face inside a thin grey frame, broken into lines at the frame's width;~%")
  (format t "[26] a dark blue label; a larger bold label; a grey (disabled) label; a read-only text view on white; three buttons~%")
  (format t "[26] PRESS, DISABLED (grey text) and TOGGLE. The same 16 px margin separates the content from every edge.~%")
  (format t "[26] Do: press PRESS; press DISABLED; press TOGGLE, then DISABLED again; press TOGGLE once more.~%")
  (format t "[26] Expected: PRESS prints \"[26] PRESS pressed\"; DISABLED prints nothing while its text is grey; TOGGLE~%")
  (format t "[26] makes DISABLED black and active (it then prints \"[26] DISABLED pressed\") and turns the grey label~%")
  (format t "[26] dark blue; the next TOGGLE puts both back to grey.~%")
  (format t "[26] Must NOT happen: the paragraph running past its frame; text cut at the bottom of a widget; a grey button~%")
  (format t "[26] reacting to a click; the window resizing from its edges.~%")
  (format t "[26] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "26 - Static text"
       :x 120 :y 140 :width 432 :height 298
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 266 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 298))))
    (let* ((root (alloy-desktop:window-root-layout window))
           (blue (alloy-desktop:rgb 0.10 0.25 0.55))
           (disabled-label (make-instance 'alloy-desktop:static-text
                                          :text "Disabled label: grey until TOGGLE." :enabled nil))
           (disabled-button (make-instance 'alloy-desktop:button
                                           :text "DISABLED" :enabled nil
                                           :on-activate (lambda ()
                                                          (format t "~&[26] DISABLED pressed~%")
                                                          (finish-output)))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Press the three buttons; watch the grey label and button.")
                           16 16 400 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text :text "Short label.")
                           16 48 400 20)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "A long paragraph is broken into lines at the width of its own widget, in the font it is drawn with; the frame and the white face are the widget's own border and background."
                                          :wrap t
                                          :background (alloy-desktop:rgb 1 1 1)
                                          :border alloy-desktop:*tab-border*)
                           16 76 400 52)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Dark blue label." :foreground blue)
                           16 136 400 20)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text (format nil "Bold label in an explicit font: ~A 11 bold."
                                                        (first alloy-desktop:*fallback-families*))
                                          :font (list (first alloy-desktop:*fallback-families*) 11 :weight :bold))
                           16 164 400 22)
      (alloy-desktop:place root disabled-label 16 194 400 20)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:text-view
                                          :text "Read-only text view, white face."
                                          :background (alloy-desktop:rgb 1 1 1))
                           16 222 400 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "PRESS"
                                          :on-activate (lambda ()
                                                         (format t "~&[26] PRESS pressed~%")
                                                         (finish-output)))
                           16 254 120 28)
      (alloy-desktop:place root disabled-button 156 254 120 28)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "TOGGLE"
                                          :on-activate (lambda ()
                                                         (let ((on (not (alloy-desktop:widget-enabled-p disabled-button))))
                                                           (setf (alloy-desktop:widget-enabled-p disabled-button) on
                                                                 (alloy-desktop:widget-enabled-p disabled-label) on
                                                                 (alloy-desktop:widget-foreground disabled-label) (and on blue))
                                                           (format t "~&[26] TOGGLE: DISABLED is now ~:[off~;on~]~%" on)
                                                           (finish-output))))
                           296 254 120 28)
      (alloy-desktop:show-window window))))
