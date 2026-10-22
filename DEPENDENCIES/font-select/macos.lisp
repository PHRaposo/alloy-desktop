(in-package #:font-select.macos)

(cffi:define-foreign-library cocoa
  (t (:framework "Cocoa")))

(cffi:define-foreign-library appkit
  (t (:framework "AppKit")))

(cffi:define-foreign-library foundation
  (t (:framework "Foundation")))

(cffi:defctype %id :pointer)
(cffi:defctype %sel :pointer)

(cffi:defcfun ("objc_getClass" %objc-get-class) :pointer
  (name :string))

(cffi:defcfun ("sel_registerName" %sel-register-name) :pointer
  (name :string))

(defmacro %objc-call (self method &rest args)
  (when (stringp self)
    (setf self `(%objc-get-class ,self)))
  (when (evenp (length args))
    (setf args (append args '(%id))))
  (let* ((retval (car (last args)))
         (base-args (list* '%id self
                           '%sel `(%sel-register-name ,method)
                           (loop for (type name) on (butlast args) by #'cddr
                                 collect type collect name))))
    (cond ((find retval '(:double :float))
           ;; arm64 has no objc_msgSend_fpret/_stret; all returns go through objc_msgSend.
           #+arm64 `(cffi:foreign-funcall "objc_msgSend" ,@base-args ,retval)
           #-arm64 `(cffi:foreign-funcall "objc_msgSend_fpret" ,@base-args ,retval))
          (t
           `(cffi:foreign-funcall "objc_msgSend" ,@base-args ,retval)))))

(defun %nsstring (string)
  (%objc-call "NSString" "stringWithUTF8String:" :string string))

(defclass macos (backend)
  ())

(defmethod initialize-instance :after ((backend macos) &key)
  (unless (cffi:foreign-library-loaded-p 'cocoa)
    (cffi:use-foreign-library foundation)
    (cffi:use-foreign-library cocoa)
    (cffi:use-foreign-library appkit)))

(defmethod select-with ((backend macos) &key default (variant :full) &allow-other-keys)
  "Open the native font panel; return a (:family :size :weight :slant) plist or NIL.
VARIANT is accepted for API parity but not yet honoured."
  (declare (ignore variant))
  #+darwin
  (trivial-main-thread:with-body-in-main-thread (:blocking t)
    (float-features:with-float-traps-masked t
      (let* ((app     (%objc-call "NSApplication" "sharedApplication"))
             (manager (%objc-call "NSFontManager" "sharedFontManager"))
             (panel   (%objc-call manager "fontPanel:" :bool t :pointer)))
        (unless (= 0 (%objc-call app "activationPolicy" :long))
          (%objc-call app "setActivationPolicy:" :long 1 :void))
        (when (and default (getf default :family))
          (let* ((face   (%nsstring (getf default :family)))
                 (sz     (coerce (or (getf default :size) 12) 'double-float))
                 (mask   (logior (if (eql (getf default :weight) :bold)   2 0)
                                 (if (eql (getf default :slant)  :italic) 1 0)))
                 (ns-font (%objc-call "NSFont" "fontWithName:size:"
                                      :pointer face :double sz :pointer)))
            (unless (cffi:null-pointer-p ns-font)
              (let ((styled (%objc-call manager "convertFont:toHaveTrait:"
                                        :pointer ns-font :uint64 mask :pointer)))
                (%objc-call manager "setSelectedFont:isMultiple:"
                            :pointer styled :bool nil :void)))))
        ;; "Done" accessory: target=panel, action=performClose: (built-in, no callback).
        (let ((done (%objc-call "NSButton" "buttonWithTitle:target:action:"
                                :pointer (%nsstring "Done")
                                :pointer panel
                                :pointer (%sel-register-name "performClose:")
                                :pointer)))
          (%objc-call panel "setAccessoryView:" :pointer done :void))
        (%objc-call manager "orderFrontFontPanel:" :pointer (cffi:null-pointer) :void)
        (let ((session (%objc-call app "beginModalSessionForWindow:" :pointer panel :pointer)))
          (unwind-protect
               (loop while (/= 0 (%objc-call panel "isVisible" :int))
                     do (%objc-call app "runModalSession:" :pointer session :long))
            (%objc-call app "endModalSession:" :pointer session :void)))
        (let ((selected (%objc-call manager "selectedFont" :pointer)))
          (cond ((cffi:null-pointer-p selected)
                 (values NIL NIL))
                (t
                 (let* ((family     (cffi:foreign-funcall "objc_msgSend"
                                                          %id selected
                                                          %sel (%sel-register-name "familyName")
                                                          :pointer))
                        (family-str (unless (cffi:null-pointer-p family)
                                      (cffi:foreign-funcall "objc_msgSend"
                                                             %id family
                                                             %sel (%sel-register-name "UTF8String")
                                                             :string)))
                        (sz-d       (%objc-call selected "pointSize" :double))
                        (traits     (%objc-call manager "traitsOfFont:" :pointer selected :uint64))
                        (weight     (if (/= 0 (logand traits 2)) :bold :regular))
                        (slant      (if (/= 0 (logand traits 1)) :italic :roman)))
                   (cond ((null family-str)
                          (values NIL NIL))
                         ;; Dot-prefixed virtual families (.AppleSystemUIFont) are not name-resolvable.
                         ((char= #\. (char family-str 0))
                          (values (list :family :system :size (round sz-d) :weight weight :slant slant) T))
                         (t
                          (values (list :family family-str :size (round sz-d) :weight weight :slant slant) T)))))))))))
