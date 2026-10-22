(in-package #:paper-print)

;;; macOS native printing backend.
;;;
;;; Same architecture as the Windows and Linux backends: resolve a native
;;; printer, hand every RGBA raster to the platform exactly once in ascending
;;; page order, and let the platform own the spool format.  Here the platform
;;; carrier is a PDFKit PDFDocument built in memory (one PDFPage per raster) and
;;; run through NSPrintOperation, which is macOS's only in-process route from
;;; pixels to a print job.  PAPER-PRINT still writes no document of its own: the
;;; PDFDocument never touches the filesystem, and the spool/save format belongs
;;; to AppKit exactly as it belongs to GTK/CUPS on Linux.
;;;
;;; Every foreign call below passes and returns only scalars and pointers.  That
;;; is deliberate: CFFI cannot pass or return C structures by value without
;;; cffi-libffi loaded, so NSRect/NSSize/CGRect never
;;; cross the boundary.  NSSize is read out of an NSValue with -getValue:size:,
;;; and per-page scaling is delegated to PDFKit's kPDFPrintPageScaleToFit rather
;;; than to a CGContextDrawImage(CGRect) call that could not be made.

(cffi:define-foreign-library paper-print-cocoa (t (:framework "Cocoa")))
(cffi:define-foreign-library paper-print-pdfkit (t (:framework "PDFKit")))
(cffi:define-foreign-library paper-print-printcore
  (t (:framework "ApplicationServices")))

(defvar *native-libraries-loaded-p* nil)

(defun %ensure-native-libraries ()
  ;; Load the frameworks this backend needs even when another library in the
  ;; image already loaded them.
  (unless *native-libraries-loaded-p*
    (handler-case
        (progn
          (cffi:use-foreign-library paper-print-cocoa)
          (cffi:use-foreign-library paper-print-pdfkit)
          (cffi:use-foreign-library paper-print-printcore)
          (setf *native-libraries-loaded-p* t))
      (error (condition)
        (%fail :load-native-printing (princ-to-string condition)))))
  t)

;;; ---------------------------------------------------------------- ObjC glue

(cffi:defcfun ("objc_getClass" %objc-get-class) :pointer (name :string))
(cffi:defcfun ("sel_registerName" %sel-register-name) :pointer (name :string))

(defmacro %objc-call (self method &rest args)
  "Send METHOD to SELF via plain objc_msgSend.  On x86_64, objc_msgSend_fpret
is a separate dispatcher for `long double' returns and returns garbage for a
CGFloat.  No call site in this backend returns a floating-point value, so
plain objc_msgSend is the only dispatcher needed and the macro stays
architecture-independent."
  (when (stringp self) (setf self `(%objc-get-class ,self)))
  (when (evenp (length args)) (setf args (append args '(:pointer))))
  (let* ((retval (car (last args)))
         (base (list* :pointer self :pointer `(%sel-register-name ,method)
                      (loop for (type name) on (butlast args) by #'cddr
                            collect type collect name))))
    `(cffi:foreign-funcall "objc_msgSend" ,@base ,retval)))

(defun %nil-p (pointer)
  (or (null pointer) (cffi:null-pointer-p pointer)))

(defun %release (pointer)
  (unless (%nil-p pointer) (%objc-call pointer "release" :void)))

(defmacro %with-autorelease-pool (&body body)
  "PAPER-PRINT is an isolated library and cannot borrow the host application's
pool, so each public entry point drains its own."
  (let ((pool (gensym "POOL")))
    `(let ((,pool (%objc-call (%objc-call "NSAutoreleasePool" "alloc" :pointer)
                              "init" :pointer)))
       (unwind-protect (progn ,@body)
         (%objc-call ,pool "release" :void)))))

(defun %nsstring (string)
  (%objc-call "NSString" "stringWithUTF8String:" :string string :pointer))

(defun %extern-nsstring (name)
  "Dereference an APPKIT_EXTERN NSString * const.  The literal behind
NSPrintJobSavingURL is \"NSJobSavingURL\" and the one behind NSPrintPaperSize is
\"NSPaperSize\", so hardcoding the C identifier would silently produce a
dictionary key that matches nothing."
  (let ((symbol (cffi:foreign-symbol-pointer name)))
    (if symbol (cffi:mem-ref symbol :pointer) (cffi:null-pointer))))

;;; NSModalResponseOK / NSModalResponseCancel (AppKit NSWindow.h, MacOSX 15.5
;;; SDK).  NSPageLayout and NSPrintPanel both answer -runModalWithPrintInfo:
;;; with one of these.
(defconstant +ns-modal-response-ok+ 1)

;;; NSBitmapImageFileType, NSBitmapImageRep.h:32-38 (TIFF 0, BMP 1, GIF 2,
;;; JPEG 3, PNG 4).
(defconstant +ns-bitmap-file-type-png+ 4)

;;; PDFPrintScalingMode, PDFDocument.h:32-37.
(defconstant +pdf-print-page-scale-none+ 0)
(defconstant +pdf-print-page-scale-to-fit+ 1)

;;; ------------------------------------------------------------------ settings

(defclass printer-settings ()
  ((print-info :initarg :print-info :reader %settings-print-info)
   (closed-p :initform nil :accessor settings-closed-p)))

(defun %make-settings (print-info)
  (make-instance 'printer-settings :print-info print-info))

(defun close-settings (settings)
  "Release native resources owned by SETTINGS; repeated calls are safe."
  (check-type settings printer-settings)
  (unless (settings-closed-p settings)
    (%release (%settings-print-info settings))
    (setf (settings-closed-p settings) t))
  settings)

(defun %ensure-open-settings (settings)
  (when settings
    (check-type settings printer-settings)
    (when (settings-closed-p settings)
      (%bad-argument :settings "these printer settings have already been closed."))))

(defun settings-port-name (settings)
  "The name of the port the printer of SETTINGS is attached to, or NIL.

Always NIL here: NSPrintInfo names a printer and a job disposition and exposes no
port name, so this backend has nothing to answer.  A caller that uses the port to
detect a queue whose own job dialog would appear must treat NIL as \"no such
queue\"."
  (check-type settings printer-settings)
  (%ensure-open-settings settings)
  nil)

(defun %copy-print-info (print-info)
  (let ((copy (%objc-call print-info "copy" :pointer)))
    (when (%nil-p copy)
      (%fail :copy-print-info "NSPrintInfo -copy returned nil."))
    copy))

(defun %shared-print-info ()
  (let ((shared (%objc-call "NSPrintInfo" "sharedPrintInfo" :pointer)))
    (when (%nil-p shared)
      (%fail :default-printer "+[NSPrintInfo sharedPrintInfo] returned nil."))
    shared))

(defun default-printer-settings ()
  "Return native AppKit settings for the current default printer.

Never opens UI: +[NSPrintInfo sharedPrintInfo] is a property read that AppKit
always answers, which is why this backend has no \"no printer configured\"
failure path.  -copy gives the caller its own object, released by
CLOSE-SETTINGS.  +[NSPrintInfo defaultPrinter] is deliberately not used; the SDK
header deprecates that pair (NSPrintInfo.h:183)."
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%with-autorelease-pool
      (%make-settings (%copy-print-info (%shared-print-info))))))

(defun %settings-or-default (settings)
  "Values: the NSPrintInfo to work on, and the PRINTER-SETTINGS this call owns
and must close (NIL when SETTINGS supplied it)."
  (if settings
      (values (%settings-print-info settings) nil)
      (let ((owned (default-printer-settings)))
        (values (%settings-print-info owned) owned))))

;;; ------------------------------------------------------------------ geometry

(cffi:defcstruct ns-size (width :double) (height :double))

(defun %paper-size (print-info)
  "Paper size in points.  -paperSize returns an NSSize by value, which CFFI
cannot receive without cffi-libffi, so the same number is read out of the print
info dictionary: the NSPrintPaperSize entry is an NSValue whose objCType is
{CGSize=dd}, and -getValue:size: copies it into a caller buffer
through a plain pointer."
  (let* ((dictionary (%objc-call print-info "dictionary" :pointer))
         (key (%extern-nsstring "NSPrintPaperSize"))
         (value (if (%nil-p key)
                    (cffi:null-pointer)
                    (%objc-call dictionary "objectForKey:" :pointer key :pointer))))
    (when (%nil-p value)
      (%fail :paper-size "NSPrintInfo carries no NSPrintPaperSize value."))
    (cffi:with-foreign-object (buffer '(:struct ns-size))
      (%objc-call value "getValue:size:"
                  :pointer buffer
                  :unsigned-long (cffi:foreign-type-size '(:struct ns-size))
                  :void)
      (values (cffi:mem-aref buffer :double 0)
              (cffi:mem-aref buffer :double 1)))))

(defun %paper-name (print-info)
  (let ((name (%objc-call print-info "paperName" :pointer)))
    (if (%nil-p name) :unknown (%objc-call name "UTF8String" :string))))

(defun %orientation (print-info)
  ;; NSPaperOrientation, NSPrintInfo.h:111: 0 portrait, 1 landscape.
  (if (zerop (%objc-call print-info "orientation" :long)) :portrait :landscape))

(defconstant +default-margin-points+ (/ (* 25 72) 25.4d0))

(defun %printable-origin (print-info paper-height)
  "Left and top inset of the printable area from the sheet, in points.

-imageablePageBounds returns an NSRect by value, which this backend cannot
receive; PMGetAdjustedPageRect and PMGetAdjustedPaperRect fill caller buffers
through pointers and need no struct return on any architecture.  NIL when
PrintCore does not answer."
  (let ((page-format (%objc-call print-info "PMPageFormat" :pointer))
        (page (cffi:foreign-symbol-pointer "PMGetAdjustedPageRect"))
        (paper (cffi:foreign-symbol-pointer "PMGetAdjustedPaperRect")))
    (when (and page paper (not (%nil-p page-format)))
      (cffi:with-foreign-objects ((page-rect :double 4) (paper-rect :double 4))
        (when (and (zerop (cffi:foreign-funcall-pointer
                           page () :pointer page-format :pointer page-rect :int))
                   (zerop (cffi:foreign-funcall-pointer
                           paper () :pointer page-format :pointer paper-rect :int)))
          ;; PMRect is top, left, bottom, right, with the page rect at the origin
          (let ((left (- (cffi:mem-aref page-rect :double 1)
                         (cffi:mem-aref paper-rect :double 1)))
                (top (- (cffi:mem-aref page-rect :double 0)
                        (cffi:mem-aref paper-rect :double 0))))
            (when (and (<= 0 left paper-height) (<= 0 top paper-height))
              (values left top))))))))

(defun %print-margin (print-info selector)
  "One NSPrintInfo margin in points, for reporting."
  (%objc-call print-info selector :double))

(defun paper-geometry (&optional settings)
  "Return page geometry without opening UI.

The values are the paper less 25 mm margins, the area win32.lisp: paper-geometry
reports with default settings.  The NSPrintInfo margins are reported under
:SETTINGS-MARGINS and not subtracted.
AppKit works in PostScript points, so this backend reports device pixels at
72 dpi -- an exact point-for-pixel representation, the same convention the Linux
backend falls back to when GTK exposes no printer resolution (linux.lisp:
paper-geometry).
NSPrintInfo has no device-resolution property to report instead.  A backend
failure falls back deterministically instead of signalling, like the other two
backends; a closed SETTINGS is still a caller defect and still signals."
  (float-features:with-float-traps-masked t
    (%ensure-open-settings settings)
    (%with-autorelease-pool
      (let ((owned nil))
        (unwind-protect
             (handler-case
                 (multiple-value-bind (print-info owned-settings)
                     (progn (%ensure-native-libraries) (%settings-or-default settings))
                   (setf owned owned-settings)
                   (multiple-value-bind (paper-width paper-height) (%paper-size print-info)
                     (let ((margin +default-margin-points+))
                       (values (max 1 (round (- paper-width (* 2 margin))))
                               (max 1 (round (- paper-height (* 2 margin))))
                               (list :backend :appkit
                                     :paper (%paper-name print-info)
                                     :paper-size (list (max 1 (round paper-width))
                                                       (max 1 (round paper-height)))
                                     :margins (float margin 1d0)
                                     :printable-origin
                                     (multiple-value-list
                                      (%printable-origin print-info paper-height))
                                     :settings-margins
                                     (list (%print-margin print-info "leftMargin")
                                           (%print-margin print-info "rightMargin")
                                           (%print-margin print-info "topMargin")
                                           (%print-margin print-info "bottomMargin"))
                                     :orientation (%orientation print-info)
                                     :dpi-x 72 :dpi-y 72 :unit :point)))))
               (paper-print-backend-error ()
                 ;; A4 less the 25 mm of the Page Setup contract, at 72 dpi, used
                 ;; when AppKit answers nothing.
                 (values (round (- 595 (* 2 +default-margin-points+)))
                         (round (- 842 (* 2 +default-margin-points+)))
                         (list :backend :appkit :dpi-x 72 :dpi-y 72 :unit :point
                               :fallback :appkit-default))))
          (when owned (close-settings owned)))))))

;;; ------------------------------------------------------------------- dialogs

(defun %run-modal-print-info-panel (panel-class selector settings operation)
  "Run an app-modal AppKit panel over a private copy of the caller's print info.

The copy matters: -runModalWithPrintInfo: mutates the object it is handed, so
running it on the caller's own NSPrintInfo would edit SETTINGS even when the
user cancels.  Acceptance returns a fresh PRINTER-SETTINGS the caller owns;
cancellation releases the copy and returns the caller's SETTINGS untouched."
  (multiple-value-bind (base owned) (%settings-or-default settings)
    (let ((copy (cffi:null-pointer))
          (accepted nil))
      (unwind-protect
           (progn
             (setf copy (%copy-print-info base))
             ;; PANEL-CLASS is a runtime string, so the class is resolved here
             ;; rather than by %OBJC-CALL's compile-time string branch.
             (let ((panel (%objc-call (%objc-get-class panel-class) selector :pointer)))
               (when (%nil-p panel)
                 (%fail operation "AppKit returned no panel."))
               (let ((response (%objc-call panel "runModalWithPrintInfo:"
                                           :pointer copy :long)))
                 (setf accepted (= response +ns-modal-response-ok+))
                 (if accepted
                     (values (%make-settings copy) t)
                     (values settings nil)))))
        (when owned (close-settings owned))
        (unless accepted (%release copy))))))

(defun page-setup (&key owner settings)
  "Display the native Page Setup panel.

Cancel returns the caller's SETTINGS and NIL, unmodified.  Acceptance returns a
fresh PRINTER-SETTINGS the caller closes.  OWNER is accepted for portable API
parity and ignored: -[NSPageLayout runModalWithPrintInfo:] is app-modal and
takes no window (NSPageLayout.h:51), the same structural reason the Linux
backend ignores it."
  (declare (ignore owner))
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%ensure-open-settings settings)
    (%with-autorelease-pool
      (%run-modal-print-info-panel "NSPageLayout" "pageLayout" settings :page-setup))))

(defun select-printer (&key settings owner)
  "Display the native Print panel to choose a printer without printing yet.

Same cancellation contract as PAGE-SETUP.  OWNER is accepted for portable API
parity and ignored: -[NSPrintPanel runModalWithPrintInfo:] takes no window
either (NSPrintPanel.h:125)."
  (declare (ignore owner))
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%ensure-open-settings settings)
    (%with-autorelease-pool
      (%run-modal-print-info-panel "NSPrintPanel" "printPanel" settings :select-printer))))

;;; ------------------------------------------------------- raster -> PDFDocument

(defun %flatten-channel (channel alpha)
  ;; The same flattening against white as the Windows and Linux backends.
  (truncate (+ (* channel alpha) (* 255 (- 255 alpha)) 127) 255))

(defun %page-to-pdf-page (page)
  "One RASTER-PAGE -> one autoreleased PDFPage.

Straight-alpha RGBA is flattened onto white into a 24-bit opaque
NSBitmapImageRep -- the alpha channel is dropped rather than carried, which is
what the other two backends also do before handing pixels to the platform.  The
rep is encoded as PNG and reloaded as an NSImage because -[NSImage initWithSize:]
and -[NSBitmapImageRep setSize:] both take an NSSize by value; NSData keeps the
whole path on pointers."
  (check-type page raster-page)
  (let* ((width (raster-page-width page))
         (height (raster-page-height page))
         (source (raster-page-data page))
         (stride (raster-page-stride page))
         (top-down (eq (raster-page-origin page) :top-left))
         (rep (%objc-call
               (%objc-call "NSBitmapImageRep" "alloc" :pointer)
               "initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:"
               :pointer (cffi:null-pointer) ; NULL planes: the rep owns the buffer
               :long width :long height :long 8 :long 3
               :char 0 :char 0
               :pointer (%nsstring "NSDeviceRGBColorSpace")
               :long (* width 3) :long 24
               :pointer)))
    (when (%nil-p rep)
      (%fail :bitmap-image-rep (list width height)))
    (unwind-protect
         (let ((destination (%objc-call rep "bitmapData" :pointer))
               ;; AppKit is free to pad rows; ask rather than assume.
               (destination-stride (%objc-call rep "bytesPerRow" :long)))
           (when (%nil-p destination)
             (%fail :bitmap-image-rep "NSBitmapImageRep exposed no bitmapData."))
           (dotimes (y height)
             (let ((source-row (* (if top-down y (- height y 1)) stride))
                   (destination-row (* y destination-stride)))
               (dotimes (x width)
                 (let* ((from (+ source-row (* x 4)))
                        (to (+ destination-row (* x 3)))
                        (alpha (aref source (+ from 3))))
                   (setf (cffi:mem-aref destination :uint8 to)
                         (%flatten-channel (aref source from) alpha)
                         (cffi:mem-aref destination :uint8 (+ to 1))
                         (%flatten-channel (aref source (+ from 1)) alpha)
                         (cffi:mem-aref destination :uint8 (+ to 2))
                         (%flatten-channel (aref source (+ from 2)) alpha))))))
           (let ((png (%objc-call rep "representationUsingType:properties:"
                                  :unsigned-long +ns-bitmap-file-type-png+
                                  :pointer (%objc-call "NSDictionary" "dictionary" :pointer)
                                  :pointer)))
             (when (%nil-p png)
               (%fail :png-representation (list width height)))
             (let ((image (%objc-call (%objc-call "NSImage" "alloc" :pointer)
                                      "initWithData:" :pointer png :pointer)))
               (when (%nil-p image)
                 (%fail :page-image (list width height)))
               (unwind-protect
                    (let ((pdf-page (%objc-call (%objc-call "PDFPage" "alloc" :pointer)
                                                "initWithImage:" :pointer image :pointer)))
                      (when (%nil-p pdf-page)
                        (%fail :pdf-page (list width height)))
                      (%objc-call pdf-page "autorelease" :pointer))
                 (%release image)))))
      (%release rep))))

(defun %build-pdf-document (page-count page-function)
  "PAGE-FUNCTION exactly once per page, 1..PAGE-COUNT ascending, into an
autoreleased in-memory PDFDocument.  Nothing is written to disk here, so a
condition escaping PAGE-FUNCTION leaves no artefact to clean up."
  (let ((document (%objc-call (%objc-call "PDFDocument" "alloc" :pointer)
                              "init" :pointer)))
    (when (%nil-p document)
      (%fail :pdf-document "PDFDocument -init returned nil."))
    (%objc-call document "autorelease" :pointer)
    ;; Each page is sized from the raster's pixel dimensions and
    ;; kPDFPrintPageScaleToFit aspect-fits from there; the Windows and Linux
    ;; backends fit from RASTER-PAGE-LOGICAL-WIDTH/HEIGHT.  The two agree when
    ;; the logical and pixel aspect ratios match.  Fitting from the logical size
    ;; here needs -[PDFPage setBounds:forBox:], which takes a PDFRect by value
    ;; and therefore cffi-libffi.
    (dotimes (index page-count)
      (%objc-call document "insertPage:atIndex:"
                  :pointer (%page-to-pdf-page (funcall page-function (1+ index)))
                  :unsigned-long index :void))
    document))

;;; ---------------------------------------------------------------- print job

(defun %apply-printer-name (print-info printer-name)
  (let ((printer (%objc-call "NSPrinter" "printerWithName:"
                             :pointer (%nsstring printer-name) :pointer)))
    (when (%nil-p printer)
      (%fail :find-printer printer-name))
    (%objc-call print-info "setPrinter:" :pointer printer :void)))

(defun %apply-output (print-info output)
  "Send the job to a file instead of a spool queue.  NSPrintSaveJob plus the
NSPrintJobSavingURL attribute, the 10.6+ replacement for the deprecated
NSPrintSavePath (NSPrintInfo.h:72,85,197).  OUTPUT selects a destination, never
a printer -- the same separation Windows keeps with DOCINFOW.lpszOutput."
  (%objc-call print-info "setJobDisposition:"
              :pointer (%extern-nsstring "NSPrintSaveJob") :void)
  (%objc-call (%objc-call print-info "dictionary" :pointer)
              "setObject:forKey:"
              :pointer (%objc-call "NSURL" "fileURLWithPath:"
                                   :pointer (%nsstring (namestring output)) :pointer)
              :pointer (%extern-nsstring "NSPrintJobSavingURL")
              :void))

(defun %run-print-operation (document print-info title output
                             &optional (scaling-mode +pdf-print-page-scale-to-fit+))
  "Run the print operation synchronously on the calling thread.

showsPrintPanel is always NO: acceptance was already decided by SELECT-PRINTER
before any page was rendered, which is what lets PAGE-FUNCTION run only after
the dialog is accepted.  A second panel here would also make -runOperation
returning NO ambiguous between cancel and failure; with no panel it can only
mean failure.  canSpawnSeparateThread is left at its NO default
(NSPrintOperation.h:93), so the job completes before this call returns."
  (let ((operation (%objc-call document
                               "printOperationForPrintInfo:scalingMode:autoRotate:"
                               :pointer print-info
                               :long scaling-mode
                               :char 0
                               :pointer)))
    (when (%nil-p operation)
      (%fail :print-operation "PDFDocument returned no NSPrintOperation."))
    (let ((operation-info (%objc-call operation "printInfo" :pointer)))
      (when output (%apply-output operation-info output)))
    (%objc-call operation "setShowsPrintPanel:" :char 0 :void)
    (%objc-call operation "setShowsProgressPanel:" :char 0 :void)
    (when title
      (%objc-call operation "setJobTitle:" :pointer (%nsstring title) :void))
    (when (zerop (%objc-call operation "runOperation" :char))
      (%fail :run-operation "NSPrintOperation -runOperation reported failure."))
    t))

(defun %delete-output-on-failure (output)
  (when (and output (probe-file output))
    (ignore-errors (delete-file output))))

(defun %print-image-pages (page-count page-function title settings
                           show-dialog output printer-name owner)
  (let ((owned-settings nil)
        (result-settings nil)
        (success nil))
    (unwind-protect
         (progn
           (cond
             (show-dialog
              (multiple-value-bind (chosen accepted)
                  (select-printer :settings settings :owner owner)
                (unless accepted
                  ;; Cancel is a normal outcome: no page rendered, no job
                  ;; created, no file written, caller settings untouched.
                  (return-from %print-image-pages (values :cancelled nil settings)))
                (setf result-settings chosen)))
             (settings
              (setf result-settings settings))
             (t
              (setf owned-settings (default-printer-settings)
                    result-settings nil)))
           (let ((print-info (%settings-print-info
                              (or (and show-dialog result-settings)
                                  owned-settings settings))))
             (when printer-name (%apply-printer-name print-info printer-name))
             (%run-print-operation (%build-pdf-document page-count page-function)
                                   print-info title output))
           (setf success t)
           (values :printed nil (if show-dialog result-settings settings)))
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
  "Print raster pages through AppKit's native printing pipeline.

PAGE-FUNCTION is called exactly once per page, in ascending order, and only
after the print dialog has been accepted when SHOW-DIALOG is true.  Each page is
flattened from straight-alpha RGBA to an opaque 24-bit bitmap and becomes one
PDFKit page; the resulting PDFDocument lives only in memory and is handed to
NSPrintOperation, so PAPER-PRINT leaves no intermediate file behind on any exit
path.  PDFKit scales each page onto the paper with kPDFPrintPageScaleToFit.

OUTPUT selects a save destination and never selects a printer.  PRINTER-NAME
selects an NSPrinter when SHOW-DIALOG is NIL.  Backend failures return :FAILED;
caller conditions from PAGE-FUNCTION propagate unchanged."
  (check-type page-count (integer 1))
  (check-type page-function function)
  (%ensure-open-settings settings)
  (when (and show-dialog printer-name)
    (%bad-argument :printer-name
                   "it is only valid when SHOW-DIALOG is NIL."))
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%with-autorelease-pool
      (handler-case
          (%print-image-pages page-count page-function title settings
                              show-dialog output printer-name owner)
        (paper-print-backend-error (condition)
          (%delete-output-on-failure output)
          (values :failed condition settings))))))

;;; ------------------------------------------------------------ vector pages

(defun %cf-release (pointer)
  (unless (%nil-p pointer)
    (cffi:foreign-funcall "CFRelease" :pointer pointer :void)))

(defun %pdf-context (data width height)
  "A PDF context of WIDTH x HEIGHT points writing into DATA."
  (let ((consumer (cffi:foreign-funcall "CGDataConsumerCreateWithCFData"
                                        :pointer data :pointer)))
    (when (%nil-p consumer)
      (%fail :pdf-consumer "CGDataConsumerCreateWithCFData returned null."))
    (unwind-protect
         (cffi:with-foreign-object (media-box :double 4)
           (setf (cffi:mem-aref media-box :double 0) 0d0
                 (cffi:mem-aref media-box :double 1) 0d0
                 (cffi:mem-aref media-box :double 2) (coerce width 'double-float)
                 (cffi:mem-aref media-box :double 3) (coerce height 'double-float))
           (let ((context (cffi:foreign-funcall "CGPDFContextCreate"
                                                :pointer consumer
                                                :pointer media-box
                                                :pointer (cffi:null-pointer)
                                                :pointer)))
             (when (%nil-p context)
               (%fail :pdf-context "CGPDFContextCreate returned null."))
             context))
      (%cf-release consumer))))

(defun %draw-pdf-pages (context page-count page-function width height
                        sheet-height left top abort-hook)
  "PAGE-FUNCTION once per page, 1..PAGE-COUNT ascending; NIL when ABORT-HOOK stopped it.

The sheet is the media box and the page is drawn at LEFT, TOP from its top left
corner, which is the printable origin: a page laid out for WIDTH x HEIGHT sits at
the top left of what the device can reach, as it does on the other two backends
(win32.lisp: paper-geometry)."
  (dotimes (index page-count t)
    (when (and abort-hook (funcall abort-hook))
      (return nil))
    (cffi:foreign-funcall "CGPDFContextBeginPage"
                          :pointer context :pointer (cffi:null-pointer) :void)
    (cffi:foreign-funcall "CGContextTranslateCTM"
                          :pointer context :double 0d0
                          :double (coerce sheet-height 'double-float) :void)
    (cffi:foreign-funcall "CGContextScaleCTM"
                          :pointer context :double 1d0 :double -1d0 :void)
    (cffi:foreign-funcall "CGContextTranslateCTM"
                          :pointer context
                          :double (coerce left 'double-float)
                          :double (coerce top 'double-float) :void)
    (funcall page-function context (1+ index) 0 0 width height 72 72)
    (cffi:foreign-funcall "CGPDFContextEndPage" :pointer context :void)))

(defun %print-pages (page-count page-function title settings output printer-name
                     abort-hook on-main-thread)
  (let* ((owned-settings (unless settings (default-printer-settings)))
         (effective-settings (or settings owned-settings))
         (print-info (%settings-print-info effective-settings))
         (data (cffi:foreign-funcall "CFDataCreateMutable"
                                     :pointer (cffi:null-pointer) :long 0 :pointer))
         (context nil)
         (document nil)
         (success nil))
    (when (%nil-p data)
      (%fail :pdf-data "CFDataCreateMutable returned null."))
    (unwind-protect
         (multiple-value-bind (width height metadata) (paper-geometry effective-settings)
           (destructuring-bind (&optional (sheet-width width) (sheet-height height))
               (getf metadata :paper-size)
             (destructuring-bind (&optional left top) (getf metadata :printable-origin)
               (setf context (%pdf-context data sheet-width sheet-height))
               (let ((drawn (%draw-pdf-pages context page-count page-function
                                             width height sheet-height
                                             (or left 0) (or top 0) abort-hook)))
                 (cffi:foreign-funcall "CGPDFContextClose" :pointer context :void)
                 (unless drawn
                   (return-from %print-pages (values :cancelled nil settings))))))
           (setf document (%objc-call (%objc-call "PDFDocument" "alloc" :pointer)
                                      "initWithData:" :pointer data :pointer))
           (when (%nil-p document)
             (%fail :pdf-document "PDFDocument -initWithData: returned nil."))
           (when printer-name (%apply-printer-name print-info printer-name))
           (funcall on-main-thread
                    (lambda ()
                      (float-features:with-float-traps-masked t
                        (%with-autorelease-pool
                          (%run-print-operation document print-info title output
                                                +pdf-print-page-scale-none+)))))
           (setf success t)
           (values :printed nil settings))
      (unless success (%delete-output-on-failure output))
      (%release document)
      (unless (%nil-p context)
        (cffi:foreign-funcall "CGContextRelease" :pointer context :void))
      (%cf-release data)
      (when owned-settings (close-settings owned-settings)))))

(defun pdf-page-from-rgba (data width height top-down)
  "An autoreleased PDFPage carrying the straight-alpha RGBA image DATA."
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%page-to-pdf-page (make-raster-page width height data
                                         :origin (if top-down :top-left :bottom-left)))))

(defun pdf-page-reference (page)
  "The CGPDFPageRef behind the PDFPage PAGE."
  (if (%nil-p page) (cffi:null-pointer) (%objc-call page "pageRef" :pointer)))

(defun print-pages (page-count page-function
                    &key (title "Common Lisp document") settings output
                      printer-name abort-hook (on-main-thread #'funcall))
  "Print pages PAGE-FUNCTION draws into a CGContextRef of a PDF context."
  (check-type page-count (integer 1))
  (check-type page-function function)
  (when (and abort-hook (not (functionp abort-hook)))
    (%bad-argument :abort-hook "it must be a function of no arguments."))
  (when (and settings printer-name)
    (%bad-argument :printer-name "it is only valid without SETTINGS."))
  (%ensure-open-settings settings)
  (float-features:with-float-traps-masked t
    (%ensure-native-libraries)
    (%with-autorelease-pool
      (handler-case
          (%print-pages page-count page-function title settings output
                        printer-name abort-hook on-main-thread)
        (paper-print-backend-error (condition)
          (%delete-output-on-failure output)
          (values :failed condition settings))))))
