(in-package #:os-fonts.linux)

(cffi:define-foreign-library gtk3 (t "libgtk-3.so.0"))
(cffi:define-foreign-library gobject (t "libgobject-2.0.so.0"))
(cffi:define-foreign-library glib (t "libglib-2.0.so.0"))
(cffi:define-foreign-library fontconfig (t "libfontconfig.so.1"))

(cffi:defcfun ("gtk_disable_setlocale" %gtk-disable-setlocale) :void)
(cffi:defcfun ("gtk_init_check" %gtk-init-check) :boolean
  (argc :pointer) (argv :pointer))
(cffi:defcfun ("gtk_settings_get_default" %gtk-settings-get-default) :pointer)
(cffi:defcfun ("g_free" %g-free) :void (mem :pointer))

(cffi:defcfun ("FcInit" %fc-init) :boolean)
(cffi:defcfun ("FcNameParse" %fc-name-parse) :pointer (name :string))
(cffi:defcfun ("FcConfigSubstitute" %fc-config-substitute) :boolean
  (config :pointer) (pattern :pointer) (kind :int))
(cffi:defcfun ("FcDefaultSubstitute" %fc-default-substitute) :void
  (pattern :pointer))
(cffi:defcfun ("FcFontMatch" %fc-font-match) :pointer
  (config :pointer) (pattern :pointer) (result :pointer))
(cffi:defcfun ("FcPatternGetString" %fc-pattern-get-string) :int
  (pattern :pointer) (object :string) (id :int) (value :pointer))
(cffi:defcfun ("FcPatternDestroy" %fc-pattern-destroy) :void
  (pattern :pointer))

(defconstant +fc-match-pattern+ 0)
(defconstant +fc-result-match+ 0)

(defclass linux (backend)
  ((initialized-p :initform nil :accessor %initialized-p)))

(defun %ensure-native (backend)
  (unless (%initialized-p backend)
    (cffi:use-foreign-library glib)
    (cffi:use-foreign-library gobject)
    (cffi:use-foreign-library gtk3)
    (cffi:use-foreign-library fontconfig)
    (%gtk-disable-setlocale)
    (unless (%gtk-init-check (cffi:null-pointer) (cffi:null-pointer))
      (error 'os-fonts:os-fonts-error))
    (unless (%fc-init)
      (error 'os-fonts:os-fonts-error))
    (setf (%initialized-p backend) t))
  backend)

(defun %settings ()
  (let ((p (%gtk-settings-get-default)))
    (when (cffi:null-pointer-p p)
      (error 'os-fonts:os-fonts-error))
    p))

(defun %gobject-get-string (object property)
  (cffi:with-foreign-object (out :pointer)
    (setf (cffi:mem-ref out :pointer) (cffi:null-pointer))
    (cffi:foreign-funcall "g_object_get"
                          :pointer object
                          :string property
                          :pointer out
                          :pointer (cffi:null-pointer)
                          :void)
    (let ((p (cffi:mem-ref out :pointer)))
      (unless (cffi:null-pointer-p p)
        (unwind-protect
             (cffi:foreign-string-to-lisp p :encoding :utf-8)
          (%g-free p))))))

(defun %gobject-get-int (object property)
  (cffi:with-foreign-object (out :int)
    (setf (cffi:mem-ref out :int) 0)
    (cffi:foreign-funcall "g_object_get"
                          :pointer object
                          :string property
                          :pointer out
                          :pointer (cffi:null-pointer)
                          :void)
    (cffi:mem-ref out :int)))

(defun %gtk-xft-dpi->dpi (fixed)
  "Convert GtkSettings gtk-xft-dpi (1024ths of a DPI) to logical DPI.
GTK uses non-positive values for an unset/default DPI; NIL also represents an
unavailable property in tests and diagnostics.  In those cases GTK/Pango's
portable baseline is 96 DPI."
  (if (and (realp fixed) (plusp fixed))
      (/ (coerce fixed 'double-float) 1024d0)
      96d0))

;; Kept internal for diagnostics. Production consumers should never mutate GtkSettings.
(defun %gobject-set-string (object property value)
  (cffi:foreign-funcall "g_object_set"
                        :pointer object
                        :string property
                        :string value
                        :pointer (cffi:null-pointer)
                        :void))

(defun %split-spaces (string)
  (loop with start = 0
        for end = (position #\Space string :start start)
        for part = (string-trim '(#\Space #\Tab) (subseq string start end))
        when (plusp (length part)) collect part
        while end do (setf start (1+ end))))

(defun %numeric-token-p (token)
  (and token (plusp (length token))
       (find-if #'digit-char-p token)
       (every (lambda (c) (or (digit-char-p c) (char= c #\.))) token)))

(defun %parse-font-name (string)
  "Parse GtkSettings gtk-font-name: FAMILY [STYLE...] SIZE."
  (let* ((tokens (%split-spaces (or string "")))
         (size 10d0)
         (weight :regular)
         (slant :roman))
    (when (and tokens (%numeric-token-p (car (last tokens))))
      (let ((n (read-from-string (car (last tokens)) nil nil)))
        (when (realp n) (setf size (coerce n 'double-float))))
      (setf tokens (butlast tokens)))
    (loop while tokens
          for word = (string-downcase (car (last tokens)))
          while (member word '("normal" "roman" "italic" "oblique" "regular"
                               "medium" "bold" "semibold" "semi-bold" "demibold"
                               "light" "thin" "black" "heavy") :test #'string=)
          do (when (member word '("bold" "semibold" "semi-bold" "demibold"
                                  "black" "heavy") :test #'string=)
               (setf weight :bold))
             (when (member word '("italic" "oblique") :test #'string=)
               (setf slant :italic))
             (setf tokens (butlast tokens)))
    (values (if tokens (format nil "~{~A~^ ~}" tokens) "Sans")
            size weight slant)))

(defun %fontconfig-family (family)
  "Resolve a Linux generic/family name using fontconfig, without spawning fc-match."
  (let ((pattern (%fc-name-parse family)))
    (when (cffi:null-pointer-p pattern)
      (return-from %fontconfig-family family))
    (unwind-protect
         (progn
           (%fc-config-substitute (cffi:null-pointer) pattern +fc-match-pattern+)
           (%fc-default-substitute pattern)
           (cffi:with-foreign-object (result :int)
             (let ((match (%fc-font-match (cffi:null-pointer) pattern result)))
               (when (cffi:null-pointer-p match)
                 (return-from %fontconfig-family family))
               (unwind-protect
                    (cffi:with-foreign-object (out :pointer)
                      (setf (cffi:mem-ref out :pointer) (cffi:null-pointer))
                      (if (= +fc-result-match+
                             (%fc-pattern-get-string match "family" 0 out))
                          (let ((p (cffi:mem-ref out :pointer)))
                            (if (cffi:null-pointer-p p)
                                family
                                (cffi:foreign-string-to-lisp p :encoding :utf-8)))
                          family))
                 (%fc-pattern-destroy match)))))
      (%fc-pattern-destroy pattern))))

(defun %copy-role (role spec &key source)
  (os-fonts::make-font-spec
   :role role
   :family (font-spec-family spec)
   :native-family (font-spec-native-family spec)
   :size (font-spec-size spec)
   :weight (font-spec-weight spec)
   :slant (font-spec-slant spec)
   :source (or source (font-spec-source spec))))

(defmethod os-fonts::query-state ((backend linux))
  (%ensure-native backend)
  (let* ((settings (%settings))
         (raw (%gobject-get-string settings "gtk-font-name"))
         (dpi-fixed (%gobject-get-int settings "gtk-xft-dpi"))
         (dpi (%gtk-xft-dpi->dpi dpi-fixed)))
    (multiple-value-bind (native-family size weight slant)
        (%parse-font-name raw)
      (let* ((family (%fontconfig-family native-family))
             (fixed-family (%fontconfig-family "monospace"))
             (system (os-fonts::make-font-spec
                      :role :system :family family :native-family native-family
                      :size size :weight weight :slant slant
                      :source :gtk-settings))
             (fixed (os-fonts::make-font-spec
                     :role :system-fixed :family fixed-family :native-family "monospace"
                     :size size :weight :regular :slant :roman
                     :source :gtk-settings+fontconfig)))
        ;; GTK gives these roles no font of their own: they inherit the same
        ;; GtkSettings default, so each is stamped with its own role and value.
        (os-fonts::make-font-state
         :logical-dpi dpi
         :source :gtk3
         ;; X11/Wayland have no per-process DPI virtualization to distrust:
         ;; gtk-xft-dpi is what it is.  The slot exists because Windows DOES
         ;; virtualize, and a consumer must be able to ask.
         :dpi-awareness :not-applicable
         ;; GtkSettings exposes no menu-bar or caption geometry -- those belong
         ;; to the window manager and the widget theme, not to a settings key.
         ;; Absence is stated explicitly so a consumer can tell "this platform
         ;; does not provide it" from "this backend forgot to fill it in".
         :metrics (list :menu-bar-height nil
                        :menu-item-height nil
                        :menu-item-width nil
                        :caption-height nil
                        :sm-caption-height nil
                        :border-width nil
                        :padded-border-width nil
                        :scroll-width nil
                        :scroll-height nil)
         :fonts (list (cons :system system)
                      (cons :system-fixed fixed)
                      (cons :menu (%copy-role :menu system))
                      (cons :control (%copy-role :control system))
                      (cons :dialog-default (%copy-role :dialog-default system))
                      (cons :label (%copy-role :label system))
                      (cons :tooltip (%copy-role :tooltip system))
                      (cons :text (%copy-role :text system))))))))
