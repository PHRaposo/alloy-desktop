(in-package #:org.shirakumo.alloy.renderers.simple)

(defvar *palettes* (make-hash-table :test 'eql))

(defmacro define-renderer-delegate (function arglist)
  `(defmethod ,function ,(subst '(renderer (eql T)) 'renderer arglist)
     ,(let* ((value (if (consp function) (pop arglist)))
             (funname (if (consp function) (second function) function))
             (call (if (find '&rest arglist)
                       `(apply #',funname ,@(remove '&rest (subst 'alloy:+renderer+ 'renderer arglist)))
                       `(,funname ,@(subst 'alloy:+renderer+ 'renderer arglist)))))
        (if value `(setf ,call ,value) call))))

(define-renderer-delegate call-with-pushed-transforms (function renderer &rest args))
(define-renderer-delegate clip (renderer extent))
(define-renderer-delegate translate (renderer point))
(define-renderer-delegate scale (renderer size))
(define-renderer-delegate rotate (renderer phi))
(define-renderer-delegate z-index (renderer))
(define-renderer-delegate (setf z-index) (value renderer))
(define-renderer-delegate clear (renderer bounds))
(define-renderer-delegate composite-mode (renderer))
(define-renderer-delegate (setf composite-mode) (value renderer))
(define-renderer-delegate line-strip (renderer points &rest args))
(define-renderer-delegate curve (renderer points &rest args))
(define-renderer-delegate rectangle (renderer bounds &rest args))
(define-renderer-delegate ellipse (renderer bounds &rest args))
(define-renderer-delegate polygon (renderer points &rest args))
(define-renderer-delegate icon (renderer bounds image &rest args))
(define-renderer-delegate text (renderer bounds string &rest args))
(define-renderer-delegate cursor (renderer text position &rest args))
(define-renderer-delegate selection (renderer text start end &rest args))
(define-renderer-delegate image-pattern (renderer image &rest args))
(define-renderer-delegate request-font (renderer family &rest args))
(define-renderer-delegate request-image (renderer data &rest args))
(define-renderer-delegate request-gradient (renderer type start stop stops &rest args))

(defmethod palette ((name symbol))
  (or (gethash name *palettes*)
      (error "No palette with name ~s" name)))

(defmethod (setf palette) ((palette palette) (name symbol))
  (setf (gethash name *palettes*) palette))

(defmethod (setf palette) ((null null) (name symbol))
  (remhash name *palettes*)
  null)

(defmacro define-palette (name &body patterns)
  `(let ((palette (or (gethash ',name *palettes*)
                      (setf (palette ',name) (make-instance 'palette)))))
     (reinitialize-instance palette :patterns (list ,@(loop for item in patterns
                                                            collect (if (listp item) `(list ,@item) item))))
     ',name))

(defmethod (setf patterns) ((src palette) (dst palette))
  (setf (patterns dst) (patterns src)))

(defmethod (setf palette) ((src symbol) (dst palette-element))
  (setf (palette dst) (palette src)))

(defmethod element-palette-state ((element alloy:element))
  #b0)

(defmethod element-palette-state ((element alloy:focus-element))
  (ecase (alloy:focus element)
    (:strong #b10)
    (:weak   #b01)
    ((NIL)   #b00)))

(defmethod element-palette-state ((component alloy:component))
  (logior (call-next-method)
          (if (alloy:active-p component)
              #b0100
              #b0000)))

(defmethod find-pattern (name (element palette-element) &rest args &key &allow-other-keys)
  (if (palette element)
      (apply #'find-pattern name (palette element) args)
      (call-next-method)))

(defmethod find-pattern (name palette &key (default NIL default-p) state)
  (declare (ignore state))
  (if default-p
      default
      (error "No pattern with name~%  ~s~%on palette object~%  ~a" name palette)))

(defmethod find-pattern ((pattern chroma:rgb) palette &key default state)
  (declare (ignore default state))
  pattern)

(defun normalize-pattern-state (state)
  (etypecase state
    ((integer 0 15) state)
    ((eql NIL)           #b0000)
    ((eql :weak-focus)   #b0001)
    ((eql :strong-focus) #b0010)
    ((eql :activated)    #b0100)
    ((eql :disabled)     #b1000)))

(defmethod find-pattern (name (palette palette) &key default (state 0))
  (declare (ignore default))
  (or (svref (gethash name (patterns palette)) state)
      (call-next-method)))

(defmethod (setf find-pattern) ((none null) name (palette palette) &key default state)
  (declare (ignore default))
  (cond (state
         (setf (svref (gethash name (patterns palette)) (normalize-pattern-state state)) NIL))
        (T
         (remhash name (patterns palette))))
  (alloy:notify-observers 'find-pattern palette name)
  none)

(defmethod (setf find-pattern) (pattern name (palette palette) &key default (state 0))
  (declare (ignore default))
  (let ((array (or (gethash name (patterns palette))
                   (setf (gethash name (patterns palette)) (make-array 16 :initial-element NIL)))))
    (setf (svref array (normalize-pattern-state state)) pattern))
  (alloy:notify-observers 'find-pattern palette name)
  pattern)

(defmethod (setf find-pattern) ((pattern symbol) name (palette palette) &rest args &key &allow-other-keys)
  (apply #'(setf find-pattern) (apply #'find-pattern pattern palette args) name palette args))

(defmethod (setf find-pattern) ((pattern chroma:color) name (palette palette) &rest args &key &allow-other-keys)
  (if (typep pattern 'chroma:rgb)
      (call-next-method)
      (apply #'(setf find-pattern) (chroma:convert pattern 'chroma:rgb) name palette args)))

(defmethod (setf find-pattern) ((pattern integer) name (palette palette) &rest args &key &allow-other-keys)
  (apply #'(setf find-pattern) (chroma:decode pattern) name palette args))

(defmethod (setf find-pattern) ((pattern list) name (palette palette) &rest args &key &allow-other-keys)
  (apply #'(setf find-pattern) (apply #'chroma:rgb pattern) name palette args))

(defmethod find-pattern (name (tree alloy:layout-tree) &rest args &key &allow-other-keys)
  (apply #'find-pattern name (alloy:ui tree) args))

(defmethod find-pattern :around (name (element alloy:layout-element) &key (default NIL default-p)
                                                                          (state (element-palette-state element)))
  (or (call-next-method name element :default NIL :state state)
      ;; This allows the gradual descent down the layout tree, and thus allows overriding down the line.
      (let ((parent (alloy:layout-parent element)))
        (cond ((eq parent element)
               (find-pattern name (alloy:layout-tree element) :default NIL :state state))
              (parent
               (find-pattern name parent :default NIL :state state))))
      (if default-p
          default
          (error "No pattern with name~%  ~s~%on palette object~%  ~a" name element))))

(defclass font ()
  ((family :initarg :family :initform (arg! :family) :reader family)
   (slant :initarg :slant :initform :roman :reader slant)
   (spacing :initarg :spacing :initform :proportional :reader spacing)
   (weight :initarg :weight :initform :regular :reader weight)
   (stretch :initarg :stretch :initform :normal :reader stretch)))

(defmethod request-font ((renderer renderer) (family string) &rest initargs)
  (apply #'make-instance 'font :family family initargs))

(defmethod find-pattern ((pattern font) palette &key default state)
  (declare (ignore default state))
  pattern)

(defmethod print-object ((font font) stream)
  (print-unreadable-object (font stream :type T)
    (format stream "~a" (family font))))

(defclass image ()
  ((size :initarg :size :reader size)
   (data :initarg :data :reader data)
   (channels :initarg :channels :reader channels)))

(defmethod request-image ((renderer renderer) (data vector) &rest initargs)
  (apply #'make-instance 'image :data data initargs))

(defmethod alloy:enter ((image image) (layout alloy:layout) &rest args)
  (apply #'alloy:enter (alloy:represent-with 'alloy:icon image) layout args))

(defmethod alloy:component-class-for-object ((image image))
  (find-class 'alloy:icon))

(defclass gradient ()
  ((start :initarg :start :initform (arg! :start) :reader start)
   (stop :initarg :stop :initform (arg! :stop) :reader stop)
   (stops :initarg :stops :initform (arg! :stops) :reader stops)))

(defmethod find-pattern ((pattern gradient) palette &key default state)
  (declare (ignore default state))
  pattern)

(defclass linear-gradient (gradient) ())
(defclass radial-gradient (gradient) ())
(defclass angle-gradient (gradient) ())
(defclass diamond-gradient (gradient) ())

(defmethod request-gradient ((renderer renderer) type start stop stops &rest initargs)
  (apply #'make-instance type :start start :stop stop :stops stops initargs))

(defclass image-pattern ()
  ((image :initarg :image :initform (arg! :image) :reader image)
   (scaling :initarg :scaling :initform (alloy:size 1 1) :reader scaling)
   (offset :initarg :offset :initform (alloy:point 0 0) :reader offset)
   (mode :initarg :mode :initform :repeat :reader mode)))

(defmethod image-pattern ((renderer renderer) image &rest initargs)
  (apply #'make-instance 'image-pattern :image image initargs))

(defmethod find-pattern ((pattern image-pattern) palette &key default state)
  (declare (ignore default state))
  pattern)

(defclass shape () ())

(defmethod shared-initialize :after ((shape shape) slots &key palette)
  (declare (ignore palette)))

(defmethod reinitialize-instance :after ((shape shape) &key renderer)
  (declare (ignore renderer)))

(defgeneric bounds (shape))

(defmethod alloy:suggest-size ((size T) (shape shape))
  (let ((bounds (bounds shape)))
    (typecase bounds
      (alloy:size (alloy:px-size (alloy:pxw bounds) (alloy:pxh bounds)))
      ;; Require enough space for the combined margins.
      (alloy:margins (alloy:px-size
                      (max (alloy:pxw size) (+ (alloy:pxl bounds) (alloy:pxr bounds)))
                      (max (alloy:pxh size) (+ (alloy:pxu bounds) (alloy:pxb bounds)))))
      (T size))))

(defclass patterned-shape (shape)
  ((pattern :initarg :pattern :initform colors:black :writer (setf pattern))
   (palette :initarg :palette :initform NIL :accessor palette)))

(defmethod find-pattern ((pattern (eql T)) (shape patterned-shape) &rest args &key &allow-other-keys)
  (apply #'find-pattern (pattern shape) shape args))

(defmethod pattern ((shape patterned-shape))
  (let ((pattern (slot-value shape 'pattern)))
    (if (symbolp pattern)
        (find-pattern pattern (palette shape))
        pattern)))

(defclass filled-shape (patterned-shape)
  ((feather-radius :initarg :feather-radius :initform (alloy:px 0) :accessor feather-radius)))

(defmethod (setf feather-radius) ((null null) (shape filled-shape))
  (setf (feather-radius shape) (alloy:px 0)))

(defmethod (setf feather-radius) ((value real) (shape filled-shape))
  (setf (feather-radius shape) (alloy:un value)))

(defclass outlined-shape (patterned-shape)
  ((line-width :initarg :line-width :initform (alloy:un 1) :accessor line-width)
   (line-style :initarg :line-style :initform NIL :accessor line-style)
   (join-style :initarg :join-style :initform NIL :accessor join-style)
   (cap-style :initarg :cap-style :initform NIL :accessor cap-style)))

(defclass bounded-shape (shape)
  ((bounds :initarg :bounds :initform (arg! :bounds) :accessor bounds)))

(defclass rectangle (bounded-shape)
  ((corner-radii :initform (make-array 4 :initial-element (alloy:px 0)) :reader corner-radii)))

(defmethod shared-initialize :after ((rectangle rectangle) slots &key (corner-radii NIL corner-radii-p))
  (when corner-radii-p
    (setf (corner-radii rectangle) corner-radii)))

(defmethod corner-radius (position (rectangle rectangle))
  (let ((radii (corner-radii rectangle)))
    (ecase position
      ((0 :top-left :north-west) (aref radii 0))
      ((1 :top-right :north-east) (aref radii 1))
      ((2 :bottom-right :south-east) (aref radii 2))
      ((3 :bottom-left :south-west) (aref radii 3)))))

(defmethod (setf corner-radius) ((value alloy:unit) position (rectangle rectangle))
  (let ((radii (corner-radii rectangle)))
    (ecase position
      ((0 :top-left :north-west) (setf (aref radii 0) value))
      ((1 :top-right :north-east) (setf (aref radii 1) value))
      ((2 :bottom-right :south-east) (setf (aref radii 2) value))
      ((3 :bottom-left :south-west) (setf (aref radii 3) value))
      ((4 :top :north) (setf (aref radii 0) (setf (aref radii 1) value)))
      ((5 :right :east) (setf (aref radii 2) (setf (aref radii 1) value)))
      ((6 :bottom :south) (setf (aref radii 2) (setf (aref radii 3) value)))
      ((7 :left :west) (setf (aref radii 0) (setf (aref radii 3) value)))
      ((8 T :all) (fill radii value)))))

(defmethod (setf corner-radius) ((null null) position (rectangle rectangle))
  (setf (corner-radius position rectangle) (alloy:px 0)))

(defmethod (setf corner-radii) ((value alloy:unit) (rectangle rectangle))
  (fill (corner-radii rectangle) value))

(defmethod (setf corner-radii) ((value real) (rectangle rectangle))
  (fill (corner-radii rectangle) (alloy:un value)))

(defmethod (setf corner-radii) ((null null) (rectangle rectangle))
  (fill (corner-radii rectangle) (alloy:px 0)))

(defmethod (setf corner-radii) ((sequence sequence) (rectangle rectangle))
  (map-into (corner-radii rectangle) #'identity sequence))

(defclass filled-rectangle (rectangle filled-shape) ())
(defclass outlined-rectangle (rectangle outlined-shape) ())

(defmethod rectangle ((renderer renderer) bounds &rest initargs &key line-width)
  (apply #'make-instance (if line-width 'outlined-rectangle 'filled-rectangle) :bounds bounds initargs))

(defclass ellipse (bounded-shape)
  ((start-angle :initform 0.0 :accessor start-angle)
   (end-angle :initform #.(float (* 2 PI) 0f0) :accessor end-angle)))

(defmethod shared-initialize :after ((ellipse ellipse) slots &key (start-angle NIL start-angle-p) (end-angle NIL end-angle-p))
  (when start-angle-p
    (setf (start-angle ellipse) start-angle))
  (when end-angle-p
    (setf (end-angle ellipse) end-angle)))

(defmethod (setf start-angle) ((value real) (ellipse ellipse))
  (setf (slot-value ellipse 'start-angle) (float value 0f0)))

(defmethod (setf end-angle) ((value real) (ellipse ellipse))
  (setf (slot-value ellipse 'end-angle) (float value 0f0)))

(defclass filled-ellipse (ellipse filled-shape) ())
(defclass outlined-ellipse (ellipse outlined-shape) ())

(defmethod ellipse ((renderer renderer) bounds &rest initargs &key line-width)
  (apply #'make-instance (if line-width 'outlined-ellipse 'filled-ellipse) :bounds bounds initargs))

(defclass polygon (filled-shape)
  ((points :initarg :points :initform (arg! :points) :accessor points)))

(defmethod polygon ((renderer renderer) points &rest initargs)
  (apply #'make-instance 'polygon :points points initargs))

(defmethod bounds ((polygon polygon))
  (destructuring-bind (a . points) (points polygon)
    (let* ((x- (alloy:pxx a)) (y- (alloy:pxy a))
           (x+ x-) (y+ y-))
      (dolist (p points (alloy:px-extent x- y- (- x+ x-) (- y+ y-)))
        (let ((x (alloy:pxx p)) (y (alloy:pxy p)))
          (setf x- (min x- x) y- (min y- y)
                x+ (max x+ x) y+ (max y+ y)))))))

(defclass line-strip (outlined-shape)
  ((points :initarg :points :initform (arg! :points) :accessor points)))

(defmethod line-strip ((renderer renderer) points &rest initargs)
  (apply #'make-instance 'line-strip :points points initargs))

(defmethod bounds ((line-strip line-strip))
  (destructuring-bind (a . points) (points line-strip)
    (let* ((x- (alloy:pxx a)) (y- (alloy:pxy a))
           (x+ x-) (y+ y-))
      (dolist (p points (alloy:px-extent x- y- (- x+ x-) (- y+ y-)))
        (let ((x (alloy:pxx p)) (y (alloy:pxy p)))
          (setf x- (min x- x) y- (min y- y)
                x+ (max x+ x) y+ (max y+ y)))))))

(defclass curve (outlined-shape)
  ((points :initarg :points :initform (arg! :points) :accessor points)))

(defmethod curve ((renderer renderer) points &rest initargs)
  (apply #'make-instance 'curve :points points initargs))

(defmethod bounds ((curve curve))
  ;; TODO: implement
  (error "IMPLEMENT ME"))

;; TODO: changing styles and size, multiple styles and size per text
;;       Might be too much for a simple interface though. Maybe could be
;;       done by a layouter -- splitting text into contiguous segments.
;;       would be difficult to manage with line wraps and bidi.
(defun sort-markup (markup)
  (flet ((sorter (a b)
           (let ((sa (pop a)) (ea (pop a))
                 (sb (pop b)) (eb (pop b)))
             (if (= sa sb)
                 (< eb ea)
                 (< sa sb)))))
    (sort markup #'sorter)))

(defun flatten-markup (markup)
  (let ((results ())
        (styles ())
        (markup (sort-markup markup)))
    ;; We do a dual-stack approach: the markup has to be sorted in sequence
    ;; without overlaps. We then scan through this sequence by iterating an
    ;; index and matching against possible starting markups (second WHEN).
    ;; If we match we push the end indices of matching styles to STYLES as
    ;; well as a singular matching index for the start of the matching
    ;; STYLE. As we iterate and appear at the matching indices of the STYLES
    ;; stack we can then actually push them onto the results list.
    (loop for i from 0
          while markup
          do (when (and styles (= i (caar styles)))
               (pop styles)
               (push (list* i (mapcar #'cdr styles)) results))
             (when (= i (caar markup))
               (loop while (and markup (= i (caar markup)))
                     do (destructuring-bind (s e style) (pop markup)
                          (declare (ignore s))
                          (push (cons e style) styles)))
               (push (list* i (mapcar #'cdr styles)) results)))
    ;; Now we process any remaining dangling styles.
    (loop for style = (pop styles)
          while style
          do (push (list* (car style) (mapcar #'cdr styles)) results))
    ;; Finally we need to ignore successive styles that begin with the
    ;; same index and only use the first (ultimately last) one, as it
    ;; would override all others anyway.
    (when results
      (let ((rresults (list (pop results))))
        (dolist (style results rresults)
          (unless (= (car style) (caar rresults))
            (push style rresults)))))))

(defclass text (bounded-shape patterned-shape)
  ((alloy:text :initarg :text :initform (arg! :text) :accessor alloy:text)
   (font :initarg :font :initform (arg! :font) :accessor font)
   (size :initarg :size :initform (alloy:un 12) :accessor size)
   (valign :initarg :valign :initform :bottom :accessor valign)
   (halign :initarg :halign :initform :start :accessor halign)
   (direction :initarg :direction :initform :right :accessor direction)
   (wrap :initarg :wrap :initform NIL :accessor wrap)
   (markup :initarg :markup :initform NIL :accessor markup)
   (bounds :initform (alloy:margins))))

(defmethod text ((renderer renderer) bounds (string string) &rest initargs)
  (apply #'make-instance 'text :text string :bounds bounds :markup (sort-markup (getf initargs :markup)) initargs))

(defmethod text :around ((renderer renderer) bounds text &rest initargs &key font)
  (let ((font (typecase font
                (font font)
                (null (request-font renderer :default))
                (T (request-font renderer font)))))
    (apply #'call-next-method renderer bounds text :font font initargs)))

(defmethod reinitialize-instance :after ((text text) &key (font NIL font-p) renderer)
  (when (and font-p (not (typep font 'font)))
    (setf (font text) (request-font renderer font))))

(defmethod (setf markup) :around ((markup cons) (text text))
  (call-next-method (sort-markup markup) text))

(defclass icon (bounded-shape)
  ((image :initarg :image :initform (arg! :image) :accessor image)
   ;; TODO: rename to SCALING and OFFSET for consistency
   (size :initarg :size :initform (alloy:px-size 1 1) :accessor size)
   (shift :initarg :shift :initform (alloy:px-point 0 0) :accessor shift)
   (sizing :initarg :sizing :initform :fit :accessor sizing)
   (valign :initarg :valign :initform :middle :accessor valign)
   (halign :initarg :halign :initform :left :accessor halign)
   (bounds :initform (alloy:margins))))

(defmethod icon ((renderer renderer) bounds (image image) &rest initargs)
  (apply #'make-instance 'icon :image image :bounds bounds initargs))

(defmethod reinitialize-instance :after ((icon icon) &key (image NIL image-p) renderer)
  (when (and image-p (not (typep image 'image)))
    (setf (image icon) (request-image renderer image))))

(defmethod alloy:bounds ((icon icon))
  (alloy:ensure-extent
   (bounds icon)
   (alloy:extent (alloy:pxx (shift icon))
                 (alloy:pxy (shift icon))
                 (* (alloy:pxw (size icon)) (alloy:pxw (size (image icon))))
                 (* (alloy:pxh (size icon)) (alloy:pxh (size (image icon)))))))

(defclass cursor (filled-rectangle)
  ((text-object :initarg :text :accessor text-object)
   (start :initarg :start :accessor start)
   (bounds :initform NIL)))

(defmethod cursor ((renderer renderer) (text text) (start integer) &rest initargs)
  (apply #'make-instance 'cursor :text text :start start initargs))

(defclass selection (polygon)
  ((text-object :initarg :text :accessor text-object)
   (start :initarg :start :accessor start)
   (end :initarg :end :accessor end)
   (pattern :initform (chroma:color 0 0 1 0.5))
   (points :initform NIL)))

(defmethod selection ((renderer renderer) (text text) (start integer) (end integer) &rest initargs)
  (apply #'make-instance 'selection :text text :start start :end end initargs))

(defun resolve-alignment (extent halign valign size)
  (let ((extent (alloy:ensure-extent extent)))
    (alloy:px-point
     (+ (alloy:pxx extent)
        (ecase halign
          ((:start :left) 0)
          (:middle (/ (- (alloy:pxw extent) (alloy:pxw size)) 2))
          ((:end :right) (- (alloy:pxw extent) (alloy:pxw size)))))
     (+ (alloy:pxy extent)
        (ecase valign
          (:bottom 0)
          (:middle (/ (- (alloy:pxh extent) (alloy:pxh size)) 2))
          (:top (- (alloy:pxh extent) (alloy:pxh size))))))))

(defun resolve-scale (extent size kind)
  (let ((ow (alloy:pxw extent))
        (oh (alloy:pxh extent))
        (iw (alloy:pxw size))
        (ih (alloy:pxh size)))
    (ecase kind
      (:fit
       extent)
      (:fit-width
       (alloy:px-size ow (* (/ ow iw) ih)))
      (:fit-height
       (alloy:px-size (* (/ oh ih) iw) oh))
      (:contain
       (let ((s (min (/ ow iw) (/ oh ih))))
         (alloy:px-size (* s iw) (* s ih))))
      (:cover
       (let ((s (max (/ ow iw) (/ oh ih))))
         (alloy:px-size (* s iw) (* s ih)))))))
