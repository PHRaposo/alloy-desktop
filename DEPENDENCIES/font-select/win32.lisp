(in-package #:font-select.win32)

(cffi:define-foreign-library comdlg32
  (:windows "Comdlg32.dll"))

(unless (cffi:foreign-library-loaded-p 'comdlg32)
  (cffi:load-foreign-library 'comdlg32))

(cffi:defcstruct logfontw
  (height           :int32)
  (width            :int32)
  (escapement       :int32)
  (orientation      :int32)
  (weight           :int32)
  (italic           :uint8)
  (underline        :uint8)
  (strike-out       :uint8)
  (charset          :uint8)
  (out-precision    :uint8)
  (clip-precision   :uint8)
  (quality          :uint8)
  (pitch-and-family :uint8)
  (face-name        :uint16 :count 32))

(cffi:defcstruct choosefontw
  (struct-size      :uint32)
  (hwnd-owner       :pointer)
  (hdc              :pointer)
  (lp-log-font      :pointer)
  (point-size       :int32)
  (flags            :uint32)
  (rgb-colors       :uint32)
  (l-cust-data      :pointer)
  (lpfn-hook        :pointer)
  (lp-template-name :pointer)
  (h-instance       :pointer)
  (lp-sz-style      :pointer)
  (font-type        :uint16)
  (___missing       :uint16)
  (size-min         :int32)
  (size-max         :int32))

(cffi:defcfun ("ChooseFontW" %choose-font-w) :int
  (lpcf :pointer))

(defconstant +cf-screen-fonts+     #x00000001)
(defconstant +cf-init-to-logfont+  #x00000040)
(defconstant +cf-effects+          #x00000100)
(defconstant +cf-force-font-exist+ #x00010000)
(defconstant +cf-scalable-only+    #x00020000)
(defconstant +cf-noscriptsel+      #x00800000)

(defconstant +fw-normal+ 400)
(defconstant +fw-bold+   700)

(defun %weight-from-plist (font)
  (if (eql (getf font :weight) :bold) +fw-bold+ +fw-normal+))

(defun %italic-from-plist (font)
  (if (eql (getf font :slant) :italic) 1 0))

(defun %write-wstring-to-buffer (string buffer count)
  "Copy STRING (truncated to COUNT-1 wchars) into BUFFER as null-terminated UTF-16."
  (let ((ws (com:string->wstring string)))
    (unwind-protect
         (let ((n (min (1- count)
                       (loop for i from 0
                             while (/= 0 (cffi:mem-aref ws :uint16 i))
                             count i))))
           (loop for i from 0 below n
                 do (setf (cffi:mem-aref buffer :uint16 i)
                          (cffi:mem-aref ws :uint16 i)))
           (setf (cffi:mem-aref buffer :uint16 n) 0))
      (cffi:foreign-free ws))))

(defun %read-wstring-from-buffer (buffer)
  (let* ((len (loop for i from 0 below 32
                    while (/= 0 (cffi:mem-aref buffer :uint16 i))
                    count i))
         (tmp (cffi:foreign-alloc :uint16 :count (1+ len) :initial-element 0)))
    (unwind-protect
         (progn
           (loop for i from 0 below len
                 do (setf (cffi:mem-aref tmp :uint16 i)
                          (cffi:mem-aref buffer :uint16 i)))
           (com:wstring->string tmp))
      (cffi:foreign-free tmp))))

(defclass win32 (backend)
  ())

(defmethod select-with ((backend win32) &key default (variant :full) &allow-other-keys)
  "VARIANT is :FULL (default), :COMPACT, or :MINIMAL.
:FULL    keeps the standard ChooseFontW panel (family, style, size, effects, script, preview).
:COMPACT adds CF_NOSCRIPTSEL, hiding only the Script dropdown.
:MINIMAL adds CF_NOSCRIPTSEL and clears CF_EFFECTS, hiding Script + Effects + Preview."
  (cffi:with-foreign-objects ((cf '(:struct choosefontw))
                              (lf '(:struct logfontw)))
    (cffi:with-foreign-slots ((height width escapement orientation weight
                               italic underline strike-out charset
                               out-precision clip-precision quality
                               pitch-and-family)
                              lf (:struct logfontw))
      (setf height           (if default (- (or (getf default :size) 12)) -12)
            width            0
            escapement       0
            orientation      0
            weight           (if default (%weight-from-plist default) +fw-normal+)
            italic           (if default (%italic-from-plist default) 0)
            underline        0
            strike-out       0
            charset          1
            out-precision    0
            clip-precision   0
            quality          0
            pitch-and-family 0))
    (let ((face-buf (cffi:foreign-slot-pointer lf '(:struct logfontw) 'face-name)))
      (loop for i from 0 below 32
            do (setf (cffi:mem-aref face-buf :uint16 i) 0))
      (when (and default (getf default :family))
        (%write-wstring-to-buffer (getf default :family) face-buf 32)))
    (cffi:with-foreign-slots ((struct-size hwnd-owner hdc lp-log-font
                               point-size flags rgb-colors l-cust-data
                               lpfn-hook lp-template-name h-instance
                               lp-sz-style font-type ___missing
                               size-min size-max)
                              cf (:struct choosefontw))
      (setf struct-size      (cffi:foreign-type-size '(:struct choosefontw))
            hwnd-owner       (cffi:null-pointer)
            hdc              (cffi:null-pointer)
            lp-log-font      lf
            point-size       (if default (* 10 (or (getf default :size) 12)) 120)
            flags            (logior +cf-screen-fonts+
                                     +cf-force-font-exist+ +cf-scalable-only+
                                     (if (eq variant :minimal) 0 +cf-effects+)
                                     (if (member variant '(:compact :minimal)) +cf-noscriptsel+ 0)
                                     (if default +cf-init-to-logfont+ 0))
            rgb-colors       0
            l-cust-data      (cffi:null-pointer)
            lpfn-hook        (cffi:null-pointer)
            lp-template-name (cffi:null-pointer)
            h-instance       (cffi:null-pointer)
            lp-sz-style      (cffi:null-pointer)
            font-type        0
            ___missing       0
            size-min         0
            size-max         0))
    (let ((ret (%choose-font-w cf)))
      (cond ((zerop ret)
             (values NIL NIL))
            (T
             (let* ((face-buf  (cffi:foreign-slot-pointer lf '(:struct logfontw) 'face-name))
                    (family    (%read-wstring-from-buffer face-buf))
                    (lf-w      (cffi:foreign-slot-value lf '(:struct logfontw) 'weight))
                    (lf-i      (cffi:foreign-slot-value lf '(:struct logfontw) 'italic))
                    (pt-tenths (cffi:foreign-slot-value cf '(:struct choosefontw) 'point-size))
                    (size      (round pt-tenths 10))
                    (weight    (if (>= lf-w 600) :bold :regular))
                    (slant     (if (/= lf-i 0) :italic :roman)))
               (values (list :family family :size size :weight weight :slant slant) T)))))))
