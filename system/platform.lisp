(in-package :alloy-desktop)

(defvar *wsl-p*
  (and (uiop:os-unix-p)
       (let ((rel (with-open-file (stream "/proc/sys/kernel/osrelease"
                                          :if-does-not-exist nil)
                    (when stream (read-line stream nil)))))
         (and rel (search "microsoft" rel :test #'char-equal))))
  "Non-NIL when the current host is Windows Subsystem for Linux.")

#+win32
(defun use-windows-ansi-strings ()
  "Pass C strings in the Windows ANSI code page and reread SB-EXT:*RUNTIME-PATHNAME* with GetModuleFileNameW."
  (let ((code-page (intern (format nil "CP~D" (cffi:foreign-funcall "GetACP" :uint32)) :keyword)))
    (if (sb-impl::get-external-format code-page)
        (setf sb-alien::*default-c-string-external-format* code-page)
        (warn "No external format for the Windows ANSI code page ~A." code-page)))
  (setf sb-ext:*runtime-pathname*
        (cffi:with-foreign-object (buffer :uint16 32768)
          (let ((length (cffi:foreign-funcall "GetModuleFileNameW" :pointer (cffi:null-pointer)
                                              :pointer buffer :uint32 32768 :uint32)))
            (sb-ext:native-pathname
             (cffi:foreign-string-to-lisp buffer :count (* 2 length) :encoding :utf-16le))))))

#+win32
(progn
  (use-windows-ansi-strings)
  (pushnew 'use-windows-ansi-strings sb-ext:*init-hooks*))

(defun open-url (url)
  "Open URL with the desktop's native/default browser or URL handler."
  (handler-bind ((error
                   (lambda (condition)
                     (format *error-output* "~&OPEN-URL ~A failed: ~A~%"
                             url (princ-to-string condition))
                     (finish-output *error-output*))))
    (let ((url-string (princ-to-string url)))
      (cond
        (*wsl-p*
         (uiop:run-program (list "cmd.exe" "/c" "start" "" url-string)
                           :output nil :wait nil))
        ((uiop:os-windows-p)
         (apply #'uiop:run-program (list "cmd" "/c" "start" "" url-string)
                :output nil :wait nil (hidden-console-options)))
        ((uiop:os-macosx-p)
         (uiop:run-program (list "open" url-string)
                           :output nil :wait nil))
        (t
         #+linux
         (run-shell-command (list "xdg-open" url-string)
                            :wait nil :output nil :error-output nil)
         #-linux
         (uiop:run-program (list "xdg-open" url-string)
                           :output nil :wait nil)))
      t)))
