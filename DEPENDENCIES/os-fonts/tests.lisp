(defpackage #:os-fonts.tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:os-fonts.tests)

(defvar *failures* nil)
(defvar *test-counts* nil)

(defun %record-failure (category description condition)
  (push (list category description condition) *failures*)
  (format *error-output* "[os-fonts/tests] ~A: ~A -- ~A~%"
          category description condition))

(defmacro check (category description &body body)
  `(progn
     (incf (gethash ,category *test-counts* 0))
     (handler-case
         (unless (progn ,@body)
           (error "check returned NIL"))
       (condition (c)
         (%record-failure ,category ,description c)))))

(defun %category-count (category)
  (count category *failures* :key #'first :test #'eq))

(defun %same-font-values-p (a b)
  (and (string= (os-fonts:font-spec-family a)
                (os-fonts:font-spec-family b))
       (equal (os-fonts:font-spec-native-family a)
              (os-fonts:font-spec-native-family b))
       (= (os-fonts:font-spec-size a)
          (os-fonts:font-spec-size b))
       (eq (os-fonts:font-spec-weight a)
           (os-fonts:font-spec-weight b))
       (eq (os-fonts:font-spec-slant a)
           (os-fonts:font-spec-slant b))))

(defun %run-contract-tests (backend state)
  (check :contract "snapshot returns FONT-STATE"
    (typep state 'os-fonts:font-state))
  (dolist (role '(:system :system-fixed :menu :control :dialog-default
                  :label :tooltip :text))
    (check :contract (format nil "role ~S has a valid FONT-SPEC" role)
      (let ((spec (os-fonts:font-for-role role backend)))
        (and (typep spec 'os-fonts:font-spec)
             (eq role (os-fonts:font-spec-role spec))
             (stringp (os-fonts:font-spec-family spec))
             (plusp (length (os-fonts:font-spec-family spec)))
             (realp (os-fonts:font-spec-size spec))
             (plusp (os-fonts:font-spec-size spec))))))
  #+linux
  (let ((system (os-fonts:font-for-role :system backend)))
    (dolist (role '(:menu :control :dialog-default :label :tooltip :text))
      (check :contract (format nil "GTK-inherited role ~S matches :SYSTEM" role)
        (%same-font-values-p system (os-fonts:font-for-role role backend)))))
  #+win32
  (let* ((dialog (os-fonts:font-for-role :dialog-default backend))
         (family (os-fonts:font-spec-family dialog))
         (advances (os-fonts:native-advance-block
                    family 13 nil nil 0 backend))
         (italic-advances (os-fonts:native-advance-block
                           family 13 nil t 0 backend)))
    (when (string-equal "MS Shell Dlg"
                        (os-fonts:font-spec-native-family dialog))
      (check :contract "MS Shell Dlg resolves to the realized family"
        (not (string-equal (os-fonts:font-spec-family dialog)
                           (os-fonts:font-spec-native-family dialog)))))
    (check :contract "Win32 native advance block has 256 entries"
      (and (vectorp advances) (= 256 (length advances))))
    (check :contract "Win32 native advance block contains integers"
      (and (vectorp advances) (every #'integerp advances)))
    (check :contract "Win32 italic native advance block has 256 entries"
      (and (vectorp italic-advances) (= 256 (length italic-advances)))))
  #+darwin
  ;; Same masking QUERY-STATE needs: these assertions call AppKit directly and
  ;; would otherwise die in CTFontGetAscent under SBCL's armed FP traps.
  (float-features:with-float-traps-masked t
    ;; Scale-independent by construction: both sides are read at runtime, so
    ;; this passes as 72 on a non-Retina screen and as 144 at 2x.  It fails if
    ;; LOGICAL-DPI is ever pinned to a constant again.
    (check :contract "logical DPI is 72 x the main screen backing scale"
      (= (os-fonts:logical-dpi backend)
         (* 72d0 (or (os-fonts.macos::%backing-scale-factor) 1d0))))
    ;; End-to-end through %FONT-SPEC: a role selector AppKit guarantees is bold
    ;; must not come back :REGULAR, which is what the fabricated value did.
    (check :contract "boldSystemFontOfSize: is reported bold"
      (let ((spec (os-fonts.macos::%font-spec :system "boldSystemFontOfSize:")))
        (and (eq :bold (os-fonts:font-spec-weight spec))
             (eq :roman (os-fonts:font-spec-slant spec)))))
    (check :contract "systemFontOfSize: is reported regular roman"
      (let ((spec (os-fonts.macos::%font-spec :system "systemFontOfSize:")))
        (and (eq :regular (os-fonts:font-spec-weight spec))
             (eq :roman (os-fonts:font-spec-slant spec)))))
    ;; The italic bit has no NSFont class selector to reach it, so it is checked
    ;; on the descriptor of named faces that ship with every macOS.  Also pins
    ;; the uint32 marshalling: Helvetica's traits are #x80000000, which a signed
    ;; return type would hand back negative.
    (dolist (case '(("Helvetica" nil nil) ("Helvetica-Bold" t nil)
                    ("Helvetica-Oblique" nil t) ("Helvetica-BoldOblique" t t)))
      (destructuring-bind (name bold italic) case
        (check :contract (format nil "symbolicTraits of ~A" name)
          (let* ((ns (os-fonts.macos::%objc-call
                      "NSString" "stringWithUTF8String:" :string name :pointer))
                 (font (os-fonts.macos::%objc-call
                        "NSFont" "fontWithName:size:" :pointer ns
                        :double 13d0 :pointer))
                 (traits (os-fonts.macos::%symbolic-traits font)))
            (and (not (cffi:null-pointer-p font))
                 (not (minusp traits))
                 (eq bold (and (logtest traits #x2) t))
                 (eq italic (and (logtest traits #x1) t)))))))
    (check :contract "menu bar height is a plausible macOS menu bar"
      (<= 20 (os-fonts:metric :menu-bar-height backend) 40))
    (check :contract "scroller thickness is a plausible NSScroller width"
      (let ((w (os-fonts:metric :scroll-width backend)))
        (and (eql w (os-fonts:metric :scroll-height backend))
             (<= 8 w 40)))))
  (check :contract "logical DPI is positive metadata"
    (and (realp (os-fonts:logical-dpi backend))
         (plusp (os-fonts:logical-dpi backend))))
  #+linux
  (check :contract "Linux DPI awareness is not applicable"
    (eq :not-applicable (os-fonts:dpi-awareness backend)))
  (dolist (key '(:menu-bar-height :menu-item-height :menu-item-width
                 :caption-height :sm-caption-height :border-width
                 :padded-border-width :scroll-width :scroll-height))
    (check :contract (format nil "metrics plist states ~S explicitly" key)
      (loop for tail on (os-fonts:metrics backend) by #'cddr
            thereis (eq (car tail) key)))))

#+linux
(defun %parse-result (string)
  (multiple-value-list (os-fonts.linux::%parse-font-name string)))

#+linux
(defun %run-parse-tests ()
  (dolist (case '(("Noto Sans 10" "Noto Sans" 10d0 :regular :roman)
                  ("DejaVu Sans Bold Italic 11.5"
                   "DejaVu Sans" 11.5d0 :bold :italic)
                  ("IBM Plex Sans Semi-Bold Oblique 9.25"
                   "IBM Plex Sans" 9.25d0 :bold :italic)
                  ("Source Code Pro 12" "Source Code Pro" 12d0 :regular :roman)))
    (destructuring-bind (input family size weight slant) case
      (check :parse (format nil "parse gtk-font-name ~S" input)
        (destructuring-bind (got-family got-size got-weight got-slant)
            (%parse-result input)
          (and (string= family got-family)
               (= size got-size)
               (eq weight got-weight)
               (eq slant got-slant))))))
  (dolist (case '((98304 96d0) (122880 120d0) (-1 96d0) (0 96d0) (nil 96d0)))
    (destructuring-bind (fixed expected) case
      (check :parse (format nil "gtk-xft-dpi normalization ~S" fixed)
        (= expected (os-fonts.linux::%gtk-xft-dpi->dpi fixed))))))

#+linux
(defun %run-linux-tests (backend)
  (let* ((settings (os-fonts.linux::%settings))
         (font-before (os-fonts.linux::%gobject-get-string settings "gtk-font-name"))
         (dpi-before (os-fonts.linux::%gobject-get-int settings "gtk-xft-dpi")))
    (check :linux "gtk-font-name is readable and non-empty"
      (and (stringp font-before) (plusp (length font-before))))
    (check :linux "gtk-xft-dpi is readable"
      (integerp dpi-before))
    ;; QUERY-STATE must only observe GtkSettings.  It must not write them.
    (os-fonts::query-state backend)
    (check :linux "query-state does not mutate gtk-font-name"
      (equal font-before
             (os-fonts.linux::%gobject-get-string settings "gtk-font-name")))
    (check :linux "query-state does not mutate gtk-xft-dpi"
      (= dpi-before
         (os-fonts.linux::%gobject-get-int settings "gtk-xft-dpi")))
    (let ((sans (os-fonts.linux::%fontconfig-family "Sans"))
          (mono (os-fonts.linux::%fontconfig-family "monospace"))
          (missing (os-fonts.linux::%fontconfig-family
                    "Nonexistent-Test-Font-Family")))
      (check :linux "fontconfig resolves Sans"
        (and (stringp sans) (plusp (length sans))))
      (check :linux "fontconfig resolves monospace"
        (and (stringp mono) (plusp (length mono))))
      (check :linux "fontconfig handles a missing family without failure"
        (and (stringp missing) (plusp (length missing)))))
    (let* ((raw-values (%parse-result font-before))
           (raw-size (second raw-values))
           (system (os-fonts:font-for-role :system backend)))
      (check :linux "provider point size equals GtkSettings point size"
        (= raw-size (os-fonts:font-spec-size system)))
      (check :linux "provider DPI equals gtk-xft-dpi normalization"
        (= (os-fonts.linux::%gtk-xft-dpi->dpi dpi-before)
           (os-fonts:logical-dpi backend))))))

(defclass poll-probe-backend (os-fonts:backend)
  ((count :initform 0 :accessor poll-probe-count)
   (family :initform "A" :accessor poll-probe-family)))

(defmethod os-fonts::query-state ((backend poll-probe-backend))
  (incf (poll-probe-count backend))
  (os-fonts::make-font-state
   :logical-dpi 96d0
   :source :probe
   :dpi-awareness :not-applicable
   :metrics nil
   :fonts (list
           (cons :system
                 (os-fonts::make-font-spec
                  :role :system
                  :family (poll-probe-family backend)
                  :native-family (poll-probe-family backend)
                  :size 10d0
                  :source :probe)))))

(defun %run-poll-tests ()
  (let ((backend (make-instance 'poll-probe-backend))
        (notifications 0))
    ;; Make process uptime exceed the interval before SNAPSHOT.  This catches the
    ;; regression where SNAPSHOT did a native read but left LAST-POLL-TICKS at 0.
    (sleep 0.55d0)
    (os-fonts:snapshot backend)
    (let ((before (poll-probe-count backend)))
      (os-fonts:poll :backend backend :interval 0.5d0)
      (check :poll "poll does no native work immediately after snapshot"
        (= before (poll-probe-count backend))))
    (let ((listener (lambda (&rest ignored)
                      (declare (ignore ignored))
                      (incf notifications))))
      (os-fonts:add-change-listener listener backend)
      (let ((generation-before (os-fonts:generation backend)))
        (setf (poll-probe-family backend) "B")
        (multiple-value-bind (state changed)
            (os-fonts:poll :backend backend :force t)
          (declare (ignore state))
          (check :poll "forced changed poll reports change" changed)
          (check :poll "generation increments exactly once for a change"
            (= (1+ generation-before) (os-fonts:generation backend)))
          (check :poll "listener runs once for a change"
            (= 1 notifications))))
      (let ((generation-before (os-fonts:generation backend))
            (notifications-before notifications))
        (multiple-value-bind (state changed)
            (os-fonts:poll :backend backend :force t)
          (declare (ignore state))
          (check :poll "stable forced poll reports no change" (not changed))
          (check :poll "stable poll does not increment generation"
            (= generation-before (os-fonts:generation backend)))
          (check :poll "stable poll does not notify listeners"
            (= notifications-before notifications))))
      (os-fonts:remove-change-listener listener backend))))

(defun %print-category-marker (label category)
  (let ((tests (gethash category *test-counts* 0)))
    (if (zerop tests)
        (format t "OS_FONT_~A_FAILURES=SKIPPED~%" label)
        (format t "OS_FONT_~A_FAILURES=~D~%" label (%category-count category)))))

(defun run-tests ()
  (let ((*failures* nil)
        (*test-counts* (make-hash-table :test #'eq))
        (backend (os-fonts:default-backend)))
    (unwind-protect
         (let ((state (os-fonts:snapshot backend)))
           (%run-contract-tests backend state)
           #+linux (%run-parse-tests)
           #+linux (%run-linux-tests backend)
           (%run-poll-tests))
      (os-fonts:finalize backend))
    (%print-category-marker "CONTRACT" :contract)
    (%print-category-marker "LINUX" :linux)
    (%print-category-marker "PARSE" :parse)
    (%print-category-marker "POLL" :poll)
    (if *failures*
        (error "os-fonts tests failed: ~D failure~:P" (length *failures*))
        t)))
