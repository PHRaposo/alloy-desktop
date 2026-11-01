(in-package #:alloy-desktop-examples)

;;; 58 - message dialog: MESSAGE-DIALOG owned by this window. The dialog sizes itself to its text, wraps a long line,
;;; keeps its own line breaks and blocks the window behind it until it ends. Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[58] Window \"58 - Message dialog\": a hint, a white line with the last result, and the buttons Short message,~%")
  (format t "[58] Long message and Several lines. Each opens a dialog with an OK button.~%")
  (format t "[58] Do: end one dialog with OK, one with Return, one with its close button; click this window during a dialog.~%")
  (format t "[58] Expected: the dialog is centred on this window with the whole text visible; the white line reads~%")
  (format t "[58] \"The dialog returned NIL.\"; afterwards this window has the active title bar.~%")
  (format t "[58] Must NOT happen: this window reacting while a dialog is open; text cut; Escape ending the dialog.~%")
  (finish-output)
  (let* ((window (alloy-desktop:make-window screen :title "58 - Message dialog"
                                                   :x 120 :y 140 :width 432 :height 128 :resizable-p nil))
         (scale (alloy-desktop:window-content-scale window))
         (root (alloy-desktop:window-root-layout window))
         (status (make-instance 'alloy-desktop:text-view :text "No dialog yet."
                                                         :background (alloy-desktop:rgb 1 1 1))))
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128)))
    (alloy-desktop:place root
                         (make-instance 'alloy-desktop:static-text :text "Choose a message to show.")
                         16 16 400 24)
    (alloy-desktop:place root status 16 48 400 24)
    (loop for (text title message)
            in (list (list "Short message" "Saved" "The document was saved.")
                     (list "Long message" "Could not save"
                           (format nil "The document could not be saved because the disk is full. Free some space on the ~
disk or choose another location, then save the document again. Your changes stay open in this window until you ~
close it, so nothing has been lost, but nothing has been written to the disk yet either."))
                     (list "Several lines" "Export finished"
                           (format nil "The export has finished.~%~%12 files were written.~%2 files were skipped.")))
          for x from 16 by 136
          do (let ((title title) (message message))
               (alloy-desktop:place root
                                    (make-instance 'alloy-desktop:button
                                                   :text text
                                                   :on-activate
                                                   (lambda ()
                                                     (let ((value (alloy-desktop:message-dialog message :owner window
                                                                                                        :title title)))
                                                       (setf (alloy-desktop:widget-text status)
                                                             (format nil "The dialog returned ~S." value))
                                                       (format t "~&[58] message-dialog returned ~S~%" value)
                                                       (finish-output))))
                                    x 84 128 28)))
    (alloy-desktop:show-window window)))
