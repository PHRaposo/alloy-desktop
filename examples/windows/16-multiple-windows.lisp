(in-package #:alloy-desktop-examples)

;;; 16 - Multiple independent windows and normal close behaviour.
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[16] Three 440x260 windows open in a diagonal: \"16 - Independent window 1\", \"2\" and \"3\".~%")
  (format t "[16] Do: click each window; close them one at a time, in any order.~%")
  (format t "[16] Expected: each closes alone and the others stay open and painted; the example ends after the last one closes.~%")
  (format t "[16] Must NOT happen: closing one window closing the others, or the program ending while a window is still open.~%")
  (finish-output)
  (multiple-value-bind (one)
      (alloy-desktop:make-window
       screen
       :title "16 - Independent window 1"
       :x 120 :y 150 :width 440 :height 260
       :resizable-p nil)
    (multiple-value-bind (two)
        (alloy-desktop:make-window
         screen
         :title "16 - Independent window 2"
         :x 570 :y 260 :width 440 :height 260
         :resizable-p nil)
      (multiple-value-bind (three)
          (alloy-desktop:make-window
           screen
           :title "16 - Independent window 3"
           :x 1020 :y 370 :width 440 :height 260
           :resizable-p nil)
        (alloy-desktop:show-window one)
        (alloy-desktop:show-window two)
        (alloy-desktop:show-window three)))))
