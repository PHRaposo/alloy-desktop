(in-package #:alloy-desktop-examples)

;;; 29 - default and cancel buttons: Return presses the default button (:default-p) and Escape the cancel button
;;; (:cancel-p), whichever element holds the focus; the window does it, not the buttons' own callbacks.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[29] One fixed-size window \"29 - Default and cancel\" (no resize), top to bottom: an instruction line;~%")
  (format t "[29] a white line saying what was pressed; three buttons OTHER, OK (the default: blue~%")
  (format t "[29] border even without the focus) and CANCEL. The same 16 px margin separates the content from every edge.~%")
  (format t "[29] Do: press Return; press Escape; click OTHER, then press Return and Escape again; click OK and CANCEL.~%")
  (format t "[29] Expected: Return reads \"OK pressed\" and Escape \"CANCEL pressed\", also after OTHER took the focus; a~%")
  (format t "[29] click on any button reads that button; each press is also printed here.~%")
  (format t "[29] Must NOT happen: Return or Escape pressing OTHER; text cut at the bottom of a button; the window resizing.~%")
  (format t "[29] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "29 - Default and cancel"
       :x 120 :y 140 :width 432 :height 128
       :resizable-p nil)
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (let ((scale (alloy-desktop:window-content-scale window)))
      (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128))))
    (let ((root (alloy-desktop:window-root-layout window))
          (status (make-instance 'alloy-desktop:text-view
                                 :text "Nothing pressed yet."
                                 :background (alloy-desktop:rgb 1 1 1))))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Press Return or Escape, or click a button.")
                           16 16 400 24)
      (alloy-desktop:place root status 16 48 400 24)
      (loop for (text x default-p cancel-p) in '(("OTHER" 16 nil nil) ("OK" 208 t nil) ("CANCEL" 316 nil t))
            do (alloy-desktop:place root
                                    (make-instance 'alloy-desktop:button
                                                   :text text :default-p default-p :cancel-p cancel-p
                                                   :on-activate (let ((text text))
                                                                  (lambda ()
                                                                    (setf (alloy-desktop:widget-text status)
                                                                          (format nil "~A pressed." text))
                                                                    (format t "~&[29] ~A pressed~%" text)
                                                                    (finish-output))))
                                    x 84 100 28))
      (alloy-desktop:show-window window))))
