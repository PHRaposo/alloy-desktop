(in-package #:paper-print)

;;; Linux native printing backend.
;;;
;;; This deliberately mirrors the Windows backend's architecture: select a
;;; native printer, obtain the platform print surface, copy each RGBA raster to
;;; that surface exactly once, finish each page, and hand the completed job to
;;; the native printing subsystem.  PAPER-PRINT does not generate PDF or
;;; PostScript.  GTK's Unix print backend (normally CUPS, or the built-in
;;; "Print to File" virtual printer) owns the spool/document format.

(defconstant +gtk-response-ok+ -5)
(defconstant +gtk-unit-points+ 1)
(defconstant +gtk-unit-mm+ 3)
(defconstant +cairo-format-argb32+ 0)

(cffi:define-foreign-library paper-print-gtk3
  (:unix (:or "libgtk-3.so.0" "libgtk-3.so")))
(cffi:define-foreign-library paper-print-gobject
  (:unix (:or "libgobject-2.0.so.0" "libgobject-2.0.so")))
(cffi:define-foreign-library paper-print-glib
  (:unix (:or "libglib-2.0.so.0" "libglib-2.0.so")))
(cffi:define-foreign-library paper-print-cairo
  (:unix (:or "libcairo.so.2" "libcairo.so")))

(defvar *native-libraries-loaded-p* nil)
(defvar *gtk-initialized-p* nil)

(defun %foreign-symbol-available-p (name)
  (let ((pointer (ignore-errors (cffi:foreign-symbol-pointer name))))
    (and pointer (not (cffi:null-pointer-p pointer)))))

(defun %ensure-native-libraries ()
  (unless *native-libraries-loaded-p*
    (handler-case
        (progn
          ;; Several native providers in the same host process may already use GTK3.
          ;; Re-loading libgtk through a second CFFI foreign-library object can
          ;; re-run GTK/ATK type registration on some Linux runtimes.  Reuse
          ;; process-global symbols when another provider already loaded them;
          ;; standalone PAPER-PRINT still loads every library it needs.
          (unless (%foreign-symbol-available-p "gtk_print_settings_new")
            (cffi:load-foreign-library 'paper-print-gtk3))
          (unless (%foreign-symbol-available-p "g_object_ref")
            (cffi:load-foreign-library 'paper-print-gobject))
          (unless (%foreign-symbol-available-p "g_main_context_iteration")
            (cffi:load-foreign-library 'paper-print-glib))
          (unless (%foreign-symbol-available-p "cairo_create")
            (cffi:load-foreign-library 'paper-print-cairo))
          (setf *native-libraries-loaded-p* t))
      (error (condition)
        (%fail :load-native-printing (princ-to-string condition)))))
  t)

(cffi:defcstruct g-error
  (domain :uint32)
  (code :int)
  (message :pointer))

(cffi:defcfun ("g_error_free" %g-error-free) :void (error :pointer))
(cffi:defcfun ("g_object_ref" %g-object-ref) :pointer (object :pointer))
(cffi:defcfun ("g_object_unref" %g-object-unref) :void (object :pointer))
(cffi:defcfun ("g_main_context_iteration" %g-main-context-iteration) :int
  (context :pointer) (may-block :int))
(cffi:defcfun ("g_filename_to_uri" %g-filename-to-uri) :pointer
  (filename :string) (hostname :pointer) (error :pointer))
(cffi:defcfun ("g_free" %g-free) :void (pointer :pointer))

(cffi:defcfun ("gtk_init_check" %gtk-init-check) :int
  (argc :pointer) (argv :pointer))
(cffi:defcfun ("gtk_settings_get_default" %gtk-settings-get-default) :pointer)
(cffi:defcfun ("gtk_print_settings_new" %gtk-print-settings-new) :pointer)
(cffi:defcfun ("gtk_print_settings_copy" %gtk-print-settings-copy) :pointer
  (settings :pointer))
(cffi:defcfun ("gtk_print_settings_set_printer" %gtk-print-settings-set-printer) :void
  (settings :pointer) (printer :string))
(cffi:defcfun ("gtk_print_settings_get_printer" %gtk-print-settings-get-printer) :pointer
  (settings :pointer))
(cffi:defcfun ("gtk_print_settings_set" %gtk-print-settings-set) :void
  (settings :pointer) (key :string) (value :string))
(cffi:defcfun ("gtk_print_settings_get_resolution" %gtk-print-settings-resolution) :int
  (settings :pointer))

(cffi:defcfun ("gtk_page_setup_new" %gtk-page-setup-new) :pointer)
(cffi:defcfun ("gtk_page_setup_copy" %gtk-page-setup-copy) :pointer
  (page-setup :pointer))
(cffi:defcfun ("gtk_page_setup_get_page_width" %gtk-page-width) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_page_height" %gtk-page-height) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_paper_width" %gtk-paper-width) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_paper_height" %gtk-paper-height) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_left_margin" %gtk-left-margin) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_right_margin" %gtk-right-margin) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_top_margin" %gtk-top-margin) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_bottom_margin" %gtk-bottom-margin) :double
  (page-setup :pointer) (unit :int))
(cffi:defcfun ("gtk_page_setup_get_paper_size" %gtk-page-paper-size) :pointer
  (page-setup :pointer))
(cffi:defcfun ("gtk_paper_size_get_name" %gtk-paper-size-name) :pointer
  (paper-size :pointer))

(cffi:defcfun ("gtk_page_setup_unix_dialog_new" %gtk-page-setup-dialog-new) :pointer
  (title :string) (parent :pointer))
(cffi:defcfun ("gtk_page_setup_unix_dialog_set_page_setup" %gtk-page-setup-dialog-set-page) :void
  (dialog :pointer) (page-setup :pointer))
(cffi:defcfun ("gtk_page_setup_unix_dialog_get_page_setup" %gtk-page-setup-dialog-get-page) :pointer
  (dialog :pointer))
(cffi:defcfun ("gtk_page_setup_unix_dialog_set_print_settings" %gtk-page-setup-dialog-set-settings) :void
  (dialog :pointer) (settings :pointer))
(cffi:defcfun ("gtk_page_setup_unix_dialog_get_print_settings" %gtk-page-setup-dialog-get-settings) :pointer
  (dialog :pointer))

(cffi:defcfun ("gtk_print_unix_dialog_new" %gtk-print-dialog-new) :pointer
  (title :string) (parent :pointer))
(cffi:defcfun ("gtk_print_unix_dialog_set_settings" %gtk-print-dialog-set-settings) :void
  (dialog :pointer) (settings :pointer))
(cffi:defcfun ("gtk_print_unix_dialog_get_settings" %gtk-print-dialog-get-settings) :pointer
  (dialog :pointer))
(cffi:defcfun ("gtk_print_unix_dialog_set_page_setup" %gtk-print-dialog-set-page) :void
  (dialog :pointer) (page-setup :pointer))
(cffi:defcfun ("gtk_print_unix_dialog_get_page_setup" %gtk-print-dialog-get-page) :pointer
  (dialog :pointer))
(cffi:defcfun ("gtk_print_unix_dialog_set_embed_page_setup" %gtk-print-dialog-embed-page-setup) :void
  (dialog :pointer) (embed :int))
(cffi:defcfun ("gtk_print_unix_dialog_get_selected_printer" %gtk-print-dialog-printer) :pointer
  (dialog :pointer))
(cffi:defcfun ("gtk_dialog_run" %gtk-dialog-run) :int (dialog :pointer))

(defun %run-dialog (dialog)
  "Run a GTK modal dialog while masking FP traps raised inside GTK/Cairo.

GTK3 may raise INVALID and DIVIDE-BY-ZERO exceptions internally while its
modal event loop runs. FLOAT-FEATURES restores the caller's trap state on exit."
  (float-features:with-float-traps-masked (:invalid :divide-by-zero)
    (%gtk-dialog-run dialog)))
(cffi:defcfun ("gtk_widget_destroy" %gtk-widget-destroy) :void (widget :pointer))

(cffi:defcfun ("gtk_enumerate_printers" %gtk-enumerate-printers) :void
  (callback :pointer) (data :pointer) (destroy-notify :pointer) (wait :int))
(cffi:defcfun ("gtk_printer_get_name" %gtk-printer-name) :pointer
  (printer :pointer))
(cffi:defcfun ("gtk_printer_get_default_page_size" %gtk-printer-default-page) :pointer
  (printer :pointer))
(cffi:defcfun ("gtk_printer_is_default" %gtk-printer-default-p) :int
  (printer :pointer))

(cffi:defcfun ("gtk_print_job_new" %gtk-print-job-new) :pointer
  (title :string) (printer :pointer) (settings :pointer) (page-setup :pointer))
(cffi:defcfun ("gtk_print_job_get_surface" %gtk-print-job-surface) :pointer
  (job :pointer) (error :pointer))
(cffi:defcfun ("gtk_print_job_send" %gtk-print-job-send) :void
  (job :pointer) (callback :pointer) (data :pointer) (destroy-notify :pointer))

(cffi:defcfun ("cairo_create" %cairo-create) :pointer (surface :pointer))
(cffi:defcfun ("cairo_destroy" %cairo-destroy) :void (context :pointer))
(cffi:defcfun ("cairo_status" %cairo-status) :int (context :pointer))
(cffi:defcfun ("cairo_surface_finish" %cairo-surface-finish) :void (surface :pointer))
(cffi:defcfun ("cairo_surface_status" %cairo-surface-status) :int (surface :pointer))
(cffi:defcfun ("cairo_surface_destroy" %cairo-surface-destroy) :void (surface :pointer))
(cffi:defcfun ("cairo_image_surface_create_for_data" %cairo-image-surface-for-data) :pointer
  (data :pointer) (format :int) (width :int) (height :int) (stride :int))
(cffi:defcfun ("cairo_save" %cairo-save) :void (context :pointer))
(cffi:defcfun ("cairo_restore" %cairo-restore) :void (context :pointer))
(cffi:defcfun ("cairo_translate" %cairo-translate) :void
  (context :pointer) (tx :double) (ty :double))
(cffi:defcfun ("cairo_scale" %cairo-scale) :void
  (context :pointer) (sx :double) (sy :double))
(cffi:defcfun ("cairo_rectangle" %cairo-rectangle) :void
  (context :pointer) (x :double) (y :double) (width :double) (height :double))
(cffi:defcfun ("cairo_clip" %cairo-clip) :void (context :pointer))
(cffi:defcfun ("cairo_set_source_surface" %cairo-set-source-surface) :void
  (context :pointer) (surface :pointer) (x :double) (y :double))
(cffi:defcfun ("cairo_paint" %cairo-paint) :void (context :pointer))
(cffi:defcfun ("cairo_show_page" %cairo-show-page) :void (context :pointer))

(defun %foreign-string (pointer)
  (unless (cffi:null-pointer-p pointer)
    (cffi:foreign-string-to-lisp pointer :encoding :utf-8)))

(defun %g-error-message (error)
  (if (cffi:null-pointer-p error)
      "unknown native printing error"
      (or (%foreign-string
           (cffi:foreign-slot-value error '(:struct g-error) 'message))
          "unknown native printing error")))

(defun %ensure-gtk ()
  (%ensure-native-libraries)
  (unless *gtk-initialized-p*
    ;; GTK is process-global.  The host process may already have initialized GTK
    ;; via another native provider.  Calling gtk_init_check
    ;; a second time is not safe on every GTK3 build: the Debian runtime can
    ;; attempt to register GtkWidget/ATK types again.
    ;; A default GtkSettings object exists only after successful GTK startup,
    ;; so reuse that process-global initialization when it is already present.
    (if (not (cffi:null-pointer-p (%gtk-settings-get-default)))
        (setf *gtk-initialized-p* t)
        (progn
          (cffi:with-foreign-object (argc :int)
            (cffi:with-foreign-object (argv :pointer)
              (setf (cffi:mem-ref argc :int) 0
                    (cffi:mem-ref argv :pointer) (cffi:null-pointer))
              (unless (plusp (%gtk-init-check argc argv))
                (%fail :gtk-init-check "GTK could not open the current display."))))
          (setf *gtk-initialized-p* t))))
  t)

(defun %ref-or-null (pointer)
  (if (or (null pointer) (cffi:null-pointer-p pointer))
      (cffi:null-pointer)
      (%g-object-ref pointer)))

(defun %unref (pointer)
  (when (and pointer (not (cffi:null-pointer-p pointer)))
    (%g-object-unref pointer)))

(defclass printer-settings ()
  ((print-settings :initarg :print-settings :reader %settings-print-settings)
   (page-setup :initarg :page-setup :reader %settings-page-setup)
   (printer :initarg :printer :reader %settings-printer)
   (closed-p :initform nil :accessor settings-closed-p)))

(defun %make-settings (print-settings page-setup printer)
  (make-instance 'printer-settings
                 :print-settings print-settings
                 :page-setup page-setup
                 :printer printer))

(defun close-settings (settings)
  "Release native resources owned by SETTINGS; repeated calls are safe."
  (check-type settings printer-settings)
  (unless (settings-closed-p settings)
    (%unref (%settings-print-settings settings))
    (%unref (%settings-page-setup settings))
    (%unref (%settings-printer settings))
    (setf (settings-closed-p settings) t))
  settings)

(defun %ensure-open-settings (settings)
  (when settings
    (check-type settings printer-settings)
    (when (settings-closed-p settings)
      (%bad-argument :settings "these printer settings have already been closed."))))

(defun settings-port-name (settings)
  "The name of the port the printer of SETTINGS is attached to, or NIL.

Always NIL here: GTK describes a destination by printer, backend and capability
flags and exposes no port name, so this backend has nothing to answer.  A caller
that uses the port to detect a queue whose own job dialog would appear must
treat NIL as \"no such queue\"."
  (check-type settings printer-settings)
  (%ensure-open-settings settings)
  nil)

(defstruct printer-search
  target
  first
  match)

(defvar *printer-search-table* (make-hash-table :test #'eql))

(cffi:defcallback %enumerate-printer-callback :int
    ((printer :pointer) (data :pointer))
  (let ((state (gethash (cffi:pointer-address data) *printer-search-table*)))
    (if (null state)
        0
        (let ((name (%foreign-string (%gtk-printer-name printer))))
          (unless (printer-search-first state)
            (setf (printer-search-first state) (%g-object-ref printer)))
          (cond
            ((and (printer-search-target state)
                  name
                  (string= (printer-search-target state) name))
             (setf (printer-search-match state) (%g-object-ref printer))
             1)
            ((and (null (printer-search-target state))
                  (plusp (%gtk-printer-default-p printer)))
             (setf (printer-search-match state) (%g-object-ref printer))
             1)
            (t 0))))))

(defun %find-printer (&optional name)
  (%ensure-gtk)
  (let ((token (cffi:foreign-alloc :uint8 :count 1))
        (state (make-printer-search :target name)))
    (unwind-protect
         (progn
           (setf (gethash (cffi:pointer-address token) *printer-search-table*) state)
           (%gtk-enumerate-printers (cffi:callback %enumerate-printer-callback)
                                    token (cffi:null-pointer) 1)
           (let ((match (printer-search-match state))
                 (first (printer-search-first state)))
             (cond
               (match
                ;; FIRST owns one reference even when it designates the same
                ;; GtkPrinter as MATCH.  MATCH owns the reference returned to
                ;; the caller, so FIRST must always be released here.
                (when first
                  (%unref first))
                match)
               ((and (null name) first) first)
               (t
                (%unref first)
                nil))))
      (remhash (cffi:pointer-address token) *printer-search-table*)
      (cffi:foreign-free token))))

(defun %printer-name-string (printer)
  (%foreign-string (%gtk-printer-name printer)))

(defun %default-page-setup-for-printer (printer)
  "Return an owned GtkPageSetup for PRINTER, with GTK's locale default fallback.

Physical/CUPS printers may expose a printer-specific default page setup. GTK's
virtual Print to File backend does not; in that case GTK_PAGE_SETUP_NEW is the
native locale-aware fallback and keeps PAPER-PRINT out of paper-size policy."
  (let ((page (%gtk-printer-default-page printer)))
    (if (cffi:null-pointer-p page)
        (%gtk-page-setup-new)
        page)))

(defun default-printer-settings ()
  "Return native GTK settings for the default available printer.

GTK may expose only its virtual 'Print to File' printer on machines without a
configured CUPS queue; that printer is still a native GtkPrinter and is a valid
fallback for this isolated backend."
  (%ensure-gtk)
  (let ((printer (%find-printer)))
    (unless printer
      (%fail :default-printer "GTK reported no printer."))
    (let ((print-settings (%gtk-print-settings-new))
          (page-setup (%default-page-setup-for-printer printer))
          (transferred nil))
      (unwind-protect
           (progn
             (%gtk-print-settings-set-printer print-settings
                                              (%printer-name-string printer))
             (setf transferred t)
             (%make-settings print-settings page-setup printer))
        (unless transferred
          (%unref print-settings)
          (%unref page-setup)
          (%unref printer))))))

(defun %base-dialog-values (settings)
  (%ensure-open-settings settings)
  (values (if settings
              (%gtk-print-settings-copy (%settings-print-settings settings))
              (%gtk-print-settings-new))
          (if settings
              (%gtk-page-setup-copy (%settings-page-setup settings))
              (%gtk-page-setup-new))))

(defun select-printer (&key settings owner)
  "Display GTK's native Unix Print dialog and return settings and acceptance.

OWNER is accepted for API parity and not passed to GTK: a native window handle of
the caller is not a GtkWindow."
  (declare (ignore owner))
  (%ensure-gtk)
  (%ensure-open-settings settings)
  (multiple-value-bind (base-settings base-page) (%base-dialog-values settings)
    (let ((dialog (cffi:null-pointer)))
      (unwind-protect
           (progn
             (setf dialog (%gtk-print-dialog-new "Print" (cffi:null-pointer)))
             (%gtk-print-dialog-set-settings dialog base-settings)
             (%gtk-print-dialog-set-page dialog base-page)
             (%gtk-print-dialog-embed-page-setup dialog 1)
             (if (/= (%run-dialog dialog) +gtk-response-ok+)
                 (values settings nil)
                 (let ((printer (%gtk-print-dialog-printer dialog)))
                   (when (cffi:null-pointer-p printer)
                     (%fail :print-dialog "GTK accepted the dialog without a printer."))
                   (let ((accepted-settings (%gtk-print-dialog-get-settings dialog))
                         (accepted-page (%gtk-page-setup-copy
                                         (%gtk-print-dialog-get-page dialog)))
                         (accepted-printer (%g-object-ref printer)))
                     (values (%make-settings accepted-settings accepted-page
                                             accepted-printer)
                             t)))))
        (unless (cffi:null-pointer-p dialog)
          (%gtk-widget-destroy dialog)
          (loop while (plusp (%g-main-context-iteration (cffi:null-pointer) 0))))
        (%unref base-settings)
        (%unref base-page)))))

(defun page-setup (&key owner settings)
  "Display GTK's native Unix Page Setup dialog.

Cancel returns the caller's SETTINGS and NIL.  Acceptance returns a fresh
PRINTER-SETTINGS object whose GtkPrintSettings/GtkPageSetup are owned by the
caller until CLOSE-SETTINGS.  OWNER is accepted and not passed to GTK."
  (declare (ignore owner))
  (%ensure-gtk)
  (%ensure-open-settings settings)
  (multiple-value-bind (base-settings base-page) (%base-dialog-values settings)
    (let ((dialog (cffi:null-pointer)))
      (unwind-protect
           (progn
             (setf dialog (%gtk-page-setup-dialog-new "Page Setup"
                                                      (cffi:null-pointer)))
             (%gtk-page-setup-dialog-set-settings dialog base-settings)
             (%gtk-page-setup-dialog-set-page dialog base-page)
             (if (/= (%run-dialog dialog) +gtk-response-ok+)
                 (values settings nil)
                 (let* ((dialog-settings (%gtk-page-setup-dialog-get-settings dialog))
                        (accepted-settings
                          (if (cffi:null-pointer-p dialog-settings)
                              (%gtk-print-settings-copy base-settings)
                              (%gtk-print-settings-copy dialog-settings)))
                        (accepted-page
                          (%gtk-page-setup-copy (%gtk-page-setup-dialog-get-page dialog)))
                        (printer-name-pointer
                          (%gtk-print-settings-get-printer accepted-settings))
                        (printer-name (%foreign-string printer-name-pointer))
                        (printer (or (and printer-name (%find-printer printer-name))
                                     (and settings
                                          (%ref-or-null (%settings-printer settings)))
                                     (%find-printer))))
                   (unless printer
                     (%unref accepted-settings)
                     (%unref accepted-page)
                     (%fail :page-setup "GTK reported no printer."))
                   (values (%make-settings accepted-settings accepted-page printer) t))))
        (unless (cffi:null-pointer-p dialog)
          (%gtk-widget-destroy dialog)
          (loop while (plusp (%g-main-context-iteration (cffi:null-pointer) 0))))
        (%unref base-settings)
        (%unref base-page)))))

(defun %page-setup-metadata (page-setup dpi)
  (let* ((paper-size (%gtk-page-paper-size page-setup))
         (paper-name (and (not (cffi:null-pointer-p paper-size))
                          (%foreign-string (%gtk-paper-size-name paper-size)))))
    (list :backend :gtk3
          :paper (or paper-name :unknown)
          :paper-mm (list (%gtk-paper-width page-setup +gtk-unit-mm+)
                          (%gtk-paper-height page-setup +gtk-unit-mm+))
          :margins-mm (list (%gtk-left-margin page-setup +gtk-unit-mm+)
                            (%gtk-top-margin page-setup +gtk-unit-mm+)
                            (%gtk-right-margin page-setup +gtk-unit-mm+)
                            (%gtk-bottom-margin page-setup +gtk-unit-mm+))
          :dpi-x dpi :dpi-y dpi :unit :pixel)))

(defun paper-geometry (&optional settings)
  "Return printable page geometry without opening UI.

With no SETTINGS this follows the same policy as the Windows backend: resolve
the current default native printer first, use its page setup when available,
and fall back to GTK's locale-aware page setup only if no printer can be
resolved. GTK stores page geometry physically. When the print settings expose a
printer resolution we return device pixels at that resolution; otherwise 72 dpi
is used as an exact point-to-device representation. Metadata always carries the
matching DPI, so callers recover the same physical/logical page size."
  (%ensure-gtk)
  (%ensure-open-settings settings)
  (let ((owned-settings nil)
        (fallback-page nil))
    (unwind-protect
         (let* ((effective-settings
                  (or settings
                      (handler-case
                          (setf owned-settings (default-printer-settings))
                        (paper-print-backend-error () nil))))
                (page-setup
                  (if effective-settings
                      (%settings-page-setup effective-settings)
                      (setf fallback-page (%gtk-page-setup-new))))
                (resolution
                  (and effective-settings
                       (%gtk-print-settings-resolution
                        (%settings-print-settings effective-settings))))
                (dpi (if (and resolution (plusp resolution)) resolution 72))
                (width-points (%gtk-page-width page-setup +gtk-unit-points+))
                (height-points (%gtk-page-height page-setup +gtk-unit-points+))
                (metadata (%page-setup-metadata page-setup dpi)))
           (values (max 1 (round (* width-points dpi) 72d0))
                   (max 1 (round (* height-points dpi) 72d0))
                   (if effective-settings
                       metadata
                       (append metadata (list :fallback :gtk-default-page)))))
      (when owned-settings (close-settings owned-settings))
      (%unref fallback-page))))

(defun %flatten-channel (channel alpha)
  (truncate (+ (* channel alpha) (* 255 (- 255 alpha)) 127) 255))

(defun %copy-page-to-cairo-data (page data)
  "Normalize PAGE to opaque native-endian Cairo ARGB32 in DATA."
  (let ((width (raster-page-width page))
        (height (raster-page-height page)))
    (dotimes (y height)
      (let ((source-y (if (eq (raster-page-origin page) :top-left)
                          y (- height y 1))))
        (dotimes (x width)
          (let* ((source (+ (* source-y (raster-page-stride page)) (* x 4)))
                 (alpha (aref (raster-page-data page) (+ source 3)))
                 (red (%flatten-channel (aref (raster-page-data page) source) alpha))
                 (green (%flatten-channel
                         (aref (raster-page-data page) (+ source 1)) alpha))
                 (blue (%flatten-channel
                        (aref (raster-page-data page) (+ source 2)) alpha))
                 (pixel (logior #xff000000
                                (ash red 16)
                                (ash green 8)
                                blue)))
            (setf (cffi:mem-aref data :uint32 (+ (* y width) x)) pixel)))))))

(defun %draw-raster-page (context page page-setup)
  "Draw one raster PAGE onto CONTEXT using the same top-left aspect-fit as GDI."
  (check-type page raster-page)
  (let* ((width (raster-page-width page))
         (height (raster-page-height page))
         (count (* width height))
         (data (cffi:foreign-alloc :uint32 :count count))
         (image (cffi:null-pointer)))
    (unwind-protect
         (progn
           (%copy-page-to-cairo-data page data)
           (setf image (%cairo-image-surface-for-data
                        data +cairo-format-argb32+ width height (* width 4)))
           (unless (zerop (%cairo-surface-status image))
             (%fail :cairo-image-surface (%cairo-surface-status image)))
           (let* ((left (%gtk-left-margin page-setup +gtk-unit-points+))
                  (top (%gtk-top-margin page-setup +gtk-unit-points+))
                  (printable-width (%gtk-page-width page-setup +gtk-unit-points+))
                  (printable-height (%gtk-page-height page-setup +gtk-unit-points+))
                  (scale (min (/ printable-width
                                 (coerce (raster-page-logical-width page) 'double-float))
                              (/ printable-height
                                 (coerce (raster-page-logical-height page) 'double-float))))
                  (destination-width (* (raster-page-logical-width page) scale))
                  (destination-height (* (raster-page-logical-height page) scale)))
             (%cairo-save context)
             (unwind-protect
                  (progn
                    (%cairo-translate context left top)
                    (%cairo-scale context
                                  (/ (coerce destination-width 'double-float) width)
                                  (/ (coerce destination-height 'double-float) height))
                    (%cairo-rectangle context 0d0 0d0
                                      (coerce width 'double-float)
                                      (coerce height 'double-float))
                    (%cairo-clip context)
                    (%cairo-set-source-surface context image 0d0 0d0)
                    (%cairo-paint context))
               (%cairo-restore context))))
      (unless (cffi:null-pointer-p image)
        (%cairo-surface-destroy image))
      (cffi:foreign-free data))))

(defstruct job-completion
  (done-p nil)
  error)

(defvar *job-completion-table* (make-hash-table :test #'eql))

(cffi:defcallback %print-job-complete :void
    ((job :pointer) (data :pointer) (error :pointer))
  (declare (ignore job))
  (let ((state (gethash (cffi:pointer-address data) *job-completion-table*)))
    (when state
      (setf (job-completion-error state)
            (unless (cffi:null-pointer-p error) (%g-error-message error))
            (job-completion-done-p state) t))))

(defconstant +print-job-send-timeout-seconds+ 60d0)

(defun %monotonic-seconds ()
  "Return elapsed process real time in seconds for deadline calculations."
  (/ (coerce (get-internal-real-time) 'double-float)
     (coerce internal-time-units-per-second 'double-float)))

(defun %send-job-synchronously (job)
  "Submit JOB and wait at most +PRINT-JOB-SEND-TIMEOUT-SECONDS+ seconds.

The deadline uses the implementation's monotonic internal real-time clock.
The GLib context is pumped non-blockingly so a missing GTK completion callback
cannot trap the caller inside G_MAIN_CONTEXT_ITERATION forever.  Timeout is
reported as PAPER-PRINT-BACKEND-ERROR with operation :PRINT-JOB-SEND-TIMEOUT."
  (let ((token (cffi:foreign-alloc :uint8 :count 1))
        (state (make-job-completion)))
    (unwind-protect
         (progn
           (setf (gethash (cffi:pointer-address token) *job-completion-table*) state)
           (%gtk-print-job-send job (cffi:callback %print-job-complete)
                                token (cffi:null-pointer))
           (let ((deadline (+ (%monotonic-seconds)
                              +print-job-send-timeout-seconds+)))
             (loop until (job-completion-done-p state)
                   do (%g-main-context-iteration (cffi:null-pointer) 0)
                      (when (>= (%monotonic-seconds) deadline)
                        (%fail :print-job-send-timeout
                               (format nil "GTK print job completion callback did not arrive within ~,1F seconds."
                                       +print-job-send-timeout-seconds+)))
                      (unless (job-completion-done-p state)
                        (sleep 0.01d0))))
           (when (job-completion-error state)
             (%fail :print-job-send (job-completion-error state)))
           t)
      (remhash (cffi:pointer-address token) *job-completion-table*)
      (cffi:foreign-free token))))

(defun %filename-uri (pathname)
  (let ((native (namestring (uiop:ensure-absolute-pathname pathname))))
    (cffi:with-foreign-object (error :pointer)
      (setf (cffi:mem-ref error :pointer) (cffi:null-pointer))
      (let ((uri (%g-filename-to-uri native (cffi:null-pointer) error)))
        (when (cffi:null-pointer-p uri)
          (let ((native-error (cffi:mem-ref error :pointer)))
            (unwind-protect
                 (%fail :filename-to-uri (%g-error-message native-error))
              (unless (cffi:null-pointer-p native-error)
                (%g-error-free native-error)))))
        (unwind-protect (%foreign-string uri)
          (%g-free uri))))))

(defun %settings-for-printer-name (printer-name settings)
  (unless (and (stringp printer-name) (plusp (length printer-name)))
    (%bad-argument :printer-name "expected a non-empty string."))
  (let ((printer (%find-printer printer-name)))
    (unless printer
      (%fail :find-printer printer-name))
    (let ((print-settings (if settings
                              (%gtk-print-settings-copy (%settings-print-settings settings))
                              (%gtk-print-settings-new)))
          (page-setup (if settings
                          (%gtk-page-setup-copy (%settings-page-setup settings))
                          (%gtk-page-setup-new)))
          (transferred nil))
      (unwind-protect
           (progn
             (%gtk-print-settings-set-printer print-settings printer-name)
             (setf transferred t)
             (%make-settings print-settings page-setup printer))
        (unless transferred
          (%unref print-settings)
          (%unref page-setup)
          (%unref printer))))))

(defun %run-native-job (page-count page-function title settings output)
  "Render PAGE-COUNT raster pages directly into GTK's native print surface.

OUTPUT is applied to a temporary copy of GtkPrintSettings, analogous to the
Windows backend passing DOCINFOW.lpszOutput to the job rather than using it to
select a printer. Caller-owned SETTINGS are never mutated."
  (let ((job (cffi:null-pointer))
        (context (cffi:null-pointer))
        (surface (cffi:null-pointer))
        (job-print-settings nil))
    (unwind-protect
         (progn
           (setf job-print-settings
                 (if output
                     (%gtk-print-settings-copy (%settings-print-settings settings))
                     (%settings-print-settings settings)))
           (when output
             (%gtk-print-settings-set job-print-settings "output-uri"
                                      (%filename-uri output)))
           (setf job (%gtk-print-job-new title
                                         (%settings-printer settings)
                                         job-print-settings
                                         (%settings-page-setup settings)))
           (when (cffi:null-pointer-p job)
             (%fail :print-job-new 0))
           (cffi:with-foreign-object (error :pointer)
             (setf (cffi:mem-ref error :pointer) (cffi:null-pointer))
             (setf surface (%gtk-print-job-surface job error))
             (when (cffi:null-pointer-p surface)
               (let ((native-error (cffi:mem-ref error :pointer)))
                 (unwind-protect
                      (%fail :print-job-surface (%g-error-message native-error))
                   (unless (cffi:null-pointer-p native-error)
                     (%g-error-free native-error))))))
           (setf context (%cairo-create surface))
           (unless (zerop (%cairo-status context))
             (%fail :cairo-create (%cairo-status context)))
           (dotimes (index page-count)
             (%draw-raster-page context (funcall page-function (1+ index))
                                (%settings-page-setup settings))
             (%cairo-show-page context)
             (unless (zerop (%cairo-status context))
               (%fail :cairo-show-page (%cairo-status context))))
           (%cairo-destroy context)
           (setf context (cffi:null-pointer))
           (%cairo-surface-finish surface)
           (unless (zerop (%cairo-surface-status surface))
             (%fail :cairo-surface-finish (%cairo-surface-status surface)))
           (%send-job-synchronously job)
           t)
      (unless (cffi:null-pointer-p context)
        (%cairo-destroy context))
      ;; SURFACE is owned by GtkPrintJob (transfer none); unref JOB owns cleanup.
      (unless (cffi:null-pointer-p job)
        (%unref job))
      (when (and output job-print-settings
                 (not (cffi:null-pointer-p job-print-settings)))
        (%unref job-print-settings)))))

(defun %delete-output-on-failure (output)
  (when (and output (probe-file output))
    (ignore-errors (delete-file output))))

(defun %print-image-pages (page-count page-function title settings
                           show-dialog output printer-name owner)
  (let ((owned-settings nil)
        (result-settings nil)
        (accepted nil)
        (success nil))
    (unwind-protect
         (progn
           (cond
             (show-dialog
              (multiple-value-setq (result-settings accepted)
                (select-printer :settings settings :owner owner))
              (unless accepted
                (return-from %print-image-pages (values :cancelled nil settings))))
             (printer-name
              (setf owned-settings (%settings-for-printer-name printer-name settings)
                    result-settings settings
                    accepted t))
             (settings
              (setf result-settings settings accepted t))
             (t
              (setf owned-settings (default-printer-settings)
                    result-settings nil
                    accepted t)))
           (let ((job-settings (or (and show-dialog result-settings)
                                   owned-settings settings)))
             (%run-native-job page-count page-function title job-settings output))
           (setf success t)
           (values :printed nil
                   (if show-dialog result-settings settings)))
      (unless success
        (%delete-output-on-failure output))
      (when (and show-dialog result-settings (not success)
                 (not (eq result-settings settings)))
        (close-settings result-settings))
      (when owned-settings
        (close-settings owned-settings)))))

(defun print-image-pages (page-count page-function
                          &key owner (title "Common Lisp document") settings
                            (show-dialog t) output printer-name)
  "Print raster pages through GTK's native Unix printing pipeline.

PAGE-FUNCTION is called exactly once per page, in ascending order, only after a
print dialog has been accepted (when SHOW-DIALOG is true).  Each page is
flattened from straight-alpha RGBA to opaque Cairo ARGB32 and drawn directly to
the GtkPrintJob surface; PAPER-PRINT never creates an intermediate PDF/PS file.

OUTPUT is passed to the native job settings and never selects a printer.
PRINTER-NAME selects a native GtkPrinter when SHOW-DIALOG is NIL, matching the
Windows separation between printer selection and DOCINFOW.lpszOutput. Backend failures return :FAILED;
caller conditions from PAGE-FUNCTION propagate unchanged."
  (check-type page-count (integer 1))
  (check-type page-function function)
  (%ensure-open-settings settings)
  (when (and show-dialog printer-name)
    (%bad-argument :printer-name
                   "it is only valid when SHOW-DIALOG is NIL."))
  (handler-case
      (%print-image-pages page-count page-function title settings
                          show-dialog output printer-name owner)
    (paper-print-backend-error (condition)
      (%delete-output-on-failure output)
      (values :failed condition settings))))

(defun print-pages (page-count page-function
                    &key (title "Common Lisp document") settings output
                      printer-name abort-hook (on-main-thread #'funcall))
  "Not implemented by this backend; see the Windows one for the contract.

Caller-drawn pages need a device the caller can draw into with the platform's
own calls.  GTK hands its own Cairo context to a draw signal instead, so there
is nothing here to hand over, and a raster job through PRINT-IMAGE-PAGES is what
this backend offers.  Signals rather than returning a status: a caller reaching
this is asking the backend for something it does not do."
  (declare (ignore page-count page-function title settings output printer-name
                   abort-hook on-main-thread))
  (%bad-argument :backend "PRINT-PAGES is not implemented by the GTK backend."))

(defun pdf-page-from-rgba (data width height top-down)
  "Not implemented by this backend; see the macOS one for the contract."
  (declare (ignore data width height top-down))
  (%bad-argument :backend
                 "PDF-PAGE-FROM-RGBA is not implemented by the GTK backend."))

(defun pdf-page-reference (page)
  "Not implemented by this backend; see the macOS one for the contract."
  (declare (ignore page))
  (%bad-argument :backend
                 "PDF-PAGE-REFERENCE is not implemented by the GTK backend."))
