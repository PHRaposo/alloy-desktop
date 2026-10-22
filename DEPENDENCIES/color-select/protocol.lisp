(in-package #:color-select)

(defvar *backend-cache* (make-hash-table :test 'eq))
(defvar *default-backend*)

(define-condition color-select-error (error)
  ())

(defun default-backend ()
  (if (boundp '*default-backend*)
      *default-backend*
      (setf *default-backend* (determine-default-backend))))

(defun choose-color (&rest args &key title default backend full-open prevent-full-open)
  "Open the native colour picker. Returns (values COLOR SUCCESS).

COLOR is a list (R G B) of single-floats in [0,1], or NIL.
DEFAULT, when given, is a list (R G B) to preselect.
FULL-OPEN T shows the expanded picker; NIL shows the basic palette only.
PREVENT-FULL-OPEN T hides the expand button (palette-only).
FULL-OPEN/PREVENT-FULL-OPEN apply to the win32 and macos backends.
If no BACKEND is specified, *DEFAULT-BACKEND* is used."
  (declare (ignore title default full-open prevent-full-open))
  (restart-case (apply #'choose-color-with (or backend (default-backend)) args)
    (continue ()
      :report "Cancel the call by returning NIL"
      (values NIL NIL))))

(defclass backend () ())

(defun get-backend (class)
  (or (gethash class *backend-cache*)
      (setf (gethash class *backend-cache*)
            (make-instance class))))

(defgeneric finalize (backend))
(defgeneric choose-color-with (backend &key title default &allow-other-keys))

(defmethod finalize ((backend symbol))
  (finalize (find-class backend)))

(defmethod choose-color-with ((backend symbol) &rest args)
  (apply #'choose-color-with (find-class backend) args))

(defmethod finalize ((backend class))
  (let ((instance (gethash backend *backend-cache*)))
    (when instance (finalize instance))))

(defmethod choose-color-with ((backend class) &rest args &key (title "Select Color"))
  (apply #'choose-color-with (get-backend backend) :title title args))

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
      (format *error-output* "[color-select] subprocess ~A failed: ~A~%"
              program (princ-to-string c))
      nil)))

(defun parse-hex-color (string)
  "Parse \"RRGGBB\" or \"#RRGGBB\" into (R G B) floats, or NIL."
  (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\#) (or string ""))))
    (when (= 6 (length trimmed))
      (handler-case
          (list (float (/ (parse-integer trimmed :start 0 :end 2 :radix 16) 255.0))
                (float (/ (parse-integer trimmed :start 2 :end 4 :radix 16) 255.0))
                (float (/ (parse-integer trimmed :start 4 :end 6 :radix 16) 255.0)))
        (parse-error (c)
          (format *error-output* "[color-select] bad hex colour ~S: ~A~%" trimmed (princ-to-string c))
          nil)))))

(defun parse-color-string (string)
  "Parse \"#RRGGBB\", \"rgb(R,G,B)\" or \"rgba(R,G,B,A)\" into (R G B) floats, or NIL."
  (let ((s (string-trim '(#\Space #\Newline #\Tab) (or string ""))))
    (cond
      ((zerop (length s)) nil)
      ((char= #\# (char s 0))
       (parse-hex-color s))
      ((and (>= (length s) 4)
            (or (string-equal s "rgb(" :end1 4)
                (and (>= (length s) 5) (string-equal s "rgba(" :end1 5))))
       (let* ((open  (position #\( s))
              (close (position #\) s))
              (body  (subseq s (1+ open) close))
              (parts (loop for start = 0 then (1+ comma)
                           for comma = (position #\, body :start start)
                           collect (string-trim '(#\Space) (subseq body start comma))
                           while comma)))
         (when (>= (length parts) 3)
           (handler-case
               (list (float (/ (parse-integer (first parts)) 255.0))
                     (float (/ (parse-integer (second parts)) 255.0))
                     (float (/ (parse-integer (third parts)) 255.0)))
             (parse-error (c)
               (format *error-output* "[color-select] bad rgb colour ~S: ~A~%" s (princ-to-string c))
               nil)))))
      (t (parse-hex-color s)))))

(defun color->hex (color)
  "Format a (R G B) list as \"#RRGGBB\"."
  (format nil "#~2,'0X~2,'0X~2,'0X"
          (round (* 255 (first color)))
          (round (* 255 (second color)))
          (round (* 255 (third color)))))
