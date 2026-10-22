(in-package #:paper-print)

(define-condition paper-print-error (error)
  ((operation :initarg :operation :reader paper-print-operation)
   (code :initarg :code :reader paper-print-code))
  (:report (lambda (condition stream)
             (format stream "Paper printing failed during ~A (code ~A)."
                     (paper-print-operation condition)
                     (paper-print-code condition)))))

(define-condition paper-print-backend-error (paper-print-error) ()
  (:documentation
   "A native printing operation reported failure: no printer, a refused device
context, or a page the platform rejected.  PRINT-IMAGE-PAGES reports it as the
:FAILED status and PAPER-GEOMETRY answers it with its deterministic fallback.
Only the library signals this type; a condition of the parent type signalled by
caller code stays a caller condition and propagates."))

(define-condition paper-print-argument-error (paper-print-error)
  ((field :initarg :field :reader paper-print-field)
   (detail :initarg :detail :reader paper-print-detail))
  (:default-initargs :operation :invalid-argument :code nil)
  (:report (lambda (condition stream)
             (format stream "Invalid ~A: ~A"
                     (paper-print-field condition)
                     (paper-print-detail condition))))
  (:documentation
   "A caller supplied an argument the library cannot use.  Always signalled and
never turned into a status: it reports a programming defect, not a printing
outcome."))

(defun %fail (operation code)
  (error 'paper-print-backend-error :operation operation :code code))

(defun %bad-argument (field control &rest arguments)
  (error 'paper-print-argument-error
         :field field :detail (apply #'format nil control arguments)))

(defstruct (raster-page
            (:constructor %make-raster-page
                (width height stride origin data logical-width logical-height)))
  (width 0 :type (integer 1))
  (height 0 :type (integer 1))
  (stride 0 :type (integer 4))
  (origin :top-left :type (member :top-left :bottom-left))
  (data #() :type (simple-array (unsigned-byte 8) (*)))
  (logical-width 0 :type real)
  (logical-height 0 :type real))

(defun make-raster-page (width height data
                         &key (stride (* width 4)) (origin :top-left)
                           (logical-width width) (logical-height height))
  "Create a validated straight-alpha RGBA raster page."
  (check-type width (integer 1))
  (check-type height (integer 1))
  (check-type stride (integer 4))
  (check-type origin (member :top-left :bottom-left))
  (check-type data (simple-array (unsigned-byte 8) (*)))
  (check-type logical-width (real (0)))
  (check-type logical-height (real (0)))
  (when (< stride (* width 4))
    (%bad-argument :stride "~D is smaller than the RGBA row width ~D."
                   stride (* width 4)))
  (when (< (length data) (* stride height))
    (%bad-argument :data "~D bytes are fewer than the ~D bytes required."
                   (length data) (* stride height)))
  (%make-raster-page width height stride origin data logical-width logical-height))
