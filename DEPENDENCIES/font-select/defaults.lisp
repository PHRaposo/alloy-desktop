(in-package #:font-select)

(define-condition no-backend-found (font-select-error)
  ()
  (:report (lambda (c s)
             (declare (ignore c))
             (format s "No usable backend for font-select could be found!"))))

(defun find-in-path (file)
  (let ((path-var (uiop:getenv "PATH")))
    (when path-var
      (dolist (dir (split (if (find :windows *features*) #\; #\:) path-var))
        (let ((p (merge-pathnames file (uiop:ensure-directory-pathname dir))))
          (when (probe-file p) (return p)))))))

(defun determine-default-backend ()
  ;; yad is the only out-of-process font picker on Linux (kdialog/zenity/qarma/
  ;; matedialog have no font dialog, and there is no xdg-desktop-portal font chooser).
  ;; Prefer it; the in-process GTK dialog is the last resort, since its nested main
  ;; loop freezes the GLFW render loop.
  (cond ((find :win32 *features*)
         'font-select.win32:win32)
        ((find :darwin *features*)
         'font-select.macos:macos)
        ((find-in-path "yad")
         'font-select.yad:yad)
        ;; an already loaded libgtk is reused: loading it again resets its state
        ((or (cffi:foreign-symbol-pointer "gtk_settings_get_default")
             (handler-case (cffi:load-foreign-library "libgtk-3.so.0")
               (cffi:load-foreign-library-error (c)
                 (format *error-output* "[font-select] libgtk-3 unavailable: ~A~%" (princ-to-string c))
                 nil)))
         'font-select.gtk:gtk)
        (T
         (error 'no-backend-found))))
