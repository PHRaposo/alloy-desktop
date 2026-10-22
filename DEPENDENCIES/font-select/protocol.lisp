(in-package #:font-select)

(defvar *backend-cache* (make-hash-table :test 'eq))
(defvar *default-backend*)

(define-condition font-select-error (error)
  ())

(defun default-backend ()
  (if (boundp '*default-backend*)
      *default-backend*
      (setf *default-backend* (determine-default-backend))))

(defun select (&rest args &key default backend variant)
  "Open a native font selection dialog.

DEFAULT and the returned FONT-PLIST share one shape:
`(:family STRING :size INTEGER :weight (:regular|:bold) :slant (:roman|:italic))`.
On macOS the system font is returned as `(:family :system ...)` (the literal
\".AppleSystemUIFont\" is not name-resolvable; the caller re-resolves).
VARIANT is one of :FULL (default), :COMPACT, :MINIMAL — selects how many widgets
the native dialog exposes. Honoured by the win32 backend; ignored by yad (and
by macos for now, until the validModesForFontPanel: bridge is implemented).
Returns (values FONT-PLIST T) on OK, (values NIL NIL) on cancel."
  (declare (ignore default variant))
  (restart-case (apply #'select-with (or backend (default-backend)) args)
    (continue ()
      :report "Cancel the call by returning NIL"
      (values NIL NIL))))

(defclass backend () ())

(defun get-backend (class)
  (or (gethash class *backend-cache*)
      (setf (gethash class *backend-cache*)
            (make-instance class))))

(defgeneric finalize (backend))
(defgeneric select-with (backend &key default &allow-other-keys))

(defmethod finalize ((backend symbol))
  (finalize (find-class backend)))

(defmethod select-with ((backend symbol) &rest args)
  (apply #'select-with (find-class backend) args))

(defmethod finalize ((backend class))
  (let ((instance (gethash backend *backend-cache*)))
    (when instance (finalize instance))))

(defmethod select-with ((backend class) &rest args)
  (apply #'select-with (get-backend backend) args))

(defmethod finalize ((backend backend)))

(defmethod finalize :after ((backend backend))
  (remhash (class-of backend) *backend-cache*))

(defmethod finalize ((all (eql T)))
  (mapc #'finalize (loop for v being the hash-values of *backend-cache* collect v)))

(defun run (program &rest args)
  ;; Print a real subprocess failure (e.g. program missing) and return NIL;
  ;; :ignore-error-status keeps a non-zero exit a value, not an error.
  (handler-case
      (multiple-value-bind (output error status)
          (uiop:run-program (list* program (remove NIL args))
                            :output :string
                            :ignore-error-status T
                            :external-format :utf-8)
        (declare (ignore error))
        (values output status))
    (error (c)
      (format *error-output* "[font-select] subprocess ~A failed: ~A~%"
              program (princ-to-string c))
      nil)))

(defun split (char string)
  (let ((parts ())
        (buffer (make-string-output-stream)))
    (flet ((maybe-commit ()
             (let ((s (get-output-stream-string buffer)))
               (when (string/= s "")
                 (push s parts)))))
      (loop for c across string
            do (if (char= c char)
                   (maybe-commit)
                   (write-char c buffer))
            finally (maybe-commit)))
    (nreverse parts)))

(defparameter *pango-style-words*
  ;; Pango style/variant/weight/stretch/gravity keywords, lowercased.
  '("normal" "roman" "oblique" "italic" "small-caps" "all-small-caps"
    "petite-caps" "all-petite-caps" "unicase" "title-caps"
    "thin" "ultra-light" "extra-light" "light" "semi-light" "demi-light"
    "book" "regular" "medium" "semi-bold" "demi-bold" "demibold" "bold"
    "ultra-bold" "extra-bold" "heavy" "black" "ultra-heavy" "extra-black"
    "ultra-condensed" "extra-condensed" "condensed" "semi-condensed"
    "semi-expanded" "expanded" "extra-expanded" "ultra-expanded"
    "not-rotated" "south" "upside-down" "north" "rotated-left" "east"
    "rotated-right" "west"))

(defun %style-word-p (token)
  (member (string-downcase token) *pango-style-words* :test #'string=))

(defun %weight-bold-p (token)
  (member (string-downcase token)
          '("semi-bold" "demi-bold" "demibold" "bold" "ultra-bold" "extra-bold"
            "heavy" "black" "ultra-heavy" "extra-black")
          :test #'string=))

(defun %slant-italic-p (token)
  (member (string-downcase token) '("italic" "oblique") :test #'string=))

(defun %numeric-token-p (token)
  (and (plusp (length token))
       (every (lambda (c) (or (digit-char-p c) (char= c #\.))) token)
       (find-if #'digit-char-p token)))

(defun %pango-string->plist (string)
  "Parse a Pango 'FAMILY [STYLE-WORDS] [SIZE]' string into
(:family STRING :size INTEGER :weight (:regular|:bold) :slant (:roman|:italic)).
NIL if empty after trim. Walks right-to-left: trailing numeric = size,
then trailing Pango style keywords, the remainder is the family."
  (let ((s (string-trim '(#\Space #\Newline #\Tab) (or string ""))))
    (when (plusp (length s))
      (let ((tokens (split #\Space s))
            (size 12) (weight :regular) (slant :roman))
        (when (and tokens (%numeric-token-p (car (last tokens))))
          (let ((n (read-from-string (car (last tokens)) nil nil)))
            (when (realp n) (setf size (round n))))
          (setf tokens (butlast tokens)))
        (loop for w = (and tokens (car (last tokens)))
              while (and w (%style-word-p w))
              do (when (%weight-bold-p w) (setf weight :bold))
                 (when (%slant-italic-p w) (setf slant :italic))
                 (setf tokens (butlast tokens)))
        (let ((family (format nil "~{~A~^ ~}" tokens)))
          (when (plusp (length family))
            (list :family family :size size :weight weight :slant slant)))))))
