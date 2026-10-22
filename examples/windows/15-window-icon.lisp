(in-package #:alloy-desktop-examples)

;;; 15 - Per-window icon on platforms that support it (Win32 and X11).
;;; Public alloy-desktop API only.

(define-example (screen)
  (format t "~&[15] A 600x340 window opens; window-icon-supported-p = ~S on this backend.~%"
          (alloy-desktop:window-icon-supported-p))
  (format t "[15] Supported on Win32 and X11; Wayland and Darwin refuse a per-window icon, and the title then says so.~%")
  (format t "[15] Do: look at the title-bar icon and the taskbar button.~%")
  (format t "[15] Expected where supported: a 32x32 icon in four quadrants: sky blue top-left, pink top-right, blue bottom-left, magenta bottom-right.~%")
  (format t "[15] Expected where not supported: the title ends in \"(not supported on this backend)\" and the default icon stays.~%")
  (format t "[15] Must NOT happen: an error, or the default icon where the title says \"supported\".~%")
  (format t "[15] Close the window to end the example.~%")
  (finish-output)
  (multiple-value-bind (window)
      (alloy-desktop:make-window
       screen
       :title (format nil "15 - Window icon (~A)"
                      (if (alloy-desktop:window-icon-supported-p)
                          "supported"
                          "not supported on this backend"))
       :width 600 :height 340
       :resizable-p nil)
    (when (alloy-desktop:window-icon-supported-p)
      (let ((pixels (make-array (* 32 32 4)
                                :element-type '(unsigned-byte 8)
                                :initial-element 0)))
        (dotimes (y 32)
          (dotimes (x 32)
            (let ((i (* 4 (+ x (* y 32)))))
              (setf (aref pixels i)       (if (< x 16) 32 240)
                    (aref pixels (+ i 1)) (if (< y 16) 160 80)
                    (aref pixels (+ i 2)) 220
                    (aref pixels (+ i 3)) 255))))
        (alloy-desktop:set-window-icon window pixels 32 32)))
    (alloy-desktop:show-window window)))
