(in-package #:alloy-desktop-examples)

;;; 28 - button: push buttons whose callbacks write what happened into a line of the window; a button disabled
;;; and enabled again (widget-enabled-p) and a button whose text changes (widget-text).
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[28] One fixed-size window \"28 - Button\" (no resize), top to bottom: an instruction line; a white line~%")
  (format t "[28] saying what happened; four buttons COUNT, TARGET (grey: disabled), ENABLE and RENAME.~%")
  (format t "[28] The same 16 px margin separates the content from every edge.~%")
  (format t "[28] Do: press COUNT twice; press TARGET; press ENABLE, then TARGET; press RENAME, then the renamed button;~%")
  (format t "[28] press ENABLE again, then the grey button.~%")
  (format t "[28] Expected: the white line reads \"COUNT pressed 1 time\", \"COUNT pressed 2 times\"; the grey TARGET does~%")
  (format t "[28] nothing; ENABLE makes TARGET black and active and itself reads DISABLE; RENAME changes TARGET's text to~%")
  (format t "[28] RENAMED (and back on the next press); each press is also printed here.~%")
  (format t "[28] Must NOT happen: a grey button reacting to a click; text cut at the bottom of a button; the window resizing.~%")
  (format t "[28] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "28 - Button"
       :x 120 :y 140 :width 432 :height 128
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128))))
    (let* ((root (alloy-desktop:window-root-layout window))
           (status (make-instance 'alloy-desktop:text-view
                                  :text "Nothing pressed yet."
                                  :background (alloy-desktop:rgb 1 1 1)))
           (count 0)
           ;; the two buttons whose callbacks read or write their own text; bound first, made below
           (target nil)
           (enable nil))
      (setf target (make-instance 'alloy-desktop:button
                                  :text "TARGET" :enabled nil
                                  :on-activate (lambda ()
                                                 (setf (alloy-desktop:widget-text status)
                                                       (format nil "~A pressed." (alloy-desktop:widget-text target)))
                                                 (format t "~&[28] ~A~%" (alloy-desktop:widget-text status))
                                                 (finish-output)))
            enable (make-instance 'alloy-desktop:button
                                  :text "ENABLE"
                                  :on-activate (lambda ()
                                                 (let ((on (not (alloy-desktop:widget-enabled-p target))))
                                                   (setf (alloy-desktop:widget-enabled-p target) on
                                                         (alloy-desktop:widget-text enable) (if on "DISABLE" "ENABLE")
                                                         (alloy-desktop:widget-text status)
                                                         (format nil "~A is now ~:[disabled~;enabled~]."
                                                                 (alloy-desktop:widget-text target) on)))
                                                 (format t "~&[28] ~A~%" (alloy-desktop:widget-text status))
                                                 (finish-output))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Press the buttons; the white line says what happened.")
                           16 16 400 24)
      (alloy-desktop:place root status 16 48 400 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "COUNT"
                                          :on-activate (lambda ()
                                                         (incf count)
                                                         (setf (alloy-desktop:widget-text status)
                                                               (format nil "COUNT pressed ~D time~:P." count))
                                                         (format t "~&[28] ~A~%" (alloy-desktop:widget-text status))
                                                         (finish-output)))
                           16 84 94 28)
      (alloy-desktop:place root target 118 84 94 28)
      (alloy-desktop:place root enable 220 84 94 28)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "RENAME"
                                          :on-activate (lambda ()
                                                         (let ((new (if (string= "TARGET" (alloy-desktop:widget-text target))
                                                                        "RENAMED"
                                                                        "TARGET")))
                                                           (setf (alloy-desktop:widget-text status)
                                                                 (format nil "~A renamed to ~A."
                                                                         (alloy-desktop:widget-text target) new)
                                                                 (alloy-desktop:widget-text target) new))
                                                         (format t "~&[28] ~A~%" (alloy-desktop:widget-text status))
                                                         (finish-output)))
                           322 84 94 28)
      (alloy-desktop:show-window window))))
