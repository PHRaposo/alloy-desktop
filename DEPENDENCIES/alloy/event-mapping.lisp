(in-package #:org.shirakumo.alloy)

(defvar *input-sequence-style* :emacs)

(defun set= (a b)
  ;; obviously very bad for large sets, but these are for modifier sets, which will never be large.
  (and (= (length a) (length b))
       (loop for ae in a
             always (member ae b))))

(defclass event-mapping ()
  ())

(defgeneric event-mapping-equal-p (a b))
(defgeneric event-matches-p (event pattern))
(defgeneric relevant-event-p (event mapping))
(defgeneric map-event (event mapping ui))

(defmethod relevant-event-p ((event event) (mapping event-mapping)) NIL)

(defmethod map-event :around ((event event) (mapping event-mapping) ui)
  (when (relevant-event-p event mapping)
    (call-next-method)))

(defclass sequential-event-mapping (event-mapping)
  ((event-sequence :accessor event-sequence)
   (index :initarg :index :initform 0 :accessor index)))

(defmethod shared-initialize :after ((mapping sequential-event-mapping) slots &key event-sequence)
  (when event-sequence
    (setf (event-sequence mapping) event-sequence)))

(defmethod (setf event-sequence) ((sequence list) (mapping sequential-event-mapping))
  (setf (event-sequence mapping) (coerce sequence 'vector)))

(defmethod event-matches-p ((event event) (pattern event))
  (typep event (type-of pattern)))

(defmethod event-matches-p ((event pointer-event) (pattern pointer-event))
  (and (typep event (type-of pattern))
       (or (null (kind pattern)) (eq (kind event) (kind pattern)))
       (or (null (location pattern)) (point= (location event) (location pattern)))))

(defmethod event-matches-p ((event key-event) (pattern key-event))
  (and (typep event (type-of pattern))
       (or (null (key pattern)) (eq (key event) (key pattern)))
       (or (null (code pattern)) (= (code event) (code pattern)))
       (set= (modifiers event) (modifiers pattern))))

(defmethod event-matches-p ((event key-event) (pattern button-event))
  (and (typep event (type-of pattern))
       (or (null (button pattern)) (eq (button event) (button pattern)))
       (or (null (device pattern)) (eq (device event) (device pattern)))))

(defmethod event-mapping-equal-p ((a event) (b event))
  (eq (type-of a) (type-of b)))

(defmethod event-mapping-equal-p ((a pointer-event) (b pointer-event))
  (and (eq (type-of a) (type-of b))
       (eq (kind a) (kind b))))

(defmethod event-mapping-equal-p ((a scroll) (b scroll))
  (and (equal (dx a) (dx b))
       (equal (dy a) (dy b))))

(defmethod event-mapping-equal-p ((a key-event) (b key-event))
  (and (equal (key a) (key b))
       (equal (code a) (code b))
       (equal (modifiers a) (modifiers b))))

(defmethod event-mapping-equal-p ((a button-event) (b button-event))
  (and (equal (button a) (button b))
       (equal (device a) (device b))))

(defmethod event-mapping-equal-p ((a sequential-event-mapping) (b sequential-event-mapping))
  (loop for ae across (event-sequence a)
        for be across (event-sequence b)
        always (event-mapping-equal-p ae be)))

(defmethod map-event ((event input-event) (mapping sequential-event-mapping) ui)
  (let ((idx (index mapping)))
    (cond ((not (event-matches-p event (aref (event-sequence mapping) idx)))
           ;; TODO: check if we have an earlier partial subsequence match and rewind to that point.
           (setf (index mapping) 0)
           NIL)
          ((= (incf (index mapping)) (length (event-sequence mapping)))
           (setf (index mapping) 0)
           :complete)
          (T
           (setf (index mapping) (1+ idx))
           :matching))))

(defclass input-mapping (sequential-event-mapping)
  ((constructor :initarg :constructor :initform (arg! :constructor) :accessor constructor)
   (context :initarg :context :initform NIL :accessor context)))

(define-print-object (mapping input-mapping)
  "~a~@[ ~a~]~@[ [~a]~]"
  (print-input-sequence (event-sequence mapping) T)
  (typecase (constructor mapping)
    (symbol (constructor mapping)))
  (etypecase (context mapping)
    (null NIL)
    (function "*")
    (symbol (context mapping))))

(defmethod map-event ((event input-event) (mapping input-mapping) ui)
  (when (etypecase (context mapping)
          (null
           T)
          (symbol
           (typep (focused ui) (context mapping)))
          (function
           (funcall (context mapping) ui)))
    (when (eql :complete (call-next-method))
      (handle (funcall (constructor mapping) ui) ui))))

(defmethod relevant-event-p ((event input-event) (mapping input-mapping))
  (typep event (type-of (svref (event-sequence mapping) (index mapping)))))

(defgeneric read-input-sequence (sequence style))
(defgeneric print-input-sequence (sequence style))

(defmethod (setf event-sequence) ((sequence string) (mapping input-mapping))
  (setf (event-sequence mapping) (read-input-sequence sequence T)))

(defmethod read-input-sequence (sequence (style (eql T)))
  (read-input-sequence sequence *input-sequence-style*))

(defmethod print-input-sequence (sequence (style (eql T)))
  (print-input-sequence sequence *input-sequence-style*))

(defun make-input-mapping (event-sequence constructor &key context)
  (make-instance 'input-mapping
                 :constructor (etypecase constructor
                                (function
                                 constructor)
                                (symbol
                                 (lambda (ui)
                                   (declare (ignore ui))
                                   (make-instance constructor))))
                 :event-sequence event-sequence
                 :context context))

(defmacro define-input-mapping (event-sequence event &body initargs)
  (form-fiddle:with-body-options (body initargs context (input-map "default")) initargs
    `(add-mapping (make-input-mapping
                   ,event-sequence
                   (lambda (ui)
                     (declare (ignorable ui))
                     ,@(or body
                           `((make-instance ',event ,@initargs))))
                   :context ,context)
                  ,input-map
                  :if-exists :supersede)))

(defun key-short (key &optional (ui T))
  (case key
    ((:alt :left-alt :right-alt :meta :left-meta :right-meta) "M")
    ((:shift :left-shift :right-shift) "S")
    ((:control :left-control :right-control) "C")
    ((:super :left-super :right-super) "s")
    ((:hyper :left-hyper :right-hyper) "H")
    ((:enter) "RET")
    ((:tab) "TAB")
    ((:delete) "DEL")
    ((:escape) "ESC")
    ((:space) "SPC")
    (T (let* ((s (or (key-text key ui) (string key)))
              (c (char-code (char s 0))))
         (if (and (= (length s) 1)
                  (<= #x20 c #x126))
             (string-downcase s)
             (format NIL "<~:(~a~)>" s))))))

;; FIXME: This is incorrect with regards to input translation layers.
;;        it won't produce the expected code if your layout is not
;;        just US-ANSI. In fact, depending on the layout, many characters
;;        or keys will require a combination of key presses, making this
;;        impossible to designate properly as a single key. Oof.
;;
;;        We also don't consider key translations in the actual mapping
;;        procedure atm. It miiiight be fine to simply change the way key
;;        chords are *displayed* to the user to assume the correct
;;        translation. But that won't fix how the user will have to specify
;;        their own key chords, so... idk what the right thing is here atm.
(defun short-key (short)
  (cond
    ((string= short "M") :alt)
    ((string= short "S") :shift)
    ((string= short "C") :control)
    ((string= short "s") :super)
    ((string= short "H") :hyper)
    ((string= short "RET") :enter)
    ((string= short "TAB") :tab)
    ((string= short "DEL") :delete)
    ((string= short "ESC") :escape)
    ((string= short "SPC") :space)
    ((string= short ";") :semicolon)
    ((string= short "'") :apostrophe)
    ((string= short ",") :comma)
    ((string= short "-") :minus)
    ((string= short ".") :period)
    ((string= short "/") :slash)
    ((string= short "=") :equal)
    ((string= short "[") :left-bracket)
    ((string= short "\\") :backslash)
    ((string= short "]") :right-bracket)
    ((string= short "`") :grave-accent)
    ((= 1 (length short))
     (intern (string-upcase (char short 0)) "KEYWORD"))
    ((and (<= 3 (length short)) (char= #\< (char short 0)) (char= #\> (char short (1- (length short)))))
     (intern (string-upcase (subseq short 1 (1- (length short)))) "KEYWORD"))
    (T :unknown)))

(defmethod read-input-sequence ((sequence string) (style (eql :emacs)))
  (let ((events ()))
    (loop with modifiers = ()
          with i = 0
          do (cond ((<= (length sequence) i)
                    (return))
                   ((and (< i (1- (length sequence)))
                         (char= #\- (char sequence (1+ i))))
                    (push (short-key (subseq sequence i (1+ i))) modifiers)
                    (incf i 2))
                   (T
                    (let* ((next (or (position #\Space sequence :start i) (length sequence)))
                           (short (subseq sequence i next)))
                      ;; TODO: parse mouse and button events
                      (push (make-instance 'key-down
                                           :key (short-key short)
                                           :code NIL
                                           :modifiers modifiers)
                            events)
                      (setf modifiers ())
                      (setf i (1+ next))))))
    (coerce (nreverse events) 'vector)))

(defmethod print-input-sequence ((sequence vector) (style (eql :emacs)))
  (with-output-to-string (out)
    (loop with first = T
          for ev across sequence
          do (unless first
               (write-char #\Space out))
             (setf first NIL)
             (etypecase ev
               (key-event
                (dolist (mod (modifiers ev))
                  (format out "~a-" (key-short mod)))
                (write-string (key-short (key ev)) out))
               (pointer-event
                (format out "<Mouse-~:(~a~)>" (kind ev)))
               (button-event
                (format out "<Button-~:(~a~)>" (button ev)))))))
