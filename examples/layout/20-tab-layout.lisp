(in-package #:alloy-desktop-examples)

;;; 20 - tab layout: the tab headers switch the visible page.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[20] One resizable 640x360 window \"20 - Tab layout\": an instruction line, a WHICH PAGE? button and~%")
  (format t "[20] a tab layout with three tabs \"One\", \"Two\", \"Three\", each page with its own text and button.~%")
  (format t "[20] Do: click each tab, press the button of each page, press WHICH PAGE? after each switch, resize the window.~%")
  (format t "[20] Expected: a click on a tab shows only that page (\"Page One\" ...); its button prints~%")
  (format t "[20] \"[20] button of page <n> pressed\"; WHICH PAGE? prints the current tab; the tab layout follows the window size.~%")
  (format t "[20] Must NOT happen: two pages visible at once; a hidden page's button answering a click;~%")
  (format t "[20] the tab bar not following the window width.~%")
  (format t "[20] Close the window from its title bar to end.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title "20 - Tab layout"
       :x 120 :y 140 :width 640 :height 360
       :resizable-p t)
    (multiple-value-bind (root tabs one two three)
        (values (alloy-desktop:window-root-layout window) nil
                (make-instance 'alloy-desktop:view)
                (make-instance 'alloy-desktop:view)
                (make-instance 'alloy-desktop:view))
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:static-text
                                          :text "Click a tab to switch the page; resize the window.")
                           16 16 480 24)
      (alloy-desktop:place root
                           (make-instance 'alloy-desktop:button
                                          :text "WHICH PAGE?"
                                          :on-activate (lambda ()
                                                         (format t "~&[20] current page: ~A~%"
                                                                 (cond ((eq (alloy-desktop:current-page tabs) one) "One")
                                                                       ((eq (alloy-desktop:current-page tabs) two) "Two")
                                                                       ((eq (alloy-desktop:current-page tabs) three) "Three")
                                                                       (t (alloy-desktop:current-page tabs))))
                                                         (finish-output)))
                           16 48 160 28)
      ;; each page: its own text and a button; the button joins the tab's focus list
      (alloy-desktop:place one (make-instance 'alloy-desktop:static-text :text "Page One") 16 16 200 24)
      (alloy-desktop:place two (make-instance 'alloy-desktop:static-text :text "Page Two") 16 16 200 24)
      (alloy-desktop:place three (make-instance 'alloy-desktop:static-text :text "Page Three") 16 16 200 24)
      (setf tabs
            (make-instance
             'alloy-desktop:tab-layout
             :tabs (list
                    (alloy-desktop:make-tab
                     "One" one
                     :focus (alloy-desktop:make-focus-list
                             (list (alloy-desktop:place
                                    one
                                    (make-instance 'alloy-desktop:button
                                                   :text "Button of page One"
                                                   :on-activate (lambda ()
                                                                  (format t "~&[20] button of page One pressed~%")
                                                                  (finish-output)))
                                    16 56 220 28))))
                    (alloy-desktop:make-tab
                     "Two" two
                     :focus (alloy-desktop:make-focus-list
                             (list (alloy-desktop:place
                                    two
                                    (make-instance 'alloy-desktop:button
                                                   :text "Button of page Two"
                                                   :on-activate (lambda ()
                                                                  (format t "~&[20] button of page Two pressed~%")
                                                                  (finish-output)))
                                    16 56 220 28))))
                    (alloy-desktop:make-tab
                     "Three" three
                     :focus (alloy-desktop:make-focus-list
                             (list (alloy-desktop:place
                                    three
                                    (make-instance 'alloy-desktop:button
                                                   :text "Button of page Three"
                                                   :on-activate (lambda ()
                                                                  (format t "~&[20] button of page Three pressed~%")
                                                                  (finish-output)))
                                    16 56 220 28)))))))
      ;; X with RIGHT and Y with BOTTOM stretch the tab layout with the window
      (alloy-desktop:place root tabs 16 88 nil nil :right 16 :bottom 16)
      (alloy-desktop:show-window window))))
