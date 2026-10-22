(in-package #:os-fonts.macos)

;; AppKit exposes the native default sizes directly by role. Passing 0 requests
;; the current system default for that role. Numeric results must never be
;; inferred from another platform; this adapter is not yet validated on macOS.

(cffi:define-foreign-library cocoa (t (:framework "Cocoa")))
(cffi:defctype %id :pointer)
(cffi:defctype %sel :pointer)
(cffi:defcfun ("objc_getClass" %objc-get-class) :pointer (name :string))
(cffi:defcfun ("sel_registerName" %sel-register-name) :pointer (name :string))

(defmacro %objc-call (self method &rest args)
  (when (stringp self) (setf self `(%objc-get-class ,self)))
  (when (evenp (length args)) (setf args (append args '(%id))))
  (let* ((retval (car (last args)))
         (base (list* '%id self '%sel `(%sel-register-name ,method)
                      (loop for (type name) on (butlast args) by #'cddr
                            collect type collect name))))
    #+arm64 `(cffi:foreign-funcall "objc_msgSend" ,@base ,retval)
    #-arm64 (if (find retval '(:double :float))
                `(cffi:foreign-funcall "objc_msgSend_fpret" ,@base ,retval)
                `(cffi:foreign-funcall "objc_msgSend" ,@base ,retval))))

(defclass macos (backend) ())

(defun %nsstring->string (nsstring)
  (unless (cffi:null-pointer-p nsstring)
    (%objc-call nsstring "UTF8String" :string)))

;; NSFontDescriptorSymbolicTraits is a uint32 bit mask (NSFontDescriptor.h).
;; Only two bits describe style: #x1 NSFontItalicTrait, #x2 NSFontBoldTrait.
;; The other bits classify the family (#x400 monospace, #x80000000 class mask)
;; and must be masked off rather than mistaken for a third style.  Measured on
;; this machine through this very macro: Helvetica #x80000000, -Bold #x80000002,
;; -Oblique #x80000001, -BoldOblique #x80000003 -- and titleBarFontOfSize:
;; #x00000002, i.e. the title-bar role really is bold and used to be reported
;; as :REGULAR because the value was fabricated instead of read.
(defun %symbolic-traits (font)
  (let ((descriptor (%objc-call font "fontDescriptor" :pointer)))
    (if (cffi:null-pointer-p descriptor)
        0
        (%objc-call descriptor "symbolicTraits" :uint32))))

(defun %font-spec (role selector)
  (let ((font (%objc-call "NSFont" selector :double 0d0 :pointer)))
    (unless (cffi:null-pointer-p font)
      (let* ((family (%nsstring->string (%objc-call font "familyName" :pointer)))
             (size (%objc-call font "pointSize" :double))
             (traits (%symbolic-traits font)))
        (os-fonts::make-font-spec
         :role role :family family :native-family family :size size
         :weight (if (logtest traits #x2) :bold :regular)
         :slant (if (logtest traits #x1) :italic :roman)
         :source :appkit)))))

(defun %backing-scale-factor ()
  "Backing scale of the main screen: 1.0 on a non-Retina display, 2.0 or 3.0 on
Retina.  NIL when there is no screen at all (no window server), so the caller
can report that instead of inventing a factor."
  (let ((screen (%objc-call "NSScreen" "mainScreen" :pointer)))
    (unless (cffi:null-pointer-p screen)
      (%objc-call screen "backingScaleFactor" :double))))

(defun %copy-role (role spec)
  (when spec
    (os-fonts::make-font-spec
     :role role
     :family (font-spec-family spec)
     :native-family (font-spec-native-family spec)
     :size (font-spec-size spec)
     :weight (font-spec-weight spec)
     :slant (font-spec-slant spec)
     :source (font-spec-source spec))))

(defun %scroller-thickness (factor)
  "Scroller thickness in device pixels, regular control size, at the scroller
style the user currently runs (overlay or legacy -- they differ by a pixel)."
  (* factor
     (%objc-call "NSScroller" "scrollerWidthForControlSize:scrollerStyle:"
                 :uint64 0                          ; NSControlSizeRegular
                 :int64 (%objc-call "NSScroller" "preferredScrollerStyle" :int64)
                 :double)))

(defmethod os-fonts::query-state ((backend macos))
  (declare (ignore backend))
  (cffi:use-foreign-library cocoa)
  ;; Every ObjC call below has to run with the FPU traps masked.  SBCL arms
  ;; :DIVIDE-BY-ZERO/:INVALID/:OVERFLOW by default and that FPU state survives
  ;; into AppKit, where CTFontGetAscent performs a division that is benign under
  ;; the masked FPU every normal Cocoa process (and LispWorks) runs with, but
  ;; raises a hardware exception here -- killing the process from inside a
  ;; foreign frame the image cannot unwind.  QUERY-STATE is the single entry
  ;; point of this backend that reaches ObjC (SNAPSHOT, REFRESH, POLL,
  ;; FONT-FOR-ROLE, LOGICAL-DPI and METRICS all funnel through it), so one
  ;; wrapper here covers every caller.  A backend that opens a window or panel
  ;; would also need to hop to the main thread; that is not needed here
  ;; because these are documented thread-safe read-only class methods, and no
  ;; window or panel is created.
  (float-features:with-float-traps-masked t
    (let* ((scale (%backing-scale-factor))
           ;; No screen at all -> assume 1.0, and say so through :SOURCE rather
           ;; than passing an invented factor off as a measurement.
           (factor (or scale 1d0))
           (system (%font-spec :system "systemFontOfSize:"))
           (fixed (%font-spec :system-fixed "userFixedPitchFontOfSize:"))
           (menu (%font-spec :menu "menuFontOfSize:"))
           (menubar (%font-spec :menu-bar "menuBarFontOfSize:"))
           (label (%font-spec :label "labelFontOfSize:"))
           (tooltip (%font-spec :tooltip "toolTipsFontOfSize:"))
           (control (%font-spec :control "controlContentFontOfSize:"))
           (text (%font-spec :text "userFontOfSize:"))
           (title (%font-spec :title-bar "titleBarFontOfSize:")))
      ;; AppKit point sizes are logical points. Backing scale is a separate concern
      ;; and is intentionally not folded into the font size here.
      (os-fonts::make-font-state
       ;; LOGICAL-DPI is the pt->device-pixel conversion factor, which is what the
       ;; other two backends already put in this slot: windows.lisp:401 feeds
       ;; GetDpiForSystem straight in (a per-monitor-aware process gets 144 at
       ;; 150%, scale included), and linux.lisp:190 does the same with gtk-xft-dpi
       ;; (Xft.dpi likewise merges physical DPI and scale).  macOS keeps those two
       ;; apart -- a fixed 72 logical resolution times backingScaleFactor -- so the
       ;; product is what belongs here: 72 on a non-Retina screen, 144 at 2x.
       :logical-dpi (* 72d0 factor)
       :source (if scale :appkit :appkit-no-screen)
       ;; AppKit works in logical points and does not virtualize DPI per process
       ;; the way Windows does; backing scale is a separate, per-screen concern.
       :dpi-awareness :not-applicable
       ;; METRICS is a device-pixel plist (see PROTOCOL.LISP), so the AppKit point
       ;; values are scaled by the same factor LOGICAL-DPI uses -- matching Win32,
       ;; where GetSystemMetrics already answers in device pixels.  Only the two
       ;; keys with a cheap, real AppKit source are filled in; the rest keep NIL
       ;; because inventing a value is exactly what the Windows backend was fixed
       ;; for.  +[NSMenu menuBarHeight] and NSScroller are class methods and need
       ;; no NSApplication, so they work in a plain non-bundled Lisp too.
       :metrics (list :menu-bar-height
                      (* factor (%objc-call "NSMenu" "menuBarHeight" :double))
                      ;; No system-wide menu item height on macOS: NSMenuItem
                      ;; sizes itself from its content, unlike NONCLIENTMETRICS.
                      :menu-item-height nil
                      ;; Menu item width is content-driven; AppKit has no constant.
                      :menu-item-width nil
                      ;; macOS has no Win32 "caption" metric.  Title-bar height
                      ;; only comes out of NSWindow frameRectForContentRect: on a
                      ;; real window, which this read-only query will not create.
                      :caption-height nil
                      :sm-caption-height nil
                      ;; NONCLIENTMETRICS border concepts, GDI-specific.
                      :border-width nil
                      :padded-border-width nil
                      ;; One thickness serves both: an NSScroller is as thick
                      ;; vertically as horizontally, so SM_CXVSCROLL and
                      ;; SM_CYHSCROLL collapse to the same number here.  Read for
                      ;; the regular control size at the user's current scroller
                      ;; style (overlay vs legacy changes it: 16 vs 15).
                      :scroll-width (%scroller-thickness factor)
                      :scroll-height (%scroller-thickness factor))
       :fonts (remove nil (mapcar (lambda (x) (and (cdr x) x))
                                  (list (cons :system system)
                                        (cons :system-fixed fixed)
                                        (cons :menu menu)
                                        (cons :menu-bar menubar)
                                        (cons :label label)
                                        (cons :tooltip tooltip)
                                        (cons :control control)
                                        (cons :dialog-default
                                              (%copy-role :dialog-default control))
                                        (cons :text text)
                                        (cons :title-bar title))))))))
