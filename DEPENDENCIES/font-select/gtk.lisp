(in-package #:font-select.gtk)

(cffi:define-foreign-library gtk3 (t "libgtk-3.so.0"))
(cffi:define-foreign-library glib (t "libglib-2.0.so.0"))

(cffi:defcfun ("gtk_disable_setlocale" %gtk-disable-setlocale) :void)
(cffi:defcfun ("gtk_init_check" %gtk-init-check) :boolean
  (argc :pointer) (argv :pointer))
(cffi:defcfun ("gtk_settings_get_default" %gtk-settings-get-default) :pointer)
(cffi:defcfun ("gtk_font_chooser_dialog_new" %font-chooser-dialog-new) :pointer
  (title :string) (parent :pointer))
(cffi:defcfun ("gtk_font_chooser_get_font" %font-chooser-get-font) :pointer
  (chooser :pointer))
(cffi:defcfun ("gtk_font_chooser_set_font" %font-chooser-set-font) :void
  (chooser :pointer) (fontname :string))
(cffi:defcfun ("gtk_dialog_run" %dialog-run) :int
  (dialog :pointer))
(cffi:defcfun ("gtk_widget_destroy" %widget-destroy) :void
  (widget :pointer))
(cffi:defcfun ("gtk_events_pending" %events-pending) :boolean)
(cffi:defcfun ("gtk_main_iteration" %main-iteration) :boolean)
(cffi:defcfun ("g_free" %g-free) :void
  (mem :pointer))

(defconstant +gtk-response-ok+ -5)

(defvar *gtk-initialized* nil)

(defun ensure-gtk ()
  (unless *gtk-initialized*
    ;; GTK is process-global. Loading libgtk again when another library already
    ;; loaded it resets the toolkit state, and a second gtk_init_check then
    ;; registers the GTK types twice.
    (unless (cffi:foreign-symbol-pointer "gtk_settings_get_default")
      (cffi:use-foreign-library gtk3)
      (cffi:use-foreign-library glib))
    ;; A default GtkSettings object exists only after a successful GTK startup.
    (when (cffi:null-pointer-p (%gtk-settings-get-default))
      ;; must run before gtk_init_check, which otherwise calls setlocale(LC_ALL,"").
      (%gtk-disable-setlocale)
      (unless (%gtk-init-check (cffi:null-pointer) (cffi:null-pointer))
        (error "gtk_init_check failed (no display available?)")))
    (setf *gtk-initialized* t)))

(defun flush-events ()
  (loop while (%events-pending) do (%main-iteration)))

(defun %read-font-string (chooser)
  "Read the chooser's font, free the C string, return a Lisp string or NIL."
  (let ((p (%font-chooser-get-font chooser)))
    (unless (cffi:null-pointer-p p)
      (unwind-protect
           (cffi:foreign-string-to-lisp p :encoding :utf-8)
        (%g-free p)))))

(defclass gtk (backend) ())

(defmethod select-with ((backend gtk) &key default (variant :full) &allow-other-keys)
  "VARIANT is accepted for API parity but ignored: gtk_font_chooser_dialog has no
flag for hiding widgets."
  (declare (ignore variant))
  ;; SBCL traps FP exceptions that Cairo/Mesa raise inside GTK; mask them (SBCL bug 1519630).
  (handler-case
      (float-features:with-float-traps-masked t
  (ensure-gtk)
  (let ((dialog (%font-chooser-dialog-new "Select Font" (cffi:null-pointer))))
    (when (cffi:null-pointer-p dialog)
      (return-from select-with (values nil nil)))
    (unwind-protect
         (progn
           (when (and default (getf default :family))
             (%font-chooser-set-font
              dialog
              (format nil "~A ~A" (getf default :family) (or (getf default :size) 12))))
           (if (= (%dialog-run dialog) +gtk-response-ok+)
               (let ((plist (font-select::%pango-string->plist (%read-font-string dialog))))
                 (if plist (values plist t) (values nil nil)))
               (values nil nil)))
      (%widget-destroy dialog)
      (flush-events))))
    (error (c)
      (format *error-output* "[font-select.gtk] ~A~%" (princ-to-string c))
      (values nil nil))))
