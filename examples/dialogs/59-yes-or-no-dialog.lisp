(in-package #:alloy-desktop-examples)

;;; 59 - yes or no dialog: YES-OR-NO-DIALOG owned by this window. Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[59] Window \"59 - Yes or no dialog\": a hint, a white line with the last result, and the button Open dialog,~%")
  (format t "[59] which opens a dialog with No and Yes; No is the default button.~%")
  (format t "[59] Do: answer with Yes, with No, with Return and with the dialog's close button.~%")
  (format t "[59] Expected: Yes returns T; No, Return and the close button return NIL; the dialog is centred on this window.~%")
  (format t "[59] Must NOT happen: this window reacting while the dialog is open; Escape ending the dialog.~%")
  (finish-output)
  (let* ((window (alloy-desktop:make-window screen :title "59 - Yes or no dialog"
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
                                          (let ((value (alloy-desktop:yes-or-no-dialog "Do you want to continue?"
                                                                                       :owner window)))
                                            (setf (alloy-desktop:widget-text status)
                                                  (format nil "The dialog returned ~S." value))
                                            (format t "~&[59] yes-or-no-dialog returned ~S~%" value)
                                            (finish-output))))
                         16 84 128 28)
    (alloy-desktop:show-window window)))
