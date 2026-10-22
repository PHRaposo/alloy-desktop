(in-package #:os-fonts)

(define-condition os-fonts-error (error) ())

(defstruct (font-spec
             (:constructor make-font-spec
                 (&key role family native-family size
                       (weight :regular) (slant :roman) source)))
  role family native-family size weight slant source)

(defstruct (font-state
             (:constructor make-font-state
                 (&key fonts logical-dpi source dpi-awareness metrics)))
  fonts logical-dpi source
  ;; DPI-AWARENESS says whether LOGICAL-DPI can be trusted.  On Windows a
  ;; DPI-unaware process is fed a virtualized 96 dpi while the display really
  ;; runs at, say, 120 -- a consumer computing px = pt * dpi/72 would then be
  ;; 20% short with no error anywhere.  Backends whose platform has no such
  ;; notion report :NOT-APPLICABLE.  The library never CHANGES this: process
  ;; DPI awareness is a global, one-way attribute of the host.
  dpi-awareness
  ;; METRICS is a portable plist of native UI metrics in device pixels, e.g.
  ;; :MENU-BAR-HEIGHT, :MENU-ITEM-HEIGHT, :CAPTION-HEIGHT.  A backend that
  ;; cannot supply a key states its absence explicitly rather than omitting it.
  metrics)

(defclass backend ()
  ((state :initform nil :accessor %state)
   (generation :initform 0 :accessor generation)
   (listeners :initform nil :accessor %listeners)
   (last-poll-ticks :initform 0 :accessor %last-poll-ticks)))

(defvar *backend-cache* (make-hash-table :test 'eq))
(defvar *default-backend*)

(defun default-backend ()
  (get-backend
   (if (boundp '*default-backend*)
       *default-backend*
       (setf *default-backend* (determine-default-backend)))))

(defun get-backend (designator)
  (etypecase designator
    (backend designator)
    (symbol (get-backend (find-class designator)))
    (class
     (or (gethash designator *backend-cache*)
         (setf (gethash designator *backend-cache*)
               (make-instance designator))))))

(defgeneric query-state (backend)
  (:documentation "Read and return the current native font state for BACKEND."))

(defgeneric finalize (backend))

(defgeneric %native-advance-block (backend family ppem bold italic block)
  (:documentation "Return 256 native whole-pixel character advances, or NIL."))

(defmethod %native-advance-block ((backend backend) family ppem bold italic block)
  (declare (ignore backend family ppem bold italic block))
  nil)

(defmethod finalize ((backend backend)))

(defmethod finalize :after ((backend backend))
  (remhash (class-of backend) *backend-cache*))

(defmethod finalize ((backend symbol))
  (finalize (find-class backend)))

(defmethod finalize ((backend class))
  (let ((instance (gethash backend *backend-cache*)))
    (when instance (finalize instance))))

(defmethod finalize ((all (eql t)))
  (mapc #'finalize
        (loop for v being the hash-values of *backend-cache* collect v)))

(defun %backend (&optional backend)
  (get-backend (or backend (default-backend))))

(defun %notify-change (backend old new)
  (dolist (fn (copy-list (%listeners backend)))
    (handler-case
        (funcall fn backend old new (generation backend))
      (error (c)
        (format *error-output* "[os-fonts] listener failed: ~A~%" c)))))

(defun refresh (&optional backend)
  "Re-read native font roles. Returns (values STATE CHANGED-P).
If the state changed, increment GENERATION and invoke listeners synchronously."
  (let* ((b (%backend backend))
         (old (%state b))
         (new (query-state b))
         (changed (not (equalp old new))))
    ;; REFRESH is itself a native read.  Record it as the latest poll time so an
    ;; immediate POLL does not query the OS again merely because the process has
    ;; existed longer than POLL's interval.
    (setf (%last-poll-ticks b) (get-internal-real-time))
    (when changed
      (setf (%state b) new)
      (incf (generation b))
      (%notify-change b old new))
    (values (%state b) changed)))

(defun poll (&key backend (interval 0.5d0) force)
  "Cheap event-loop hook. Re-read the OS only when INTERVAL seconds elapsed.
No background thread is created; change listeners therefore run on the caller's thread."
  (let* ((b (%backend backend))
         (now (get-internal-real-time))
         (period (* interval internal-time-units-per-second)))
    (when (or force
              (null (%state b))
              (>= (- now (%last-poll-ticks b)) period))
      (setf (%last-poll-ticks b) now)
      (return-from poll (refresh b)))
    (values (%state b) nil)))

(defun snapshot (&optional backend)
  (let ((b (%backend backend)))
    (or (%state b) (nth-value 0 (refresh b)))))

(defun font-for-role (role &optional backend)
  "Return the native FONT-SPEC for ROLE, or NIL when the backend has no such role."
  (cdr (assoc role (font-state-fonts (snapshot backend)) :test #'eq)))

(defun system-font (&optional backend)
  (font-for-role :system backend))

(defun system-fixed-font (&optional backend)
  (font-for-role :system-fixed backend))

(defun logical-dpi (&optional backend)
  (font-state-logical-dpi (snapshot backend)))

(defun dpi-awareness (&optional backend)
  "Whether LOGICAL-DPI is trustworthy on this platform/process. See FONT-STATE."
  (font-state-dpi-awareness (snapshot backend)))

(defun metrics (&optional backend)
  "Plist of native UI metrics in device pixels. See FONT-STATE."
  (font-state-metrics (snapshot backend)))

(defun metric (key &optional backend)
  "One native UI metric, e.g. (METRIC :MENU-BAR-HEIGHT). NIL when unavailable."
  (getf (metrics backend) key))

(defun native-advance-block (family ppem bold italic block &optional backend)
  "Return the OS-native whole-pixel advances for one 256-character BLOCK.

FAMILY names the requested face, PPEM is its device-pixel height, and BOLD and
ITALIC describe its style. The result is a 256-element signed integer vector,
or NIL when the backend cannot provide an exact native table."
  (check-type family string)
  (check-type ppem (integer 1 *))
  (check-type block (integer 0 *))
  (%native-advance-block (%backend backend) family ppem bold italic block))

(defun add-change-listener (function &optional backend)
  "Register FUNCTION as (lambda (backend old-state new-state generation) ...)."
  (let ((b (%backend backend)))
    (pushnew function (%listeners b) :test #'eq)
    function))

(defun remove-change-listener (function &optional backend)
  (let ((b (%backend backend)))
    (setf (%listeners b) (delete function (%listeners b) :test #'eq))
    function))
