(in-package #:alloy-desktop-examples)

;;; 62 - modal window: an ordinary window run with RUN-MODAL-DIALOG and an owner, ended by EXIT-MODAL, by ABORT-MODAL
;;; or by closing it, with a second dialog opened from it. Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[62] Window \"62 - Modal window\": a hint, a white line with the last result, and the button Open modal window,~%")
  (format t "[62] which opens a smaller window with OK, Another dialog and Cancel.~%")
  (format t "[62] Do: end it with OK, Return, Cancel, Escape and its close button; open it, press Another dialog, click both~%")
  (format t "[62] windows behind the message, press OK, click the first window, then end the modal window.~%")
  (format t "[62] Expected: OK and Return report value :ACCEPTED accepted T; the others report value NIL accepted NIL.~%")
  (format t "[62] Must NOT happen: the first window answering while the modal window is open, also after the message ended.~%")
  (finish-output)
  (let* ((window (alloy-desktop:make-window screen :title "62 - Modal window"
                                                   :x 120 :y 140 :width 432 :height 128 :resizable-p nil))
         (scale (alloy-desktop:window-content-scale window))
         (root (alloy-desktop:window-root-layout window))
         (status (make-instance 'alloy-desktop:text-view :text "No modal window yet."
                                                         :background (alloy-desktop:rgb 1 1 1))))
    ;; make-window takes px and PLACE logical units: 16 + 400 + 16 by 16 + 96 + 16 at the window's scale
    (alloy-desktop:set-window-size window (round (* scale 432)) (round (* scale 128)))
    (alloy-desktop:place root
                         (make-instance 'alloy-desktop:static-text :text "Open the modal window and end it.")
                         16 16 400 24)
    (alloy-desktop:place root status 16 48 400 24)
    (alloy-desktop:place
     root
     (make-instance
      'alloy-desktop:button
      :text "Open modal window"
      :on-activate
      (lambda ()
        (let* ((dialog (alloy-desktop:make-window screen :title "Modal window"
                                                         :width 332 :height 104 :resizable-p nil))
               (dialog-root (alloy-desktop:window-root-layout dialog)))
          (alloy-desktop:set-window-size dialog (round (* scale 332)) (round (* scale 104)))
          (alloy-desktop:place dialog-root
                               (make-instance 'alloy-desktop:static-text
                                              :text "The window behind waits for this one.")
                               16 16 300 24)
          (loop for (text default-p cancel-p action)
                  in (list (list "OK" t nil (lambda () (alloy-desktop:exit-modal :accepted)))
                           (list "Another dialog" nil nil
                                 (lambda ()
                                   (alloy-desktop:message-dialog "A dialog opened from a modal window."
                                                                 :owner dialog :title "Message")))
                           (list "Cancel" nil t (lambda () (alloy-desktop:abort-modal))))
                for (x width) in '((16 80) (104 124) (236 80))
                do (alloy-desktop:place dialog-root
                                        (make-instance 'alloy-desktop:button :text text :default-p default-p
                                                                             :cancel-p cancel-p :on-activate action)
                                        x 60 width 28))
          (alloy-desktop:place-window-relative-to dialog window nil nil)
          (multiple-value-bind (value accepted-p) (alloy-desktop:run-modal-dialog dialog :owner window)
            (setf (alloy-desktop:widget-text status)
                  (format nil "Ended with value ~S, accepted ~S." value accepted-p))
            (format t "~&[62] modal ended: value ~S accepted ~S~%" value accepted-p)
            (finish-output)))))
     16 84 160 28)
    (alloy-desktop:show-window window)))
