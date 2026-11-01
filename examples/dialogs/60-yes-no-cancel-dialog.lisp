(in-package #:alloy-desktop-examples)

;;; 60 - yes, no or cancel dialog: YES-NO-CANCEL-DIALOG owned by this window. Yes is the default button and Cancel the
;;; cancel button. Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[60] Window \"60 - Yes no cancel dialog\": a hint, a white line with the last result, and the button Open dialog,~%")
  (format t "[60] which opens a dialog with Cancel, No and Yes; Yes is the default button.~%")
  (format t "[60] Do: answer with Yes, No, Cancel, Return, Escape and the dialog's close button.~%")
  (format t "[60] Expected: Yes and Return return T; No and the close button return NIL; Cancel and Escape return :CANCEL.~%")
  (format t "[60] Must NOT happen: this window reacting while the dialog is open.~%")
  (finish-output)
  (let* ((window (alloy-desktop:make-window screen :title "60 - Yes no cancel dialog"
                                                   :x 120 :y 140 :width 432 :height 128 :resizable-p nil))
         (scale (alloy-desktop:window-content-scale window))
         (root (alloy-desktop:window-root-layout window))
         (status (make-instance 'alloy-desktop:text-view :text "No dialog yet."
                                                         :background (alloy-desktop:rgb 1 1 1))))
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128)))
    (alloy-desktop:place root
                         (make-instance 'alloy-desktop:static-text :text "Open the dialog and answer it.")
                         16 16 400 24)
    (alloy-desktop:place root status 16 48 400 24)
    (alloy-desktop:place root
                         (make-instance 'alloy-desktop:button
                                        :text "Open dialog"
                                        :on-activate
                                        (lambda ()
                                          (let ((value (alloy-desktop:yes-no-cancel-dialog
                                                        "Save the changes before closing?" :owner window)))
                                            (setf (alloy-desktop:widget-text status)
                                                  (format nil "The dialog returned ~S." value))
                                            (format t "~&[60] yes-no-cancel-dialog returned ~S~%" value)
                                            (finish-output))))
                         16 84 128 28)
    (alloy-desktop:show-window window)))
