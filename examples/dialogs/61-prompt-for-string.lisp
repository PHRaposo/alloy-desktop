(in-package #:alloy-desktop-examples)

;;; 61 - prompt for string: PROMPT-FOR-STRING owned by this window: an editable field that has the keyboard when the
;;; dialog opens, OK as the default button and Cancel as the cancel button. Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[61] Window \"61 - Prompt for string\": a hint, a white line with the last result, and the buttons Short prompt~%")
  (format t "[61] and Long prompt. Each opens a dialog with a field, Cancel and OK.~%")
  (format t "[61] Do: type without clicking the field; end with Return, with OK, with Cancel, with Escape, with the close button.~%")
  (format t "[61] Expected: the keys reach the field at once; Return and OK return its text; the others return NIL.~%")
  (format t "[61] Must NOT happen: having to click the field; this window reacting while the dialog is open.~%")
  (finish-output)
  (let* ((window (alloy-desktop:make-window screen :title "61 - Prompt for string"
                                                   :x 120 :y 140 :width 432 :height 128 :resizable-p nil))
         (scale (alloy-desktop:window-content-scale window))
         (root (alloy-desktop:window-root-layout window))
         (status (make-instance 'alloy-desktop:text-view :text "No dialog yet."
                                                         :background (alloy-desktop:rgb 1 1 1))))
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128)))
    (alloy-desktop:place root
                         (make-instance 'alloy-desktop:static-text :text "Open a dialog and type a name.")
                         16 16 400 24)
    (alloy-desktop:place root status 16 48 400 24)
    (loop for (text prompt initial)
            in (list (list "Short prompt" "Name:" "")
                     (list "Long prompt"
                           (format nil "Type the name of the new document. The name appears in the title bar and in the ~
list of recent documents, and it can be changed later from the File menu.")
                           "Untitled"))
          for x from 16 by 136
          do (let ((prompt prompt) (initial initial))
               (alloy-desktop:place root
                                    (make-instance 'alloy-desktop:button
                                                   :text text
                                                   :on-activate
                                                   (lambda ()
                                                     (let ((value (alloy-desktop:prompt-for-string
                                                                   prompt :owner window :initial-string initial)))
                                                       (setf (alloy-desktop:widget-text status)
                                                             (format nil "The dialog returned ~S." value))
                                                       (format t "~&[61] prompt-for-string returned ~S~%" value)
                                                       (finish-output))))
                                    x 84 128 28)))
    (alloy-desktop:show-window window)))
