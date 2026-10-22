(in-package #:color-select)

(define-condition no-backend-found (color-select-error)
  ()
  (:report (lambda (c s)
             (declare (ignore c))
             (format s "No usable backend for color-select could be found!"))))

(defun find-in-path (file)
  (let ((path (uiop:getenv "PATH")))
    (when path
      (dolist (dir (uiop:split-string path :separator ":"))
        (when (plusp (length dir))
          (let ((candidate (merge-pathnames file (uiop:ensure-directory-pathname dir))))
            (when (probe-file candidate)
              (return candidate))))))))

(defun determine-default-backend ()
  ;; Prefer out-of-process CLI dialogs on Linux: an in-process GTK dialog runs a
  ;; nested main loop (gtk_dialog_run) that freezes the GLFW render loop and, on a
  ;; GL/EGL compositor, replaces the current context. A subprocess has its own
  ;; context and event loop. GTK is the last resort.
  (cond ((find :win32 *features*)
         'color-select.win32:win32)
        ((find :darwin *features*)
         'color-select.macos:macos)
        ((find-in-path "kdialog")
         'color-select.kdialog:kdialog)
        ((find-in-path "matedialog")
         (make-instance 'color-select.zenity:zenity :program-name "matedialog"))
        ((find-in-path "qarma")
         (make-instance 'color-select.zenity:zenity :program-name "qarma"))
        ((find-in-path "yad")
         'color-select.yad:yad)
        ((find-in-path "zenity")
         'color-select.zenity:zenity)
        ;; an already loaded libgtk is reused: loading it again resets its state
        ((or (cffi:foreign-symbol-pointer "gtk_settings_get_default")
             (handler-case (cffi:load-foreign-library "libgtk-3.so.0")
               (cffi:load-foreign-library-error (c)
                 (format *error-output* "[color-select] libgtk-3 unavailable: ~A~%" (princ-to-string c))
                 nil)))
         'color-select.gtk:gtk)
        (t
         (error 'no-backend-found))))
