(in-package #:org.shirakumo.alloy.renderers.simple)

(defgeneric call-with-pushed-transforms (function renderer &key clear))
(defgeneric clip (renderer extent))
(defgeneric translate (renderer point))
(defgeneric scale (renderer size))
(defgeneric rotate (renderer phi))
(defgeneric z-index (renderer))
(defgeneric (setf z-index) (z-index renderer))

(defgeneric clear (renderer bounds))
(defgeneric composite-mode (renderer))
(defgeneric (setf composite-mode) (mode renderer))

(defgeneric line-strip (renderer points &key pattern line-width line-style join-style cap-style &allow-other-keys))
(defgeneric curve (renderer points &key pattern line-width line-style join-style cap-style &allow-other-keys))
(defgeneric rectangle (renderer bounds &key pattern corner-radii line-width line-style join-style cap-style &allow-other-keys))
(defgeneric ellipse (renderer bounds &key pattern start-angle end-angle line-width line-style join-style cap-style &allow-other-keys))
(defgeneric polygon (renderer points &key pattern &allow-other-keys))
(defgeneric icon (renderer bounds image &key size halign valign &allow-other-keys))
(defgeneric text (renderer bounds string &key pattern font size halign valign direction wrap markup &allow-other-keys))
(defgeneric cursor (renderer text position &key pattern &allow-other-keys))
(defgeneric selection (renderer text start end &key pattern &allow-other-keys))

(defgeneric image-pattern (renderer image &key scaling offset mode &allow-other-keys))
(defgeneric request-font (renderer family &key slant spacing weight stretch &allow-other-keys))
(defgeneric request-image (renderer data &key size channels &allow-other-keys))
(defgeneric request-gradient (renderer type start stop stops &key &allow-other-keys))

(defclass renderer (alloy:renderer)
  ((composite-mode :initform :source-over :accessor composite-mode)))

(defmacro with-pushed-transforms ((renderer &rest args) &body body)
  `(call-with-pushed-transforms (lambda () ,@body) ,renderer ,@args))

(defmethod alloy:constrain-visibility ((extent alloy:extent) (renderer renderer))
  (call-next-method)
  ;; constrain-visibility's extent is in the global frame, so we need to
  ;; temporarily reset the transforms to the identity while we do the clip.
  (let ((old (transform-matrix renderer)))
    (setf (transform-matrix renderer) (identity-matrix renderer))
    (clip renderer extent)
    (setf (transform-matrix renderer) old)))

(defmethod alloy:render :around ((renderer renderer) (layout alloy:layout-element))
  (with-pushed-transforms (renderer)
    (let ((old (alloy:visible-bounds renderer)))
      (setf (alloy:visible-bounds renderer) (alloy::copy-extent old))
      (unwind-protect
           (progn
             (translate renderer (alloy:bounds layout))
             (call-next-method))
        (setf (alloy:visible-bounds renderer) old)))))

(defun normalize-pattern-table (table)
  ;; state is a bitfield of [ ACTIVATED DISABLED STRONG WEAK ]
  (labels ((normalize (array)
             (loop for i downfrom #b1111 to #b0000
                   ; We ignore the #b__11 case because the focus can never be both strong and weak.
                   do (unless (or (svref array i) (= #b11 (logand i #b0011)))
                        (setf (aref array i)
                              (or (svref array (logand i #b1100))
                                  (svref array (logand i #b0011))
                                  (svref array (logand i #b0000))))))))
    (loop for k being the hash-keys of table using (hash-value v)
          do (when v (normalize v))))
  table)

(defclass palette (alloy:observable)
  ((patterns :initform (make-hash-table :test 'eql) :accessor patterns)))

(defmethod describe-object :after ((palette palette) stream)
  (format stream "~&~%Patterns:~%")
  (loop for name being the hash-keys of (patterns palette) using (hash-value patterns)
        do (format stream "  ~a:~%" name)
           (loop for i from 0 below (length patterns)
                 for val = (aref patterns i)
                 do (when val (format stream "    ~5,'0b: ~a~%" i val)))))

(defmethod shared-initialize :after ((palette palette) slots &key (patterns NIL patterns-p))
  (when patterns-p
    (etypecase patterns
      (hash-table
       (setf (patterns palette) (normalize-pattern-table patterns)))
      (list
       (clrhash (patterns palette))
       (loop with state = #b0000
             for thing in patterns
             if (listp thing)
             collect (destructuring-bind (k v) thing
                       (setf (find-pattern k palette :state state) v))
             else do (etypecase thing
                       (symbol (setf state thing))
                       (integer (setf state thing))))
       (normalize-pattern-table (patterns palette))))))

(defgeneric find-pattern (name palette &key state default))
(defgeneric (setf find-pattern) (value name palette &key state default))
(defgeneric element-palette-state (element))

(org.shirakumo.alloy.observables:define-activity find-pattern palette (name))

(defclass palette-element (alloy:element)
  ((palette :initarg :palette :initform NIL :accessor palette)))

(defmethod (setf palette) ((name symbol) (element palette-element))
  (setf (palette element) (palette name)))
