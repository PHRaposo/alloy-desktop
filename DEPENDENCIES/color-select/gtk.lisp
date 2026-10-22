(in-package #:color-select.gtk)

(cffi:define-foreign-library gtk3 (t "libgtk-3.so.0"))

(cffi:defcstruct gdk-rgba
  (red :double) (green :double) (blue :double) (alpha :double))

(cffi:defcfun ("gtk_disable_setlocale" %gtk-disable-setlocale) :void)
(cffi:defcfun ("gtk_init_check" %gtk-init-check) :boolean
  (argc :pointer) (argv :pointer))
(cffi:defcfun ("gtk_settings_get_default" %gtk-settings-get-default) :pointer)
(cffi:defcfun ("gtk_color_chooser_dialog_new" %color-chooser-dialog-new) :pointer
  (title :string) (parent :pointer))
(cffi:defcfun ("gtk_color_chooser_get_rgba" %color-chooser-get-rgba) :void
  (chooser :pointer) (rgba :pointer))
(cffi:defcfun ("gtk_color_chooser_set_rgba" %color-chooser-set-rgba) :void
  (chooser :pointer) (rgba :pointer))
(cffi:defcfun ("gtk_dialog_run" %dialog-run) :int
  (dialog :pointer))
(cffi:defcfun ("gtk_widget_destroy" %widget-destroy) :void
  (widget :pointer))
(cffi:defcfun ("gtk_events_pending" %events-pending) :boolean)
(cffi:defcfun ("gtk_main_iteration" %main-iteration) :boolean)

(defconstant +gtk-response-ok+ -5)

(defvar *gtk-initialized* nil)

(defun ensure-gtk ()
  (unless *gtk-initialized*
    ;; GTK is process-global. Loading libgtk again when another library already
    ;; loaded it resets the toolkit state, and a second gtk_init_check then
    ;; registers the GTK types twice.
    (unless (cffi:foreign-symbol-pointer "gtk_settings_get_default")
      (cffi:use-foreign-library gtk3))
    ;; A default GtkSettings object exists only after a successful GTK startup.
    (when (cffi:null-pointer-p (%gtk-settings-get-default))
      ;; must run before gtk_init_check, which otherwise calls setlocale(LC_ALL,"").
      (%gtk-disable-setlocale)
      (unless (%gtk-init-check (cffi:null-pointer) (cffi:null-pointer))
        (error "gtk_init_check failed (no display available?)")))
    (setf *gtk-initialized* t)))

(defun flush-events ()
  (loop while (%events-pending) do (%main-iteration)))

(defun %rgba-component (ptr slot)
  (float (cffi:foreign-slot-value ptr '(:struct gdk-rgba) slot) 1.0))

(defclass gtk (backend) ())

(defmethod choose-color-with ((backend gtk) &key default &allow-other-keys)
  ;; SBCL traps FP exceptions that Cairo/Mesa raise inside GTK; mask them (SBCL bug 1519630).
  (handler-case
      (float-features:with-float-traps-masked t
  (ensure-gtk)
  (let ((dialog (%color-chooser-dialog-new "Select Color" (cffi:null-pointer))))
    (when (cffi:null-pointer-p dialog)
      (return-from choose-color-with (values nil nil)))
    (unwind-protect
         (progn
           (when default
             (cffi:with-foreign-object (rgba '(:struct gdk-rgba))
               (setf (cffi:foreign-slot-value rgba '(:struct gdk-rgba) 'red)   (coerce (first default) 'double-float)
                     (cffi:foreign-slot-value rgba '(:struct gdk-rgba) 'green) (coerce (second default) 'double-float)
                     (cffi:foreign-slot-value rgba '(:struct gdk-rgba) 'blue)  (coerce (third default) 'double-float)
                     (cffi:foreign-slot-value rgba '(:struct gdk-rgba) 'alpha) 1d0)
               (%color-chooser-set-rgba dialog rgba)))
           (if (= (%dialog-run dialog) +gtk-response-ok+)
               (cffi:with-foreign-object (out '(:struct gdk-rgba))
                 (%color-chooser-get-rgba dialog out)
                 (values (list (%rgba-component out 'red)
                               (%rgba-component out 'green)
                               (%rgba-component out 'blue))
                         t))
               (values nil nil)))
      (%widget-destroy dialog)
      (flush-events))))
    (error (c)
      (format *error-output* "[color-select.gtk] ~A~%" (princ-to-string c))
      (values nil nil))))
