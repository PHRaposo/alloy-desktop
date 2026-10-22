(in-package #:color-select.macos)

(cffi:define-foreign-library cocoa      (t (:framework "Cocoa")))
(cffi:define-foreign-library appkit     (t (:framework "AppKit")))
(cffi:define-foreign-library foundation (t (:framework "Foundation")))

(cffi:defctype id :pointer)
(cffi:defctype sel :pointer)

(cffi:defcfun (get-class "objc_getClass") :pointer
  (name :string))

(cffi:defcfun (register-name "sel_registerName") :pointer
  (name :string))

(defmacro objc-call (self method &rest args)
  (when (stringp self)
    (setf self `(get-class ,self)))
  (when (evenp (length args))
    (setf args (append args '(id))))
  (let ((retval (car (last args)))
        (base-args (list* 'id self
                          'sel `(register-name ,method)
                          (loop for (type name) on (butlast args) by #'cddr
                                collect type collect name))))
    (cond ((find retval '(:double :float))
           ;; arm64 has no objc_msgSend_fpret/_stret; all returns go through objc_msgSend.
           #+arm64 `(cffi:foreign-funcall "objc_msgSend" ,@base-args ,retval)
           #-arm64 `(cffi:foreign-funcall "objc_msgSend_fpret" ,@base-args ,retval))
          (t
           `(cffi:foreign-funcall "objc_msgSend" ,@base-args ,retval)))))

(defclass macos (backend)
  ())

(defmethod initialize-instance :after ((backend macos) &key)
  (unless (cffi:foreign-library-loaded-p 'cocoa)
    (cffi:use-foreign-library foundation)
    (cffi:use-foreign-library cocoa)
    (cffi:use-foreign-library appkit)))

(defun nsstring (string)
  (objc-call "NSString" "stringWithUTF8String:" :string string))

(defun rgb->nscolor (color)
  (objc-call "NSColor" "colorWithCalibratedRed:green:blue:alpha:"
             :double (coerce (first color) 'double-float)
             :double (coerce (second color) 'double-float)
             :double (coerce (third color) 'double-float)
             :double 1.0d0))

(defun nscolor->rgb (ns-color)
  (let* ((rgb (objc-call ns-color "colorUsingColorSpaceName:"
                         :pointer (nsstring "NSCalibratedRGBColorSpace")))
         (r   (objc-call rgb "redComponent"   :double))
         (g   (objc-call rgb "greenComponent" :double))
         (b   (objc-call rgb "blueComponent"  :double)))
    (list (float r) (float g) (float b))))

;; NSColorPanelMode: 5 = color list (palette), 6 = colour wheel (full).
;; The panel is a non-modal NSPanel; drive it with a modal session
;; (beginModalSessionForWindow:) and set the process to :accessory (1) so a
;; non-bundled SBCL shows and focuses the panel.
(defmethod choose-color-with ((backend macos) &key default (full-open t) &allow-other-keys)
  #+darwin
  (trivial-main-thread:with-body-in-main-thread (:blocking t)
    (float-features:with-float-traps-masked t
      (let ((app   (objc-call "NSApplication" "sharedApplication"))
            (panel (objc-call "NSColorPanel" "sharedColorPanel")))
        (unless (= 0 (objc-call app "activationPolicy" :long))
          (objc-call app "setActivationPolicy:" :long 1 :void))
        (objc-call panel "setShowsAlpha:" :bool nil :void)
        (objc-call panel "setMode:" :long (if full-open 6 5) :void)
        (when default
          (objc-call panel "setColor:" :pointer (rgb->nscolor default) :void))
        ;; "Done" accessory: target=panel, action=performClose: (built-in, no callback).
        (let ((done (objc-call "NSButton" "buttonWithTitle:target:action:"
                               :pointer (nsstring "Done")
                               :pointer panel
                               :pointer (register-name "performClose:")
                               :pointer)))
          (objc-call panel "setAccessoryView:" :pointer done :void))
        (objc-call panel "makeKeyAndOrderFront:" :pointer (cffi:null-pointer) :void)
        (let ((session (objc-call app "beginModalSessionForWindow:" :pointer panel :pointer)))
          (unwind-protect
               (loop while (/= 0 (objc-call panel "isVisible" :int))
                     do (objc-call app "runModalSession:" :pointer session :long))
            (objc-call app "endModalSession:" :pointer session :void)))
        (let ((c (objc-call panel "color" :pointer)))
          (if (cffi:null-pointer-p c)
              (values NIL NIL)
              (values (nscolor->rgb c) T)))))))
