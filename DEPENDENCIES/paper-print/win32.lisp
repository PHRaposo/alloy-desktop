(in-package #:paper-print)

(cffi:define-foreign-library comdlg32
  (:windows "Comdlg32.dll"))

(cffi:define-foreign-library gdi32
  (:windows "Gdi32.dll"))

(cffi:define-foreign-library kernel32
  (:windows "Kernel32.dll"))

(dolist (library '(comdlg32 gdi32 kernel32))
  (unless (cffi:foreign-library-loaded-p library)
    (cffi:load-foreign-library library)))

(cffi:defcstruct point
  (x :int32)
  (y :int32))

(cffi:defcstruct rect
  (left :int32)
  (top :int32)
  (right :int32)
  (bottom :int32))

(cffi:defcstruct printdlgw
  (struct-size :uint32)
  (hwnd-owner :pointer)
  (hdevmode :pointer)
  (hdevnames :pointer)
  (hdc :pointer)
  (flags :uint32)
  (from-page :uint16)
  (to-page :uint16)
  (min-page :uint16)
  (max-page :uint16)
  (copies :uint16)
  (hinstance :pointer)
  (custom-data :pointer)
  (print-hook :pointer)
  (setup-hook :pointer)
  (print-template-name :pointer)
  (setup-template-name :pointer)
  (print-template :pointer)
  (setup-template :pointer))

(cffi:defcstruct pagesetupdlgw
  (struct-size :uint32)
  (hwnd-owner :pointer)
  (hdevmode :pointer)
  (hdevnames :pointer)
  (flags :uint32)
  (paper-size (:struct point))
  (min-margin (:struct rect))
  (margin (:struct rect))
  (hinstance :pointer)
  (custom-data :pointer)
  (page-setup-hook :pointer)
  (page-paint-hook :pointer)
  (page-setup-template-name :pointer)
  (page-setup-template :pointer))

(cffi:defcstruct devnames
  (driver-offset :uint16)
  (device-offset :uint16)
  (output-offset :uint16)
  (default :uint16))

(cffi:defcstruct docinfow
  (size :int32)
  (document-name :pointer)
  (output :pointer)
  (datatype :pointer)
  (type :uint32))

(cffi:defcstruct bitmapinfoheader
  (size :uint32)
  (width :int32)
  (height :int32)
  (planes :uint16)
  (bit-count :uint16)
  (compression :uint32)
  (image-size :uint32)
  (x-pels-per-meter :int32)
  (y-pels-per-meter :int32)
  (colors-used :uint32)
  (colors-important :uint32))

(cffi:defcfun ("PrintDlgW" %print-dialog) :int32
  (dialog :pointer))

(cffi:defcfun ("PageSetupDlgW" %page-setup-dialog) :int32
  (dialog :pointer))

(cffi:defcfun ("CommDlgExtendedError" %common-dialog-error) :uint32)

(cffi:defcfun ("GlobalAlloc" %global-alloc) :pointer
  (flags :uint32)
  (bytes :size))

(cffi:defcfun ("GlobalSize" %global-size) :size
  (memory :pointer))

(cffi:defcfun ("GlobalLock" %global-lock) :pointer
  (memory :pointer))

(cffi:defcfun ("GlobalUnlock" %global-unlock) :int32
  (memory :pointer))

(cffi:defcfun ("GlobalFree" %global-free) :pointer
  (memory :pointer))

(cffi:defcfun ("CreateDCW" %create-dc) :pointer
  (driver :pointer)
  (device :pointer)
  (output :pointer)
  (devmode :pointer))

(cffi:defcfun ("DeleteDC" %delete-dc) :int32
  (hdc :pointer))

(cffi:defcfun ("GetDeviceCaps" %get-device-caps) :int32
  (hdc :pointer)
  (index :int32))

(cffi:defcfun ("StartDocW" %start-doc) :int32
  (hdc :pointer)
  (document-info :pointer))

(cffi:defcfun ("StartPage" %start-page) :int32
  (hdc :pointer))

(cffi:defcfun ("EndPage" %end-page) :int32
  (hdc :pointer))

(cffi:defcfun ("EndDoc" %end-doc) :int32
  (hdc :pointer))

(cffi:defcfun ("AbortDoc" %abort-doc) :int32
  (hdc :pointer))

(cffi:defcfun ("SetStretchBltMode" %set-stretch-mode) :int32
  (hdc :pointer)
  (mode :int32))

(cffi:defcfun ("SetBrushOrgEx" %set-brush-origin) :int32
  (hdc :pointer)
  (x :int32)
  (y :int32)
  (previous :pointer))

(cffi:defcfun ("GetLocaleInfoW" %get-locale-info) :int32
  (locale :uint32)
  (information :uint32)
  (data :pointer)
  (characters :int32))

(cffi:defcfun ("StretchDIBits" %stretch-dibits) :int32
  (hdc :pointer)
  (destination-x :int32)
  (destination-y :int32)
  (destination-width :int32)
  (destination-height :int32)
  (source-x :int32)
  (source-y :int32)
  (source-width :int32)
  (source-height :int32)
  (bits :pointer)
  (bitmap-info :pointer)
  (usage :uint32)
  (raster-operation :uint32))

(defconstant +gmem-moveable+ #x0002)
(defconstant +pd-no-selection+ #x00000004)
(defconstant +pd-no-page-numbers+ #x00000008)
(defconstant +pd-return-dc+ #x00000100)
(defconstant +pd-use-devmode-copies-and-collate+ #x00040000)
(defconstant +psd-margins+ #x00000002)
(defconstant +psd-hundredths-of-millimeters+ #x00000008)
(defconstant +horizontal-size-mm+ 4)
(defconstant +vertical-size-mm+ 6)
(defconstant +horizontal-resolution+ 8)
(defconstant +vertical-resolution+ 10)
(defconstant +logical-dpi-x+ 88)
(defconstant +logical-dpi-y+ 90)
(defconstant +physical-width+ 110)
(defconstant +physical-height+ 111)
(defconstant +physical-offset-x+ 112)
(defconstant +physical-offset-y+ 113)
(defconstant +halftone+ 4)
(defconstant +dib-rgb-colors+ 0)
(defconstant +bi-rgb+ 0)
(defconstant +source-copy+ #x00CC0020)
(defconstant +gdi-error+ -1)
(defconstant +locale-user-default+ #x0400)
(defconstant +locale-ipapersize+ #x0000100A)
(defconstant +fallback-dots-per-inch+ 600)
(defconstant +fallback-margin-hundredths-mm+ 2500)

(defclass printer-settings ()
  ((hdevmode :initarg :hdevmode :accessor %settings-hdevmode)
   (hdevnames :initarg :hdevnames :accessor %settings-hdevnames)
   (margin :initarg :margin :accessor %settings-margin)
   (paper-size :initarg :paper-size :accessor %settings-paper-size)
   (closed-p :initform nil :accessor settings-closed-p)))

(defun %zero-memory (pointer bytes)
  (dotimes (index bytes)
    (setf (cffi:mem-aref pointer :uint8 index) 0)))

(defun %copy-global-memory (handle)
  (if (cffi:null-pointer-p handle)
      (cffi:null-pointer)
      (let* ((size (%global-size handle))
             (copy (%global-alloc +gmem-moveable+ size)))
        (when (cffi:null-pointer-p copy)
          (%fail :global-alloc 0))
        (let ((source (%global-lock handle))
              (destination (%global-lock copy)))
          (when (or (cffi:null-pointer-p source)
                    (cffi:null-pointer-p destination))
            (unless (cffi:null-pointer-p source)
              (%global-unlock handle))
            (unless (cffi:null-pointer-p destination)
              (%global-unlock copy))
            (%global-free copy)
            (%fail :global-lock 0))
          (unwind-protect
               (dotimes (index size)
                 (setf (cffi:mem-aref destination :uint8 index)
                       (cffi:mem-aref source :uint8 index)))
            (%global-unlock handle)
            (%global-unlock copy)))
        copy)))

(defun %free-global-memory (handle)
  (unless (cffi:null-pointer-p handle)
    (let ((failed-handle (%global-free handle)))
      (unless (cffi:null-pointer-p failed-handle)
        (warn "GlobalFree failed for handle ~S." failed-handle)))))

(defun close-settings (settings)
  "Release native resources owned by SETTINGS; repeated calls are safe."
  (check-type settings printer-settings)
  (unless (settings-closed-p settings)
    (%free-global-memory (%settings-hdevmode settings))
    (%free-global-memory (%settings-hdevnames settings))
    (setf (%settings-hdevmode settings) (cffi:null-pointer)
          (%settings-hdevnames settings) (cffi:null-pointer)
          (settings-closed-p settings) t))
  settings)

(defun %ensure-open-settings (settings)
  (when (and settings (settings-closed-p settings))
    (%bad-argument :settings "these printer settings have already been closed.")))

(defun %point-values (pointer)
  (values (cffi:foreign-slot-value pointer '(:struct point) 'x)
          (cffi:foreign-slot-value pointer '(:struct point) 'y)))

(defun %rect-values (pointer)
  (list (cffi:foreign-slot-value pointer '(:struct rect) 'left)
        (cffi:foreign-slot-value pointer '(:struct rect) 'top)
        (cffi:foreign-slot-value pointer '(:struct rect) 'right)
        (cffi:foreign-slot-value pointer '(:struct rect) 'bottom)))

(defun %set-point (pointer values)
  (setf (cffi:foreign-slot-value pointer '(:struct point) 'x) (first values)
        (cffi:foreign-slot-value pointer '(:struct point) 'y) (second values)))

(defun %set-rect (pointer values)
  (setf (cffi:foreign-slot-value pointer '(:struct rect) 'left) (first values)
        (cffi:foreign-slot-value pointer '(:struct rect) 'top) (second values)
        (cffi:foreign-slot-value pointer '(:struct rect) 'right) (third values)
        (cffi:foreign-slot-value pointer '(:struct rect) 'bottom) (fourth values)))

(defun %dialog-result (result operation)
  (if (zerop result)
      (let ((code (%common-dialog-error)))
        (if (zerop code) :cancelled (%fail operation code)))
      :accepted))

(defun %make-settings (hdevmode hdevnames margin paper-size)
  (make-instance 'printer-settings
                 :hdevmode hdevmode
                 :hdevnames hdevnames
                 :margin margin
                 :paper-size paper-size))

(defun page-setup (&key owner settings)
  "Display the native Windows Page Setup dialog.

Returns the settings to keep and whether the user accepted.  Cancel is a normal
result and returns the caller's own SETTINGS with NIL; an accepted dialog
returns a new settings object the caller owns and must eventually pass to
CLOSE-SETTINGS.  Unlike the Print dialog, this one honours OWNER."
  (%ensure-open-settings settings)
  (let ((hdevmode (%copy-global-memory
                   (if settings (%settings-hdevmode settings) (cffi:null-pointer))))
        (hdevnames (%copy-global-memory
                    (if settings (%settings-hdevnames settings) (cffi:null-pointer))))
        (transferred-p nil))
    (unwind-protect
         (cffi:with-foreign-object (dialog '(:struct pagesetupdlgw))
           (%zero-memory dialog (cffi:foreign-type-size '(:struct pagesetupdlgw)))
           (setf (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'struct-size)
                 (cffi:foreign-type-size '(:struct pagesetupdlgw))
                 (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'hwnd-owner)
                 (or owner (cffi:null-pointer))
                 (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'hdevmode) hdevmode
                 (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'hdevnames) hdevnames
                 (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'flags)
                 (logior +psd-margins+ +psd-hundredths-of-millimeters+))
           (when settings
             (%set-point (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'paper-size)
                         (%settings-paper-size settings))
             (%set-rect (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'margin)
                        (%settings-margin settings)))
           (let ((raw-result (%page-setup-dialog dialog)))
             (setf hdevmode (cffi:foreign-slot-value
                             dialog '(:struct pagesetupdlgw) 'hdevmode)
                   hdevnames (cffi:foreign-slot-value
                              dialog '(:struct pagesetupdlgw) 'hdevnames))
             (if (eq (%dialog-result raw-result :page-setup-dialog) :cancelled)
                 (values settings nil)
                 (multiple-value-bind (paper-width paper-height)
                     (%point-values
                      (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'paper-size))
                   (let ((new-settings
                           (%make-settings
                            hdevmode hdevnames
                            (%rect-values
                             (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'margin))
                            (list paper-width paper-height))))
                     (setf transferred-p t)
                     (values new-settings t))))))
      (unless transferred-p
        (%free-global-memory hdevmode)
        (%free-global-memory hdevnames)))))

(defun %device-name-pointer (hdevnames)
  (let ((base (%global-lock hdevnames)))
    (when (cffi:null-pointer-p base)
      (%fail :global-lock-devnames 0))
    (values (cffi:inc-pointer
             base
             (* 2 (cffi:foreign-slot-value base '(:struct devnames) 'device-offset)))
            base)))

(defun %output-name-pointer (hdevnames)
  (let ((base (%global-lock hdevnames)))
    (when (cffi:null-pointer-p base)
      (%fail :global-lock-devnames 0))
    (cffi:inc-pointer
     base
     (* 2 (cffi:foreign-slot-value base '(:struct devnames) 'output-offset)))))

(defun settings-port-name (settings)
  "The name of the port the printer of SETTINGS is attached to, or NIL.

The port is read from the DEVNAMES block, which carries it beside the device
name.  It tells a queue whose StartDoc opens a destination dialog of its own --
a prompting port such as PORTPROMPT: or FILE: -- from one that spools silently.
Answers NIL when SETTINGS carry no DEVNAMES block or the port name is empty."
  (check-type settings printer-settings)
  (%ensure-open-settings settings)
  (let ((hdevnames (%settings-hdevnames settings)))
    (unless (cffi:null-pointer-p hdevnames)
      (unwind-protect
           (let ((name (cffi:foreign-string-to-lisp
                        (%output-name-pointer hdevnames) :encoding :utf-16le)))
             (unless (zerop (length name)) name))
        (%global-unlock hdevnames)))))

(defun %settings-dc (settings)
  (%ensure-open-settings settings)
  (multiple-value-bind (device names-base)
      (%device-name-pointer (%settings-hdevnames settings))
    (declare (ignore names-base))
    (let* ((devmode-handle (%settings-hdevmode settings))
           (devmode (if (cffi:null-pointer-p devmode-handle)
                        (cffi:null-pointer)
                        (%global-lock devmode-handle))))
      (when (and (not (cffi:null-pointer-p devmode-handle))
                 (cffi:null-pointer-p devmode))
        (%global-unlock (%settings-hdevnames settings))
        (%fail :global-lock-devmode 0))
      (unwind-protect
           (cffi:with-foreign-string (driver "WINSPOOL" :encoding :utf-16le)
             (let ((hdc (%create-dc driver device (cffi:null-pointer) devmode)))
               (when (cffi:null-pointer-p hdc)
                 (%fail :create-printer-dc 0))
               hdc))
        (unless (cffi:null-pointer-p devmode)
          (%global-unlock devmode-handle))
        (%global-unlock (%settings-hdevnames settings))))))

(defun %named-printer-dc (printer-name)
  (cffi:with-foreign-string (driver "WINSPOOL" :encoding :utf-16le)
    (cffi:with-foreign-string (device printer-name :encoding :utf-16le)
      (let ((hdc (%create-dc driver device (cffi:null-pointer) (cffi:null-pointer))))
        (when (cffi:null-pointer-p hdc)
          (%fail :create-named-printer-dc printer-name))
        hdc))))

(defun default-printer-settings ()
  "Return settings for the current default printer without opening a dialog.

The caller owns the returned PRINTER-SETTINGS and must eventually pass it to
CLOSE-SETTINGS.  A missing or refused default printer signals
PAPER-PRINT-BACKEND-ERROR."
  (let ((hdevmode (cffi:null-pointer))
        (hdevnames (cffi:null-pointer))
        (transferred-p nil))
    (unwind-protect
         (cffi:with-foreign-object (dialog '(:struct pagesetupdlgw))
           (%zero-memory dialog (cffi:foreign-type-size '(:struct pagesetupdlgw)))
           (setf (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'struct-size)
                 (cffi:foreign-type-size '(:struct pagesetupdlgw))
                 (cffi:foreign-slot-value dialog '(:struct pagesetupdlgw) 'flags)
                 (logior #x00000400 +psd-hundredths-of-millimeters+))
           (let ((raw-result (%page-setup-dialog dialog)))
             (setf hdevmode (cffi:foreign-slot-value
                             dialog '(:struct pagesetupdlgw) 'hdevmode)
                   hdevnames (cffi:foreign-slot-value
                              dialog '(:struct pagesetupdlgw) 'hdevnames))
             (when (eq :cancelled (%dialog-result raw-result :default-printer))
               (%fail :default-printer 0)))
           (multiple-value-bind (paper-width paper-height)
               (%point-values
                (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'paper-size))
             (let ((settings
                     (%make-settings
                      hdevmode hdevnames
                      (%rect-values
                       (cffi:foreign-slot-pointer dialog '(:struct pagesetupdlgw) 'margin))
                      (list paper-width paper-height))))
               (setf transferred-p t)
               settings)))
      (unless transferred-p
        (%free-global-memory hdevmode)
        (%free-global-memory hdevnames)))))

(defun %delete-dc-checked (hdc)
  (when (zerop (%delete-dc hdc))
    (warn "DeleteDC failed for handle ~S." hdc)))

(defun %geometry-from-dc (hdc)
  (let ((width (%get-device-caps hdc +horizontal-resolution+))
        (height (%get-device-caps hdc +vertical-resolution+)))
    (values
     width height
     (list :physical-width (%get-device-caps hdc +physical-width+)
           :physical-height (%get-device-caps hdc +physical-height+)
           :offset-x (%get-device-caps hdc +physical-offset-x+)
           :offset-y (%get-device-caps hdc +physical-offset-y+)
           :dpi-x (%get-device-caps hdc +logical-dpi-x+)
           :dpi-y (%get-device-caps hdc +logical-dpi-y+)
           :width-mm (%get-device-caps hdc +horizontal-size-mm+)
           :height-mm (%get-device-caps hdc +vertical-size-mm+)))))

(defun %margin-device-pixels (hundredths-mm dpi)
  (round (* hundredths-mm dpi) 2540))

(defun %printable-rectangle (hdc settings)
  (multiple-value-bind (device-width device-height metadata)
      (%geometry-from-dc hdc)
    (if (null settings)
        (values 0 0 device-width device-height metadata)
        (destructuring-bind (left top right bottom)
            (%settings-margin settings)
          (let* ((dpi-x (getf metadata :dpi-x))
                 (dpi-y (getf metadata :dpi-y))
                 (offset-x (getf metadata :offset-x))
                 (offset-y (getf metadata :offset-y))
                 (physical-width (getf metadata :physical-width))
                 (physical-height (getf metadata :physical-height))
                 (x (max 0 (- (%margin-device-pixels left dpi-x) offset-x)))
                 (y (max 0 (- (%margin-device-pixels top dpi-y) offset-y)))
                 (right-edge
                   (min device-width
                        (- physical-width
                           (%margin-device-pixels right dpi-x)
                           offset-x)))
                 (bottom-edge
                   (min device-height
                        (- physical-height
                           (%margin-device-pixels bottom dpi-y)
                           offset-y))))
            (values x y
                    (max 1 (- right-edge x))
                    (max 1 (- bottom-edge y))
                    metadata))))))

(defvar *resolved-geometry* nil
  "Width, height and metadata of the last geometry a real printer resolved.
It is the first fallback when a later query finds no usable printer, so a
printer that disappears mid-session does not change the page size under a
layout that was already computed from it.")

(defun %live-geometry (settings)
  (let ((owned-settings (unless settings (default-printer-settings))))
    (unwind-protect
         (let ((hdc (%settings-dc (or settings owned-settings))))
           (unwind-protect
                (multiple-value-bind (x y width height metadata)
                    (%printable-rectangle hdc (or settings owned-settings))
                  (let ((full (list* :destination-x x :destination-y y metadata)))
                    (setf *resolved-geometry* (list width height full))
                    (values width height full)))
             (%delete-dc-checked hdc)))
      (when owned-settings
        (close-settings owned-settings)))))

(defun %locale-paper-millimeters ()
  "Return the width and height in millimeters of the user's default paper.
LOCALE_IPAPERSIZE in WinNls.h reports 1 for US Letter and 9 for ISO A4; any
other value falls back to A4, the size the rest of the world defaults to."
  (let ((size (cffi:with-foreign-pointer (buffer 32)
                (let ((characters (%get-locale-info +locale-user-default+
                                                    +locale-ipapersize+ buffer 16)))
                  (when (plusp characters)
                    (parse-integer
                     (cffi:foreign-string-to-lisp buffer :encoding :utf-16le
                                                         :count (* 2 (1- characters)))
                     :junk-allowed t))))))
    (if (eql size 1)
        (values 2159/10 2794/10 :locale-letter)
        (values 210 297 :locale-a4))))

(defun %millimeters-to-pixels (millimeters dots-per-inch)
  (round (* millimeters dots-per-inch 10) 254))

(defun %locale-fallback-geometry ()
  "Printable geometry for a host with no usable printer, in the live form.
The nominal device is the locale's default paper at 600 dpi with 25 mm margins."
  (multiple-value-bind (width-mm height-mm branch) (%locale-paper-millimeters)
    (let* ((dots-per-inch +fallback-dots-per-inch+)
           (physical-width (%millimeters-to-pixels width-mm dots-per-inch))
           (physical-height (%millimeters-to-pixels height-mm dots-per-inch))
           (margin (%margin-device-pixels +fallback-margin-hundredths-mm+
                                          dots-per-inch)))
      (values (- physical-width (* 2 margin))
              (- physical-height (* 2 margin))
              (list :destination-x margin :destination-y margin
                    :physical-width physical-width
                    :physical-height physical-height
                    :offset-x 0 :offset-y 0
                    :dpi-x dots-per-inch :dpi-y dots-per-inch
                    :width-mm (round width-mm) :height-mm (round height-mm)
                    :fallback branch)))))

(defun %fallback-geometry ()
  (if *resolved-geometry*
      (destructuring-bind (width height metadata) *resolved-geometry*
        (values width height (append metadata (list :fallback :session-cache))))
      (%locale-fallback-geometry)))

(defun paper-geometry (&optional settings)
  "Return printable pixel width, printable pixel height and device metadata.

Never opens user interface and never signals because of the printer.  A missing
default printer, a device that no longer exists and a refused device context all
produce a deterministic fallback whose metadata carries :FALLBACK naming the
branch taken: :SESSION-CACHE for the last geometry a real printer resolved in
this session, otherwise :LOCALE-A4 or :LOCALE-LETTER for the locale's default
paper with 25 mm margins at 600 dpi.  Live geometry carries no :FALLBACK key.

The values are the printable area less the margins SETTINGS carry.  PRINT-PAGES
draws into that same area before any margin, so a page laid out for this size
sits at the top left of what the device can reach.

A caller defect, such as SETTINGS that were already closed, still signals a
PAPER-PRINT-ARGUMENT-ERROR."
  (handler-case (%live-geometry settings)
    (paper-print-backend-error () (%fallback-geometry))))

(defun %print-dialog-dc (settings)
  "Open the native Print dialog and return its device context.

The Print dialog is created without an owner: with an owner window of the calling
process PrintDlgW returns at once without showing the dialog when called from the
thread that owns it, and does not return when called from another thread.  A NULL
owner, the desktop window and a window of another process all show the dialog and
return normally.  Page Setup is unaffected and still honours its owner."
  (%ensure-open-settings settings)
  (let ((hdevmode (%copy-global-memory
                   (if settings (%settings-hdevmode settings) (cffi:null-pointer))))
        (hdevnames (%copy-global-memory
                    (if settings (%settings-hdevnames settings) (cffi:null-pointer))))
        (transferred-p nil))
    (unwind-protect
         (cffi:with-foreign-object (dialog '(:struct printdlgw))
           (%zero-memory dialog (cffi:foreign-type-size '(:struct printdlgw)))
           (setf (cffi:foreign-slot-value dialog '(:struct printdlgw) 'struct-size)
                 (cffi:foreign-type-size '(:struct printdlgw))
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hwnd-owner)
                 (cffi:null-pointer)
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hdevmode) hdevmode
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hdevnames) hdevnames
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'flags)
                 (logior +pd-return-dc+ +pd-no-selection+ +pd-no-page-numbers+
                         +pd-use-devmode-copies-and-collate+)
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'min-page) 1
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'max-page) #xffff
                 (cffi:foreign-slot-value dialog '(:struct printdlgw) 'copies) 1)
           (let ((raw-result (%print-dialog dialog)))
             (setf hdevmode (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hdevmode)
                   hdevnames (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hdevnames))
             (if (eq (%dialog-result raw-result :print-dialog) :cancelled)
                 (values (cffi:null-pointer) settings nil)
                 (let ((hdc (cffi:foreign-slot-value dialog '(:struct printdlgw) 'hdc))
                       (new-settings
                         (%make-settings
                          hdevmode hdevnames
                          (if settings (%settings-margin settings) '(0 0 0 0))
                          (if settings (%settings-paper-size settings) '(0 0)))))
                   (setf transferred-p t)
                   (values hdc new-settings t)))))
      (unless transferred-p
        (%free-global-memory hdevmode)
        (%free-global-memory hdevnames)))))

(defun select-printer (&key settings owner)
  "Display the native Print dialog and return settings and acceptance.

Returns (values SETTINGS ACCEPTED-P).  Cancel returns the caller's SETTINGS and
NIL.  Acceptance returns a new PRINTER-SETTINGS owned by the caller, which must
eventually be passed to CLOSE-SETTINGS.  Native device contexts remain private
to the backend and are always released before this function returns.

OWNER is accepted for portable API parity.  The Windows backend uses an unowned
Print dialog because PrintDlgW shows no dialog at all when hwndOwner is a window
of the calling process (see %PRINT-DIALOG-DC)."
  (declare (ignore owner))
  (let ((hdc (cffi:null-pointer)))
    (unwind-protect
         (multiple-value-bind (dialog-hdc result accepted)
             (%print-dialog-dc settings)
           (setf hdc dialog-hdc)
           (values result accepted))
      (unless (cffi:null-pointer-p hdc)
        (%delete-dc-checked hdc)))))

(declaim (inline %flatten-channel))
(defun %flatten-channel (channel alpha)
  (truncate (+ (* channel alpha) (* 255 (- 255 alpha)) 127) 255))

(defun %page-to-device-bits (page bits)
  "Copy PAGE into BITS as the top-down 32-bit BGRX bitmap GDI is handed.

This runs once per pixel of a page at the printer's resolution, which is tens of
millions of pixels for A4 at 600 dpi, so the types are declared and the opaque
pixel -- every pixel of a page whose alpha is already flat -- skips the blend it
is the identity of."
  (let ((width (raster-page-width page))
        (height (raster-page-height page))
        (stride (raster-page-stride page))
        (data (raster-page-data page))
        (bottom-up (eq (raster-page-origin page) :bottom-left)))
    (declare (type (simple-array (unsigned-byte 8) (*)) data)
             (type fixnum width height stride)
             (optimize (speed 3) (safety 1)))
    (dotimes (y height)
      (declare (type fixnum y))
      (let ((source (the fixnum (* (if bottom-up (- height y 1) y) stride)))
            (destination (the fixnum (* y width 4))))
        (declare (type fixnum source destination))
        (dotimes (x width)
          (declare (ignorable x))
          (let ((alpha (aref data (+ source 3))))
            (declare (type (unsigned-byte 8) alpha))
            (if (= alpha 255)
                (setf (cffi:mem-aref bits :uint8 destination)
                      (aref data (+ source 2))
                      (cffi:mem-aref bits :uint8 (+ destination 1))
                      (aref data (+ source 1))
                      (cffi:mem-aref bits :uint8 (+ destination 2))
                      (aref data source))
                (setf (cffi:mem-aref bits :uint8 destination)
                      (%flatten-channel (aref data (+ source 2)) alpha)
                      (cffi:mem-aref bits :uint8 (+ destination 1))
                      (%flatten-channel (aref data (+ source 1)) alpha)
                      (cffi:mem-aref bits :uint8 (+ destination 2))
                      (%flatten-channel (aref data source) alpha))))
          (setf (cffi:mem-aref bits :uint8 (+ destination 3)) 0)
          (incf source 4)
          (incf destination 4))))))

(defun %draw-page (hdc page destination-x destination-y
                   printable-width printable-height)
  (check-type page raster-page)
  (let* ((width (raster-page-width page))
         (height (raster-page-height page))
         (bytes (* width height 4))
         (bits (cffi:foreign-alloc :uint8 :count bytes)))
    (unwind-protect
         (progn
           (%page-to-device-bits page bits)
           (cffi:with-foreign-object (info '(:struct bitmapinfoheader))
             (%zero-memory info (cffi:foreign-type-size '(:struct bitmapinfoheader)))
             (setf (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'size)
                   (cffi:foreign-type-size '(:struct bitmapinfoheader))
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'width) width
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'height) (- height)
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'planes) 1
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'bit-count) 32
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'compression) +bi-rgb+
                   (cffi:foreign-slot-value info '(:struct bitmapinfoheader) 'image-size) bytes)
             (let* ((scale (min (/ printable-width (raster-page-logical-width page))
                                (/ printable-height (raster-page-logical-height page))))
                    (destination-width (max 1 (round (* (raster-page-logical-width page) scale))))
                    (destination-height (max 1 (round (* (raster-page-logical-height page) scale)))))
               (when (zerop (%set-stretch-mode hdc +halftone+))
                 (%fail :set-stretch-mode 0))
               (when (zerop (%set-brush-origin hdc 0 0 (cffi:null-pointer)))
                 (%fail :set-brush-origin 0))
               (let ((scanlines
                       (%stretch-dibits hdc
                                        destination-x destination-y
                                        destination-width destination-height
                                        0 0 width height bits info
                                        +dib-rgb-colors+ +source-copy+)))
                 (when (or (zerop scanlines) (= scanlines +gdi-error+))
                   (%fail :stretch-dibits scanlines))))))
      (cffi:foreign-free bits))))

(defun %run-print-job (hdc settings page-count page-function title output)
  (multiple-value-bind (destination-x destination-y printable-width printable-height)
      (%printable-rectangle hdc settings)
    (cffi:with-foreign-string (document-name title :encoding :utf-16le)
      (labels ((run (output-pointer)
                 (cffi:with-foreign-object (info '(:struct docinfow))
                   (%zero-memory info (cffi:foreign-type-size '(:struct docinfow)))
                   (setf (cffi:foreign-slot-value info '(:struct docinfow) 'size)
                         (cffi:foreign-type-size '(:struct docinfow))
                         (cffi:foreign-slot-value info '(:struct docinfow) 'document-name)
                         document-name
                         (cffi:foreign-slot-value info '(:struct docinfow) 'output)
                         output-pointer)
                   (let ((document-open nil))
                     (unwind-protect
                          (progn
                            (let ((job (%start-doc hdc info)))
                              (when (<= job 0)
                                (%fail :start-doc job)))
                            (setf document-open t)
                            (dotimes (index page-count)
                              (let ((started (%start-page hdc)))
                                (when (<= started 0)
                                  (%fail :start-page started)))
                              (%draw-page hdc (funcall page-function (1+ index))
                                          destination-x destination-y
                                          printable-width printable-height)
                              (let ((ended (%end-page hdc)))
                                (when (<= ended 0)
                                  (%fail :end-page ended))))
                            (let ((ended (%end-doc hdc)))
                              (when (<= ended 0)
                                (%fail :end-doc ended)))
                            (setf document-open nil))
                       (when document-open
                         (%abort-doc hdc)))))))
        (if output
            (cffi:with-foreign-string (output-pointer (namestring output) :encoding :utf-16le)
              (run output-pointer))
            (run (cffi:null-pointer)))))))

(defun %print-image-pages (page-count page-function title settings
                           show-dialog output printer-name)
  (let ((owned-settings (unless settings (default-printer-settings)))
        (hdc (cffi:null-pointer))
        (result-settings nil)
        (settings-transferred-p nil))
    (unwind-protect
         (multiple-value-bind (dialog-hdc new-settings accepted)
             (if show-dialog
                 (%print-dialog-dc (or settings owned-settings))
                 (values (if printer-name
                             (%named-printer-dc printer-name)
                             (%settings-dc (or settings owned-settings)))
                         settings t))
           (setf hdc dialog-hdc
                 result-settings new-settings)
           (unless accepted
             (return-from %print-image-pages (values :cancelled nil settings)))
           (%run-print-job hdc (or result-settings settings owned-settings)
                           page-count page-function title output)
           (setf settings-transferred-p t)
           (values :printed nil result-settings))
      (unless (cffi:null-pointer-p hdc)
        (%delete-dc-checked hdc))
      (when (and result-settings
                 (not settings-transferred-p)
                 (not (eq result-settings settings))
                 (not (eq result-settings owned-settings)))
        (close-settings result-settings))
      (when owned-settings
        (close-settings owned-settings)))))

(defun print-image-pages (page-count page-function
                          &key owner (title "Common Lisp document") settings
                            (show-dialog t) output printer-name)
  "Print PAGE-COUNT raster pages; return status, detail and printer settings.

STATUS is :PRINTED, :CANCELLED when the user dismissed the native dialog, or
:FAILED when the platform refused the job.  DETAIL is the backend condition on
:FAILED and NIL otherwise; the third value is the settings object the caller
should keep, which is its own SETTINGS unless an accepted dialog produced a new
one.  On :FAILED the document is aborted and no output file is left behind.

PAGE-FUNCTION is called exactly once per page, in ascending order from 1 to
PAGE-COUNT.  That order is part of this backend's contract, so a caller may
stream pages; a caller may not assume anything narrower, such as being called
only once in total or in some other order.

A condition signalled by PAGE-FUNCTION is the caller's, and propagates
unchanged through the aborted job.  Invalid arguments signal as well, never
returning a status: PAGE-COUNT and PAGE-FUNCTION by type, everything else as a
PAPER-PRINT-ARGUMENT-ERROR.

OWNER is accepted for signature compatibility and ignored: the native Print
dialog is opened without an owner window (see %PRINT-DIALOG-DC)."
  (declare (ignore owner))
  (check-type page-count (integer 1))
  (check-type page-function function)
  (when (and show-dialog printer-name)
    (%bad-argument :printer-name
                   "it is only valid when SHOW-DIALOG is NIL."))
  (handler-case
      (%print-image-pages page-count page-function title settings
                          show-dialog output printer-name)
    (paper-print-backend-error (condition)
      (values :failed condition settings))))

;;; ------------------------------------------------------------- vector job

(cffi:defcfun ("SetAbortProc" %set-abort-procedure) :int32
  (hdc :pointer)
  (procedure :pointer))

(defvar *job-abort-hook* nil
  "Predicate the running job asks whether it should stop, or NIL for none.
Bound only for the extent of one job, on the thread that runs it, which is the
thread GDI calls the abort procedure back on.")

(defvar *job-abort-requested* nil
  "True once the abort hook has asked for the running job to stop.")

(defvar *job-abort-condition* nil
  "A condition the abort hook signalled, kept to be resignalled after the job.
A callback must not unwind through the foreign frames GDI calls it from, so the
condition leaves the callback as a value instead of propagating from inside it.")

(cffi:defcallback %abort-procedure :int32 ((hdc :pointer) (code :int32))
  (declare (ignore hdc code))
  (unless *job-abort-requested*
    (handler-case
        (when (and *job-abort-hook* (funcall *job-abort-hook*))
          (setf *job-abort-requested* t))
      (serious-condition (condition)
        ;; the hook is the caller's code and may fail; the job then stops and
        ;; the condition is reported rather than swallowed
        (setf *job-abort-condition* condition
              *job-abort-requested* t))))
  ;; TRUE continues the job, FALSE cancels it (Microsoft, AbortProc)
  (if *job-abort-requested* 0 1))

(defun %run-vector-job (hdc page-count page-function title output)
  "Spool PAGE-COUNT pages drawn straight into HDC; answer T, or NIL when aborted.

The pages go into the device's own printable area with no margin applied: a
vector job draws its own page, so where the content sits on the sheet is the
caller's layout and not this backend's."
  (multiple-value-bind (destination-x destination-y printable-width printable-height
                        metadata)
      (%printable-rectangle hdc nil)
    (let ((dpi-x (getf metadata :dpi-x))
          (dpi-y (getf metadata :dpi-y)))
      (when (zerop (%set-abort-procedure hdc (cffi:callback %abort-procedure)))
        (%fail :set-abort-procedure 0))
      (cffi:with-foreign-string (document-name title :encoding :utf-16le)
        (labels ((run (output-pointer)
                   (cffi:with-foreign-object (info '(:struct docinfow))
                     (%zero-memory info (cffi:foreign-type-size '(:struct docinfow)))
                     (setf (cffi:foreign-slot-value info '(:struct docinfow) 'size)
                           (cffi:foreign-type-size '(:struct docinfow))
                           (cffi:foreign-slot-value info '(:struct docinfow) 'document-name)
                           document-name
                           (cffi:foreign-slot-value info '(:struct docinfow) 'output)
                           output-pointer)
                     (let ((document-open nil))
                       (unwind-protect
                            (progn
                              (let ((job (%start-doc hdc info)))
                                (when (<= job 0)
                                  ;; a refusal after the hook asked to stop is
                                  ;; the cancellation, not a device failure
                                  (if *job-abort-requested*
                                      (return-from run nil)
                                      (%fail :start-doc job))))
                              (setf document-open t)
                              (dotimes (index page-count)
                                (when *job-abort-requested* (return))
                                (let ((started (%start-page hdc)))
                                  (when (<= started 0)
                                    (if *job-abort-requested*
                                        (return)
                                        (%fail :start-page started))))
                                (funcall page-function hdc (1+ index)
                                         destination-x destination-y
                                         printable-width printable-height
                                         dpi-x dpi-y)
                                (let ((ended (%end-page hdc)))
                                  (when (<= ended 0)
                                    (if *job-abort-requested*
                                        (return)
                                        (%fail :end-page ended)))))
                              (cond (*job-abort-requested*
                                     (%abort-doc hdc)
                                     (setf document-open nil)
                                     nil)
                                    (t
                                     (let ((ended (%end-doc hdc)))
                                       (when (<= ended 0)
                                         (%fail :end-doc ended)))
                                     (setf document-open nil)
                                     t)))
                         (when document-open
                           (%abort-doc hdc)))))))
          (if output
              (cffi:with-foreign-string (output-pointer (namestring output)
                                                        :encoding :utf-16le)
                (run output-pointer))
              (run (cffi:null-pointer))))))))

(defun %print-pages (page-count page-function title settings output printer-name
                     abort-hook)
  (let ((owned-settings (unless (or settings printer-name)
                          (default-printer-settings)))
        (hdc (cffi:null-pointer)))
    (%ensure-open-settings settings)
    (unwind-protect
         (let ((*job-abort-hook* abort-hook)
               (*job-abort-requested* nil)
               (*job-abort-condition* nil))
           (setf hdc (if printer-name
                         (%named-printer-dc printer-name)
                         (%settings-dc (or settings owned-settings))))
           (let ((completed (%run-vector-job hdc page-count page-function
                                             title output)))
             (when *job-abort-condition*
               (error *job-abort-condition*))
             (values (if completed :printed :cancelled) nil settings)))
      (unless (cffi:null-pointer-p hdc)
        (%delete-dc-checked hdc))
      (when owned-settings
        (close-settings owned-settings)))))

(defun print-pages (page-count page-function
                    &key (title "Common Lisp document") settings output
                      printer-name abort-hook (on-main-thread #'funcall))
  "Print PAGE-COUNT pages the caller draws itself; return status, detail and settings.

PAGE-FUNCTION is called exactly once per page, in ascending order from 1 to
PAGE-COUNT, with the device context and the page's geometry:

  (hdc page-number destination-x destination-y printable-width printable-height
   dpi-x dpi-y)

and must draw that page into HDC with the platform's own drawing calls.  The
rectangle is the device's printable area, in device units, with no margin
applied.  Unlike PRINT-IMAGE-PAGES, which scales a raster onto the sheet, this
one hands the device straight to the caller, so text stays text and lines stay
lines in the produced document.

STATUS is :PRINTED, :CANCELLED when ABORT-HOOK stopped the job, or :FAILED when
the platform refused it; DETAIL is the backend condition on :FAILED and NIL
otherwise.  A cancelled job is aborted and leaves no output file behind.

ABORT-HOOK, when given, is a function of no arguments the platform calls while
it spools; answering true cancels the job.  It runs on this thread, inside a
native call, so it must return promptly and must not re-enter this library.  A
condition it signals cancels the job and is resignalled from here.

SETTINGS names the printer, or PRINTER-NAME does; with neither, the default
printer is used and released again.  OUTPUT names the file a queue that would
otherwise ask for one writes to.  No dialog is ever opened.

Invalid arguments signal and never return a status."
  (declare (ignore on-main-thread))
  (check-type page-count (integer 1))
  (check-type page-function function)
  (when (and abort-hook (not (functionp abort-hook)))
    (%bad-argument :abort-hook "it must be a function of no arguments."))
  (when (and settings printer-name)
    (%bad-argument :printer-name "it is only valid without SETTINGS."))
  (handler-case
      (%print-pages page-count page-function title settings output printer-name
                    abort-hook)
    (paper-print-backend-error (condition)
      (values :failed condition settings))))

(defun pdf-page-from-rgba (data width height top-down)
  "Not implemented by this backend; see the macOS one for the contract."
  (declare (ignore data width height top-down))
  (%bad-argument :backend
                 "PDF-PAGE-FROM-RGBA is not implemented by the GDI backend."))

(defun pdf-page-reference (page)
  "Not implemented by this backend; see the macOS one for the contract."
  (declare (ignore page))
  (%bad-argument :backend
                 "PDF-PAGE-REFERENCE is not implemented by the GDI backend."))
