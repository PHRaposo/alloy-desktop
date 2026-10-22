(in-package #:color-select.win32)

(cffi:define-foreign-library comdlg32
  (:windows "Comdlg32.dll"))

(cffi:defcstruct choosecolorw
  (struct-size      :uint32)
  (hwnd-owner       :pointer)
  (h-instance       :pointer)
  (rgb-result       :uint32)
  (lp-cust-colors   :pointer)
  (flags            :uint32)
  (l-cust-data      :pointer)
  (lpfn-hook        :pointer)
  (lp-template-name :pointer))

(cffi:defcfun ("ChooseColorW" %choose-color-w) :int
  (lpcc :pointer))

(defconstant +cc-rgb-init+          #x00000001)
(defconstant +cc-full-open+         #x00000002)
(defconstant +cc-prevent-full-open+ #x00000004)
(defconstant +cc-any-color+         #x00000100)

(defclass win32 (backend)
  ())

(defmethod initialize-instance :after ((backend win32) &key)
  (unless (cffi:foreign-library-loaded-p 'comdlg32)
    (cffi:load-foreign-library 'comdlg32)))

(defun rgb->colorref (color)
  (let ((r (round (* 255 (first color))))
        (g (round (* 255 (second color))))
        (b (round (* 255 (third color)))))
    (logior r (ash g 8) (ash b 16))))

(defun colorref->rgb (cref)
  (list (float (/ (logand cref #xFF) 255.0))
        (float (/ (logand (ash cref -8) #xFF) 255.0))
        (float (/ (logand (ash cref -16) #xFF) 255.0))))

(defmethod choose-color-with ((backend win32) &key default (full-open t) prevent-full-open
                              &allow-other-keys)
  (cffi:with-foreign-objects ((cc '(:struct choosecolorw))
                              (cust :uint32 16))
    (dotimes (i 16)
      (setf (cffi:mem-aref cust :uint32 i) #x00FFFFFF))
    (cffi:with-foreign-slots ((struct-size hwnd-owner h-instance rgb-result
                               lp-cust-colors flags l-cust-data lpfn-hook
                               lp-template-name)
                              cc (:struct choosecolorw))
      (setf struct-size      (cffi:foreign-type-size '(:struct choosecolorw))
            hwnd-owner       (cffi:null-pointer)
            h-instance       (cffi:null-pointer)
            rgb-result       (if default (rgb->colorref default) 0)
            lp-cust-colors   cust
            flags            (logior +cc-any-color+
                                     (if default            +cc-rgb-init+          0)
                                     (if full-open          +cc-full-open+         0)
                                     (if prevent-full-open  +cc-prevent-full-open+ 0))
            l-cust-data      (cffi:null-pointer)
            lpfn-hook        (cffi:null-pointer)
            lp-template-name (cffi:null-pointer))
      (if (/= 0 (%choose-color-w cc))
          (values (colorref->rgb
                   (cffi:foreign-slot-value cc '(:struct choosecolorw) 'rgb-result))
                  T)
          (values NIL NIL)))))
