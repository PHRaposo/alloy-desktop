(in-package #:os-fonts.windows)

;; The Windows adapter mirrors the native role split exposed by NONCLIENTMETRICS.
;; Numeric results must never be inferred from another platform.

(cffi:define-foreign-library user32 (t "user32.dll"))
(cffi:define-foreign-library gdi32 (t "gdi32.dll"))
(cffi:define-foreign-library advapi32 (t "advapi32.dll"))

(defconstant +spi-getnonclientmetrics+ #x0029)
(defconstant +system-fixed-font+ 16)
(defconstant +default-gui-font+ 17)
(defconstant +sm-cymenu+ 15)
(defconstant +tmpf-fixed-pitch+ #x01)  ; win32 quirk: bit CLEAR means fixed pitch
(defconstant +tmpf-truetype+ #x04)
(defconstant +hkey-local-machine+ #x80000002)
(defconstant +rrf-rt-reg-sz+ #x00000002)
(defconstant +cleartype-natural-quality+ 6)
(defconstant +default-charset+ 1)

(cffi:defcstruct logfontw
  (height :long) (width :long) (escapement :long) (orientation :long)
  (weight :long) (italic :uint8) (underline :uint8) (strike-out :uint8)
  (char-set :uint8) (out-precision :uint8) (clip-precision :uint8)
  (quality :uint8) (pitch-and-family :uint8)
  (face-name :uint16 :count 32))

(cffi:defcstruct nonclientmetricsw
  (cb-size :uint)
  (border-width :int) (scroll-width :int) (scroll-height :int)
  (caption-width :int) (caption-height :int)
  (caption-font (:struct logfontw))
  (sm-caption-width :int) (sm-caption-height :int)
  (sm-caption-font (:struct logfontw))
  (menu-width :int) (menu-height :int)
  (menu-font (:struct logfontw))
  (status-font (:struct logfontw))
  (message-font (:struct logfontw))
  (padded-border-width :int))

(cffi:defcstruct textmetricw
  (height :long) (ascent :long) (descent :long)
  (internal-leading :long) (external-leading :long)
  (ave-char-width :long) (max-char-width :long)
  (weight :long) (overhang :long)
  (digitized-aspect-x :long) (digitized-aspect-y :long)
  (first-char :uint16) (last-char :uint16)
  (default-char :uint16) (break-char :uint16)
  (italic :uint8) (underlined :uint8) (struck-out :uint8)
  (pitch-and-family :uint8) (char-set :uint8))

(cffi:defcfun ("SystemParametersInfoW" %system-parameters-info-w) :boolean
  (action :uint) (param :uint) (data :pointer) (flags :uint))
(cffi:defcfun ("GetDpiForSystem" %get-dpi-for-system) :uint)
(cffi:defcfun ("GetStockObject" %get-stock-object) :pointer (object :int))
(cffi:defcfun ("GetObjectW" %get-object-w) :int
  (object :pointer) (size :int) (data :pointer))
(cffi:defcfun ("GetSystemMetrics" %get-system-metrics) :int (index :int))
(cffi:defcfun ("IsProcessDPIAware" %is-process-dpi-aware) :boolean)
(cffi:defcfun ("GetThreadDpiAwarenessContext" %get-thread-dpi-awareness-context) :pointer)
(cffi:defcfun ("GetAwarenessFromDpiAwarenessContext" %get-awareness-from-context) :int
  (context :pointer))
(cffi:defcfun ("CreateCompatibleDC" %create-compatible-dc) :pointer (dc :pointer))
(cffi:defcfun ("DeleteDC" %delete-dc) :boolean (dc :pointer))
(cffi:defcfun ("SelectObject" %select-object) :pointer (dc :pointer) (obj :pointer))
(cffi:defcfun ("DeleteObject" %delete-object) :boolean (obj :pointer))
(cffi:defcfun ("CreateFontIndirectW" %create-font-indirect-w) :pointer (lf :pointer))
(cffi:defcfun ("GetTextMetricsW" %get-text-metrics-w) :boolean (dc :pointer) (tm :pointer))
(cffi:defcfun ("GetTextFaceW" %get-text-face-w) :int
  (dc :pointer) (count :int) (buf :pointer))
(cffi:defcfun ("RegGetValueW" %reg-get-value-w) :long
  (key :pointer) (subkey :pointer) (value :pointer) (flags :uint)
  (type :pointer) (data :pointer) (size :pointer))
(cffi:defcfun ("GetDC" %get-dc) :pointer (hwnd :pointer))
(cffi:defcfun ("ReleaseDC" %release-dc) :int
  (hwnd :pointer) (dc :pointer))
(cffi:defcfun ("CreateCompatibleBitmap" %create-compatible-bitmap) :pointer
  (dc :pointer) (width :int) (height :int))
(cffi:defcfun ("GetCharWidth32W" %get-char-width-32-w) :boolean
  (dc :pointer) (first-char :uint) (last-char :uint) (buffer :pointer))

(defclass windows (backend) ())

(defun %wstring-buffer (ptr count)
  (let ((chars (loop for i below count
                     for c = (cffi:mem-aref ptr :uint16 i)
                     until (zerop c) collect (code-char c))))
    (coerce chars 'string)))

(defun %logfont-face (ptr)
  (%wstring-buffer (cffi:foreign-slot-pointer ptr '(:struct logfontw) 'face-name) 32))

(defun %font-substitute (family)
  "Resolve FAMILY through the Windows FontSubstitutes registry key, if present."
  (cffi:with-foreign-strings ((subkey "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes"
                                     :encoding :utf-16le)
                              (value family :encoding :utf-16le))
    (cffi:with-foreign-object (bytes :uint32)
      (setf (cffi:mem-ref bytes :uint32) 0)
      (if (zerop (%reg-get-value-w (cffi:make-pointer +hkey-local-machine+)
                                   subkey value +rrf-rt-reg-sz+
                                   (cffi:null-pointer) (cffi:null-pointer) bytes))
          (let ((count (cffi:mem-ref bytes :uint32)))
            (cffi:with-foreign-object (buffer :uint8 count)
              (if (zerop (%reg-get-value-w (cffi:make-pointer +hkey-local-machine+)
                                           subkey value +rrf-rt-reg-sz+
                                           (cffi:null-pointer) buffer bytes))
                  (%wstring-buffer buffer (floor count 2))
                  family)))
          family))))

(defun %fill-logfont (lf family ppem bold italicp)
  "Fill LF with a native font request suitable for exact advance measurement."
  (dotimes (i (cffi:foreign-type-size '(:struct logfontw)))
    (setf (cffi:mem-aref lf :uint8 i) 0))
  (cffi:with-foreign-slots ((height weight italic char-set quality)
                            lf (:struct logfontw))
    (setf height (- ppem)
          weight (if bold 700 400)
          italic (if italicp 1 0)
          char-set +default-charset+
          quality +cleartype-natural-quality+))
  (let ((face (cffi:foreign-slot-pointer lf '(:struct logfontw) 'face-name)))
    (loop for i below (min 31 (length family))
          do (setf (cffi:mem-aref face :uint16 i)
                   (char-code (char family i))))))

(defun %call-with-text-dc (family ppem bold italic function)
  "Call FUNCTION with a colour GDI DC realizing the requested font exactly."
  (cffi:use-foreign-library user32)
  (cffi:use-foreign-library gdi32)
  (let ((screen (%get-dc (cffi:null-pointer))))
    (when (cffi:null-pointer-p screen)
      (return-from %call-with-text-dc nil))
    (unwind-protect
         (let ((dc (%create-compatible-dc screen))
               (bitmap (%create-compatible-bitmap screen 8 8)))
           (if (or (cffi:null-pointer-p dc) (cffi:null-pointer-p bitmap))
               (progn
                 (unless (cffi:null-pointer-p bitmap) (%delete-object bitmap))
                 (unless (cffi:null-pointer-p dc) (%delete-dc dc))
                 nil)
               (let ((old-bitmap (%select-object dc bitmap))
                     (font (cffi:null-pointer))
                     (old-font (cffi:null-pointer)))
                 (unwind-protect
                      (cffi:with-foreign-object (lf '(:struct logfontw))
                        (%fill-logfont lf family ppem bold italic)
                        (setf font (%create-font-indirect-w lf))
                        (unless (cffi:null-pointer-p font)
                          (setf old-font (%select-object dc font))
                          (cffi:with-foreign-object (buffer :uint16 64)
                            (%get-text-face-w dc 64 buffer)
                            (when (string-equal family (%wstring-buffer buffer 64))
                              (funcall function dc)))))
                   (unless (cffi:null-pointer-p old-font)
                     (%select-object dc old-font))
                   (unless (cffi:null-pointer-p font) (%delete-object font))
                   (%select-object dc old-bitmap)
                   (%delete-object bitmap)
                   (%delete-dc dc)))))
      (%release-dc (cffi:null-pointer) screen))))

(defmethod os-fonts::%native-advance-block
    ((backend windows) family ppem bold italic block)
  (declare (ignore backend))
  (%call-with-text-dc
   family ppem bold italic
   (lambda (dc)
     (let ((first (* block 256)))
       (cffi:with-foreign-object (buffer :int 256)
         (when (%get-char-width-32-w dc first (+ first 255) buffer)
           (let ((result (make-array 256 :element-type '(signed-byte 32))))
             (dotimes (i 256 result)
               (setf (aref result i) (cffi:mem-aref buffer :int i))))))))))

;;; ------------------------------------------------------------ GDI measuring

(defmacro %with-font-dc ((dc lf) &body body)
  "Select the LOGFONTW at LF into a scratch memory DC bound to DC, run BODY,
and release every GDI object -- the font is deselected before it is deleted."
  (let ((font (gensym "FONT")) (old (gensym "OLD")))
    `(let ((,dc (%create-compatible-dc (cffi:null-pointer)))
           (,font (%create-font-indirect-w ,lf)))
       (if (or (cffi:null-pointer-p ,dc) (cffi:null-pointer-p ,font))
           (progn (unless (cffi:null-pointer-p ,font) (%delete-object ,font))
                  (unless (cffi:null-pointer-p ,dc) (%delete-dc ,dc))
                  nil)
           (let ((,old (%select-object ,dc ,font)))
             (unwind-protect (progn ,@body)
               (%select-object ,dc ,old)
               (%delete-object ,font)
               (%delete-dc ,dc)))))))

(defun %text-metrics (lf)
  "(values TM-HEIGHT TM-INTERNAL-LEADING PITCH-AND-FAMILY REAL-FACE) for LF, or NIL."
  (%with-font-dc (dc lf)
    (cffi:with-foreign-object (tm '(:struct textmetricw))
      (when (%get-text-metrics-w dc tm)
        (cffi:with-foreign-slots ((height internal-leading pitch-and-family)
                                  tm (:struct textmetricw))
          (values height internal-leading pitch-and-family
                  (cffi:with-foreign-object (buf :uint16 64)
                    (let ((n (%get-text-face-w dc 64 buf)))
                      (declare (ignore n))
                      (%wstring-buffer buf 64)))))))))

(defun %logfont-point-size (ptr dpi &optional tm-height internal-leading)
  "Point size of the LOGFONTW at PTR.

A negative lfHeight already IS the character height, so it converts directly.
A POSITIVE lfHeight is a cell height that includes internal leading, and the
exact conversion needs TEXTMETRIC:

    pt = (tmHeight - tmInternalLeading) * 72 / dpi

The GDI stock SYSTEM_FIXED_FONT reports a positive lfHeight, so skipping this
case would hand consumers a role with no size at all."
  (let ((height (cffi:foreign-slot-value ptr '(:struct logfontw) 'height)))
    (cond ((minusp height) (* (- height) (/ 72d0 dpi)))
          ((zerop height) nil)
          (t (unless tm-height
               (multiple-value-setq (tm-height internal-leading)
                 (%text-metrics ptr)))
             (when tm-height
               (/ (* (- tm-height internal-leading) 72d0) dpi))))))

(defun %logfont->spec (role ptr dpi source)
  (multiple-value-bind (tm-height internal-leading pitch realized-face)
      (%text-metrics ptr)
    (declare (ignore pitch))
    (cffi:with-foreign-slots ((weight italic) ptr (:struct logfontw))
      (let* ((native-face (%logfont-face ptr))
             (face (%font-substitute (or realized-face native-face))))
      (os-fonts::make-font-spec
       :role role :family face :native-family native-face
       :size (%logfont-point-size ptr dpi tm-height internal-leading)
       :weight (if (>= weight 600) :bold :regular)
       :slant (if (zerop italic) :roman :italic)
       :source source)))))

(defun %role-alias (role spec)
  "SPEC re-stamped with ROLE.
Several roles resolve to the same native font here; sharing one spec object
between them would make FONT-SPEC-ROLE report the role it was built for
instead of the role that answered the lookup."
  (when spec
    (os-fonts::make-font-spec
     :role role
     :family (font-spec-family spec)
     :native-family (font-spec-native-family spec)
     :size (font-spec-size spec)
     :weight (font-spec-weight spec)
     :slant (font-spec-slant spec)
     :source (font-spec-source spec))))

(defun %slot-font (ncm slot role dpi)
  (%logfont->spec role
                  (cffi:foreign-slot-pointer ncm '(:struct nonclientmetricsw) slot)
                  dpi :nonclientmetrics))

;;; -------------------------------------------------- scalable fixed-pitch face

(defparameter *fixed-pitch-preference*
  '("Consolas" "Lucida Console" "Courier New")
  "Scalable fixed-pitch faces to try, best first.  Rebind to override.

Windows exposes no API that designates a scalable fixed-pitch UI font.  The one
OS-level fixed role is the GDI stock SYSTEM_FIXED_FONT, which resolves to the
raster face Fixedsys: it reports TrueType=NO, so it carries no outline for any
renderer that needs one, and its point size is not DPI-stable, because GDI
snaps to whichever raster strike exists.  A scalable face therefore has to be
picked, and the OS offers no ranking.

Every candidate is verified at query time -- it must resolve to ITSELF under
GetTextFaceW and report as TrueType and fixed pitch -- so this order is a
preference among faces that all pass the same objective test, never a
correctness decision.  A consumer that wants a different face rebinds this
variable.")

(defun %scalable-fixed-face (dpi size-pt)
  "First preference this Windows resolves to ITSELF and reports as a TrueType
fixed-pitch face. Returns NIL when none qualifies, so the caller can fall back."
  (cffi:with-foreign-object (lf '(:struct logfontw))
    (dolist (want *fixed-pitch-preference*)
      (dotimes (i (cffi:foreign-type-size '(:struct logfontw)))
        (setf (cffi:mem-aref lf :uint8 i) 0))
      (setf (cffi:foreign-slot-value lf '(:struct logfontw) 'height)
            (- (round (* (or size-pt 9) dpi) 72)))
      (let ((p (cffi:foreign-slot-pointer lf '(:struct logfontw) 'face-name)))
        (loop for i from 0 below (min 31 (length want))
              do (setf (cffi:mem-aref p :uint16 i) (char-code (char want i)))))
      ;; GDI substitutes silently, so trust GetTextFaceW, not the request.
      (multiple-value-bind (tm-height leading pitch face) (%text-metrics lf)
        (declare (ignore tm-height leading))
        (when (and face (string-equal face want)
                   (logtest pitch +tmpf-truetype+)
                   (not (logtest pitch +tmpf-fixed-pitch+)))
          (return-from %scalable-fixed-face face))))
    nil))

(defun %stock-fixed-spec (dpi)
  "The raw GDI stock SYSTEM_FIXED_FONT as a spec, kept for diagnostics only:
it is the OS's own fixed role, but raster and not DPI-stable."
  (let ((obj (%get-stock-object +system-fixed-font+)))
    (unless (cffi:null-pointer-p obj)
      (cffi:with-foreign-object (lf '(:struct logfontw))
        (when (plusp (%get-object-w obj (cffi:foreign-type-size '(:struct logfontw)) lf))
          (%logfont->spec :system-fixed lf dpi :gdi-stock-object))))))

(defun %dialog-default-spec (dpi)
  "The font GDI assigns to a dialog control that does not name a font."
  (let ((object (%get-stock-object +default-gui-font+)))
    (unless (cffi:null-pointer-p object)
      (cffi:with-foreign-object (lf '(:struct logfontw))
        (when (plusp (%get-object-w object
                                    (cffi:foreign-type-size '(:struct logfontw))
                                    lf))
          (%logfont->spec :dialog-default lf dpi :gdi-stock-object))))))

(defun %fixed-spec (dpi ui-spec)
  "The :SYSTEM-FIXED role: a SCALABLE fixed-pitch family at the OS UI point size.

Family: see *FIXED-PITCH-PREFERENCE*.  Size: the UI font's, because the stock
object's own size changes with DPI while the UI font's point size does not, and
at the unscaled 96 dpi reference the two agree exactly."
  (let* ((size (and ui-spec (os-fonts:font-spec-size ui-spec)))
         (face (%scalable-fixed-face dpi size)))
    (if face
        (os-fonts::make-font-spec
         :role :system-fixed :family face :native-family face :size size
         :weight :regular :slant :roman
         :source :nonclientmetrics+scalable-fixed)
        ;; Nothing scalable qualified: fall back to the OS stock rather than
        ;; inventing a face, and let the SOURCE say where it came from.
        (%stock-fixed-spec dpi))))

;;; ------------------------------------------------------------------- state

(defun %dpi-awareness ()
  "Whether LOGICAL-DPI can be trusted in THIS process.
A DPI-unaware process is fed a virtualized 96 dpi, so the very same read yields
different logical font heights depending on this attribute alone.  The library
reports it and never sets it:
process DPI awareness is a one-way, process-global attribute of the HOST, and
changing it from inside a library would silently relayout every window the host
already has."
  ;; Both context calls are Windows 10 1607+; on older Windows the symbol does
  ;; not resolve and CFFI signals, which is why a value-return is correct here.
  (or (ignore-errors
        (case (%get-awareness-from-context (%get-thread-dpi-awareness-context))
          (0 :unaware)
          (1 :system-aware)
          (2 :per-monitor-aware)
          (t :unknown)))
      (ignore-errors (if (%is-process-dpi-aware) :aware :unaware))
      :unknown))

(defun %metrics (ncm)
  "Native UI metrics in device pixels, from the NONCLIENTMETRICS already read.

:MENU-BAR-HEIGHT and :MENU-ITEM-HEIGHT are different quantities and both are
reported: SM_CYMENU is the height of the menu bar itself, while the
NONCLIENTMETRICS iMenuHeight is the height of one menu item box."
  (cffi:with-foreign-slots ((border-width scroll-width scroll-height
                             caption-height sm-caption-height
                             menu-width menu-height padded-border-width)
                            ncm (:struct nonclientmetricsw))
    (list :menu-bar-height (%get-system-metrics +sm-cymenu+)
          :menu-item-height menu-height
          :menu-item-width menu-width
          :caption-height caption-height
          :sm-caption-height sm-caption-height
          :border-width border-width
          :padded-border-width padded-border-width
          :scroll-width scroll-width
          :scroll-height scroll-height)))

(defmethod os-fonts::query-state ((backend windows))
  (declare (ignore backend))
  (cffi:use-foreign-library user32)
  (cffi:use-foreign-library gdi32)
  (cffi:use-foreign-library advapi32)
  ;; GetDpiForSystem is Windows 10 1607+; older Windows fails to resolve the
  ;; symbol and CFFI signals, so falling back to the 96 dpi default is correct.
  (let ((dpi (coerce (or (ignore-errors (%get-dpi-for-system)) 96) 'double-float)))
    (cffi:with-foreign-object (ncm '(:struct nonclientmetricsw))
      (setf (cffi:foreign-slot-value ncm '(:struct nonclientmetricsw) 'cb-size)
            (cffi:foreign-type-size '(:struct nonclientmetricsw)))
      (unless (%system-parameters-info-w +spi-getnonclientmetrics+
                                         (cffi:foreign-type-size '(:struct nonclientmetricsw))
                                         ncm 0)
        (error 'os-fonts:os-fonts-error))
      (let* ((message (%slot-font ncm 'message-font :system dpi))
             (menu (%slot-font ncm 'menu-font :menu dpi))
             (status (%slot-font ncm 'status-font :status dpi))
             (caption (%slot-font ncm 'caption-font :caption dpi))
             (dialog-default (%dialog-default-spec dpi))
             (fixed (%fixed-spec dpi message)))
        (os-fonts::make-font-state
         :logical-dpi dpi :source :win32
         :dpi-awareness (%dpi-awareness)
         :metrics (%metrics ncm)
         :fonts (remove nil
                        (list (cons :system message)
                              (and fixed (cons :system-fixed fixed))
                              (cons :menu menu)
                              (cons :status status)
                              (cons :caption caption)
                              (and dialog-default
                                   (cons :dialog-default dialog-default))
                              (cons :control (%role-alias :control message))
                              (cons :label (%role-alias :label message))
                              (cons :tooltip (%role-alias :tooltip status))
                              ;; Windows has no separate document-text role:
                              ;; message-font IS the UI text font, which is why
                              ;; :CONTROL and :LABEL also come from it.
                              (cons :text (%role-alias :text message)))))))))
