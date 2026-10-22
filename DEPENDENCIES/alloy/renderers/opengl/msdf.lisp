(defpackage #:org.shirakumo.alloy.renderers.opengl.msdf
  (:use #:cl)
  (:local-nicknames
   (#:alloy #:org.shirakumo.alloy)
   (#:simple #:org.shirakumo.alloy.renderers.simple)
   (#:presentations #:org.shirakumo.alloy.renderers.simple.presentations)
   (#:opengl #:org.shirakumo.alloy.renderers.opengl)
   (#:font-discovery #:org.shirakumo.font-discovery)
   (#:chroma #:org.shirakumo.alloy.chroma)
   (#:colors #:org.shirakumo.alloy.chroma.colors)
   (#:uax-14 #:org.shirakumo.alloy.uax-14))
  (:export
   #:fontcache-default-directory
   #:fontcache-file
   #:font-file-not-found
   #:renderer
   #:fontcache-directory
   #:font
   #:file
   #:cache-font
   #:cached-font
   #:fontcache
   #:atlas
   #:text
   #:cursor
   #:selection
   #:msdf-font-scale
   #:msdf-line-height
   #:msdf-pen-advance
   #:text-decoration-count
   #:decorate-text
   #:decorated-text-origin))
(in-package #:org.shirakumo.alloy.renderers.opengl.msdf)

(defvar +default-char+ (3b-bmfont::make-glyph))

(defun fontcache-default-directory ()
  ;; KLUDGE: Would be better to use the LOCALAPPDATA envvar, but that requires portable getenv.
  #+win32 (merge-pathnames "AppData/Local/alloy/msdf/" (user-homedir-pathname))
  #-win32 (merge-pathnames ".cache/alloy/msdf/" (user-homedir-pathname)))

(defun fontcache-file (path &optional (cache (fontcache-default-directory)))
  (cond ((or (string= (pathname-type path) "font")
             (string= (pathname-type path) "fnt")
             (string= (pathname-type path) "json"))
         path)
        ((or (string= (pathname-type path) "otf")
             (string= (pathname-type path) "ttf"))
         ;; KLUDGE: would be better to name the files by font properties to collate duplicate files
         ;;         and to avoid pathname length or depth overflow.
         (merge-pathnames (make-pathname :type "json"
                                         :directory (list :relative)
                                         :defaults path)
                          cache))
        (T
         (error "Unrecognised font format for file~%  ~a" path))))

(defclass renderer (opengl:renderer)
  ((fontcache-directory :initarg :fontcache :initform (fontcache-default-directory) :accessor fontcache-directory)
   (fontcache :initform (make-hash-table :test 'equal) :accessor fontcache)
   (font-name-cache :initform (make-hash-table :test 'equalp) :accessor font-name-cache)))

(defmethod initialize-instance :after ((renderer renderer) &key)
  ;; Init font cache
  (dolist (path (directory (make-pathname :name :wild :type "json" :defaults (fontcache-directory renderer))))
    (setf (gethash (pathname-name path) (fontcache renderer))
          (make-instance 'font :family (pathname-name path) :file path :renderer renderer))
    (setf (gethash (pathname-name path) (font-name-cache renderer))
          path)))

(defmethod compute-fallback-chain ((renderer renderer))
  (let ((fonts ()))
    (loop for font being the hash-values of (fontcache renderer)
          do (pushnew font fonts))
    (flet ((try-load-font (font)
             (handler-case (partial-allocate font)
               (error (e)
                 (warn "Failed to load font: ~a~%~a" font e)
                 NIL)))
           (font-score (font)
             (hash-table-count (3b-bmfont::chars (data font)))))
      (setf fonts (remove-if-not #'try-load-font fonts))
      (sort (coerce fonts 'vector) #'< :key #'font-score))))

(defmethod alloy:allocate :before ((renderer renderer))
  (unless (opengl:resource 'text-vbo renderer NIL)
    ;; KLUDGE: pre-allocate a pretty big array to sidestep a driver issue on Windows/nVidia/OpenGL causing segfaults on repeat size changes.
    (setf (opengl:resource 'text-vbo renderer)
          (opengl:make-vertex-buffer renderer (* 10 1024 24)
                                     :data-usage :dynamic-draw))
    (setf (opengl:resource 'text-vao renderer)
          (opengl:make-vertex-array renderer `((,(opengl:resource 'text-vbo renderer) :size 2 :stride 60 :offset 0)
                                               (,(opengl:resource 'text-vbo renderer) :size 2 :stride 60 :offset 8)
                                               (,(opengl:resource 'text-vbo renderer) :size 4 :stride 60 :offset 16)
                                               (,(opengl:resource 'text-vbo renderer) :size 3 :stride 60 :offset 32)
                                               (,(opengl:resource 'text-vbo renderer) :size 4 :stride 60 :offset 44))))
    (opengl::make-shader-from-file renderer 'text-shader)))

(defmethod alloy:deallocate ((renderer renderer))
  (loop for font being the hash-values of (fontcache renderer)
        do (alloy:deallocate font)))

(defmethod cache-font ((family string) &rest args &key cache-file &allow-other-keys)
  (apply #'cache-font
         (font-discovery:file (or (font-discovery:find-font :family family)
                                  (error "No font named ~s found." family)))
         :cache-file (or cache-file (fontcache-file (make-pathname :name family :type "ttf"))) args))

(defmethod cache-font ((font-file pathname) &rest args &key (cache-file (fontcache-file font-file)) (size 32) (spread 8) &allow-other-keys)
  (remf args :cache-file)
  (apply #'sdf-bmfont:create-bmfont font-file cache-file :size size :spread spread :mode :msdf+a :type :json args)
  cache-file)

(define-condition font-file-not-found (error)
  ((file :initarg :file :reader file))
  (:report (lambda (c s) (format s "Specified font file does not exist or is not accessible.~%  ~a" (file c)))))

(defun cached-font (renderer file &key family evict-cache)
  (let* ((cache-file (if family
                         (make-pathname :name family :type "json" :defaults (fontcache-directory renderer))
                         (fontcache-file file (fontcache-directory renderer))))
         (cache (gethash cache-file (fontcache renderer))))
    (cond ((and cache (not evict-cache))
           cache)
          (T
           (unless (probe-file cache-file)
             (unless (probe-file file)
               (error 'font-file-not-found :file file))
             (ensure-directories-exist cache-file)
             (format T "~&Alloy: Caching font atlas from~%  ~a~%for~%  ~a~%This may take a while.~%" file cache-file)
             (cache-font file :cache-file cache-file))
           (setf (gethash cache-file (fontcache renderer))
                 (make-instance 'font :family family :file cache-file :renderer renderer))))))

(defclass font (simple:font)
  ((renderer :initarg :renderer :accessor renderer)
   (fallback-chain :accessor fallback-chain)
   (file :initarg :file :accessor file)
   (px-range :initform 4.0 :accessor px-range)
   (data :accessor data)
   (atlas :accessor atlas)))

(defmethod compute-fallback-chain ((font font))
  (let* ((chain (compute-fallback-chain (renderer font)))
         (pos (position font chain)))
    (rotatef (aref chain 0) (aref chain pos))
    chain))

(defvar *bmfont-data-cache* (make-hash-table :test 'equal)
  "Resolved BMFont pathname -> (data . px-range).

The parsed BMFont description is immutable CPU state with no GL resource
attached, so every font over the same file can share one copy regardless of
which renderer owns it.")

(defun partial-allocate (font)
  (unless (slot-boundp font 'data)
    (let* ((key (or (probe-file (file font)) (file font)))
           (hit (gethash key *bmfont-data-cache*)))
      (cond (hit
             (setf (data font) (car hit))
             (setf (px-range font) (cdr hit)))
            (T
             (with-open-file (stream (file font) :external-format :utf-8)
               (setf (data font) (3b-bmfont-json:read-bmfont-json stream)))
             (setf (px-range font) (float (getf (3b-bmfont:distance-field (data font)) :distance-range) 0f0))
             (setf (gethash key *bmfont-data-cache*) (cons (data font) (px-range font)))))))
  font)

(defun msdf-em-size (data)
  "The pixel EM size BMFont DATA was baked at: the size the glyph outlines were
scaled by, and so the denominator of every conversion from font units to pixels.
3b-bmfont:base is the ascender minus the padding the bake adds below it, a
baseline metric that moves with the bake and must never scale a glyph."
  (float (3b-bmfont:size data) 0f0))

(defun msdf-font-scale (font pixel-size)
  "The factor taking FONT's glyph geometry from font units to device pixels, at a
requested draw size of PIXEL-SIZE."
  (/ (float pixel-size 0f0) (msdf-em-size (data font))))

(defgeneric msdf-line-height (font pixel-size)
  (:documentation "FONT's baseline-to-baseline distance in device pixels at a draw size of PIXEL-SIZE.")
  (:method (font pixel-size)
    (* (msdf-font-scale font pixel-size)
       (float (3b-bmfont:line-height (data font)) 0f0))))

(defgeneric msdf-pen-advance (font string start end pixel-size)
  (:documentation "Pen travel from START to END of STRING in device pixels at a draw size of PIXEL-SIZE.")
  (:method (font string start end pixel-size)
    (* (msdf-font-scale font pixel-size)
       (float (3b-bmfont:measure-glyphs (data font) string :start start :end end) 0f0))))

(defmethod alloy:allocate ((font font))
  (let ((renderer (renderer font)))
    (partial-allocate font)
    (unless (slot-boundp font 'atlas)
      (let ((file (merge-pathnames (getf (aref (3b-bmfont:pages (data font)) 0) :file) (file font))))
        (setf (atlas font) (simple:request-image renderer file :filtering :linear))))
    (unless (slot-boundp font 'fallback-chain)
      (flet ((ensure-font (font-ish)
               (typecase font-ish
                 (font font-ish)
                 (T (simple:request-font (renderer font) font-ish)))))
        (setf (fallback-chain font) (map 'vector #'ensure-font (compute-fallback-chain font)))))))

(defmethod alloy:allocated-p ((font font))
  (slot-boundp font 'atlas))

(defmethod alloy:deallocate ((font font))
  (slot-makunbound font 'atlas))

(defmethod simple:request-font ((renderer renderer) (family string) &rest args)
  (let ((font (or (gethash family (font-name-cache renderer))
                  (setf (gethash family (font-name-cache renderer))
                        (font-discovery:file (or (apply #'font-discovery:find-font :family family args)
                                                 (error "No font named ~s found." family)))))))
    (cached-font renderer font :family family)))

(defmethod simple:request-font ((renderer renderer) (file pathname) &key)
  (cached-font renderer file))

(defmethod simple:request-font ((renderer renderer) (default (eql :default)) &key)
  (simple:request-font renderer "Arial"))

(defmethod simple:request-font ((renderer renderer) (font font) &key)
  font)

;;; A sequence of font runs represented as parallel vectors of indices
;;; and fonts for rendering a string of text.
(defstruct (font-sequence
            (:constructor make-font-sequence ()))
  ;; Hand-roll adjustable vectors here for speed.
  (indices (make-array 2 :element-type '(unsigned-byte 32)) :type (simple-array (unsigned-byte 32) (*)))
  (fonts (make-array 2) :type simple-vector)
  (capacity 2 :type (unsigned-byte 32))
  (length 0 :type (unsigned-byte 32)))

;;; Add INDEX and FONT onto FONT-SEQUENCE.
(defun font-sequence-push (font-sequence index font)
  (declare (type font-sequence font-sequence))
  (declare (type (unsigned-byte 32) index))
  (let ((len (font-sequence-length font-sequence))
        (cap (font-sequence-capacity font-sequence)))
    (when (= len cap)
      ;; geometric growth, min 4
      (let* ((new-cap (max 4 (ash cap 1)))
             (new-indices (make-array new-cap :element-type '(unsigned-byte 32)))
             (new-fonts (make-array new-cap)))
        (replace new-indices (font-sequence-indices font-sequence))
        (replace new-fonts (font-sequence-fonts font-sequence))
        (setf (font-sequence-indices font-sequence) new-indices
              (font-sequence-fonts font-sequence) new-fonts
              (font-sequence-capacity font-sequence) new-cap)))
    (setf (aref (font-sequence-indices font-sequence) len) index
          (aref (font-sequence-fonts font-sequence) len) font)
    (setf (font-sequence-length font-sequence) (1+ len))))

;;; Compute a sequence of font runs. If one font applies for the
;;; entire string, just return the font.
;;;
;;; FIXME: optimize font-sequence by reusing it
(defun compute-glyph-font-sequence (string font-fallback-chain
                                    &key (start 0) (end (length string)))
  (let ((primary-font (aref font-fallback-chain 0))
        font-sequence
        previous)
    (declare (type string string))
    (declare (type simple-vector font-fallback-chain))
    (loop for i from start below end
          for c = (aref string i)
          do (flet ((try-add (font)
                      (unless (eq font previous)
                        (when previous
                          (unless font-sequence
                            (setf font-sequence (make-font-sequence))
                            (font-sequence-push font-sequence 0 previous))
                          (font-sequence-push font-sequence i font))
                        (setf previous font))))
               (unless (eql c #\Space) ;; Special provision for space to avoid frequent switching.
                 (loop for font across font-fallback-chain
                       do (unless (alloy:allocated-p font)
                            (alloy:allocate font))
                          (when (gethash c (3b-bmfont::chars (data font)))
                            (try-add font)
                            (return))
                       finally (try-add primary-font)))))
    (cond (font-sequence
           (font-sequence-push font-sequence end primary-font)
           font-sequence)
          (t
           (or previous primary-font)))))

(defun map-glyphs (font-sequence function string extent scale wrap
                   &key (start 0) (end (length string)) (halign :start))
  (declare (type string string))
  (declare (type function function))
  (let* ((x 0.0) (y 0.0)
         (breaker (uax-14:make-breaker string))
         (max-width (alloy:pxw extent))
         (breaks (make-array 0 :adjustable T :fill-pointer T :element-type '(unsigned-byte 32)))
         (line-start 0)
         (next-break 0)
         (next-mandatory NIL)
         (last-break 0)
         (base-scale (float scale 0f0))
         (scale (float scale 0f0))
         f (w 0.0) (h 0.0) (line -1.0) (space 0.0) chars kernings
         (%k (cons NIL NIL))
         (i start) (si 0)
         (font-sequence-p (font-sequence-p font-sequence))
         (font-sequence-indices
           (and font-sequence-p
                (font-sequence-indices
                 (the font-sequence font-sequence))))
         (font-sequence-fonts
           (and font-sequence-p
                (font-sequence-fonts
                 (the font-sequence font-sequence)))))
    (declare (type single-float x y max-width w h space line scale base-scale))
    (declare (type (unsigned-byte 32) line-start next-break last-break i end si))
    (declare (optimize speed))
    (labels ((select-font (font)
               (unless (eq f font)
                 (setf f font)
                 (let ((font (data font)))
                   (setf scale (/ base-scale (msdf-em-size font)))
                   (setf w (/ (float (3b-bmfont::scale-w font))))
                   (setf h (/ (float (3b-bmfont::scale-h font))))
                   ;; KLUDGE: we ignore the line height of fonts other than our primary font
                   (when (< line 0.0)
                     (setf line (msdf-line-height f base-scale)))
                   (setf space (* scale (3b-bmfont::space-size font)))
                   (setf chars (3b-bmfont::chars font))
                   (setf kernings (3b-bmfont::kernings font)))))
             (find-font (i)
               (cond (font-sequence-p
                      (loop while (< i (aref font-sequence-indices si))
                            do (decf si))
                      (loop while (<= (aref font-sequence-indices si) i)
                            do (select-font (aref font-sequence-fonts si))
                               (incf si)))
                     (t
                      (select-font font-sequence))))
             (kerning (previous next)
               (setf (car %k) previous)
               (setf (cdr %k) next)
               (the single-float (gethash %k kernings 0f0)))
             (map-line (start end)
               ;; FIXME: need to know what alignment to use to decide on proper starting X.
               (loop for i from start below end
                     for p = NIL then c
                     for c = (char string i)
                     do (find-font i)
                        (case c
                          (#\linefeed
                           (setf x 0.0)
                           (decf y line)
                           ;; KLUDGE: We need these stubs to ensure that things that estimate vertex position
                           ;;         based on character index don't shift things badly for newlines and spaces
                           (funcall function i x y 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))
                          (#\space
                           (incf x space)
                           (funcall function i x y 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))
                          (T
                           (let* ((glyph (gethash c chars +default-char+))
                                  (xoffset (3b-bmfont:glyph-xoffset glyph))
                                  (yoffset (3b-bmfont:glyph-yoffset glyph))
                                  (width (3b-bmfont:glyph-width glyph))
                                  (height (3b-bmfont:glyph-height glyph))
                                  (cx (3b-bmfont:glyph-x glyph))
                                  (cy (3b-bmfont:glyph-y glyph))
                                  (xadvance (3b-bmfont:glyph-xadvance glyph)))
                             (let ((x- (+ x (* scale xoffset)))
                                   (y- (+ y (- line (* scale (+ yoffset height)))))
                                   (x+ (+ x (* scale (+ xoffset width))))
                                   (y+ (+ y (- line (* scale yoffset))))
                                   (u- (* cx w))
                                   (v- (* cy h))
                                   (u+ (* (+ cx width) w))
                                   (v+ (* (+ cy height) h)))
                               (funcall function i x y x- y- x+ y+ u- v- u+ v+))
                             (incf x (* scale (+ (kerning p c) xadvance))))))))
             (insert-break (at width)
               (vector-push-extend at breaks)
               (ecase halign
                 ((:start :left)
                  (setf x 0.0))
                 ((:middle :center)
                  (setf x (* 0.5 (- max-width width))))
                 ((:end :right)
                  (setf x (- max-width width))))
               (map-line line-start at)
               (unless (= x 0.0)
                 (setf x 0.0)
                 (decf y line))
               (setf line-start at)))
      (select-font (if font-sequence-p
                       (aref font-sequence-fonts 0)
                       font-sequence))
      ;; This first loops through, only computing the width after each
      ;; character. Then, when a line break is encountered or the line is full,
      ;; it calls INSERT-BREAK to emit the complete line before starting on the
      ;; next line.
      ;;
      ;; This is obviously stupid, and could be improved a lot by backtracking instead
      ;; when line breaks are needed. But I'm lazy.
      ;;
      ;; FIXME: This model inherently assumes a LTR system and will not deal with
      ;;        RTL, TTB, BTT orientations correctly. We also don't use UAX-9 yet.
      (when (< i end)
        (loop with line-widths of-type (array single-float 1)
                 = (make-array 1 :element-type 'single-float :adjustable T :fill-pointer 1 :initial-element 0.0)
              for p = NIL then c
              for c = (char string i)
              do (find-font i)
                 (when (and next-mandatory (= next-break i))
                   (insert-break i x)) ; TODO is X correct?
                 (case c
                   (#\linefeed
                    (vector-push-extend (aref line-widths (1- (length line-widths))) line-widths))
                   (#\space
                    (incf x space)
                    (vector-push-extend (+ (aref line-widths (1- (length line-widths))) space) line-widths))
                   (t
                    (let* ((char (gethash c chars +default-char+))
                           (x+ (+ x (* scale (+ (3b-bmfont:glyph-xoffset char)
                                                (3b-bmfont:glyph-width char))))))
                      (cond ((or (< x+ max-width) (null wrap)
                                 (<= i (1+ line-start))) ; force out at least one character to prevent infinite loop
                             (vector-push-extend x+ line-widths)
                             (incf x (* scale (+ (kerning p c)
                                                 (3b-bmfont:glyph-xadvance char)))))
                            ((< line-start last-break)
                             (insert-break last-break (aref line-widths (- last-break line-start 1)))
                             (setf (fill-pointer line-widths) 1)
                             (setf i (1- last-break)))
                            ((< line-start i)
                             (insert-break (1- i) (aref line-widths (- i line-start 1)))
                             (setf (fill-pointer line-widths) 1)
                             (decf i))))))
                 (when (<= next-break i)
                   (multiple-value-bind (pos mandatory) (uax-14:next-break breaker)
                     (setf next-mandatory mandatory)
                     (shiftf last-break next-break (or pos (1+ end)))))
                 (incf i)
              while (< i end)
              finally (insert-break end (aref line-widths (1- (length line-widths))))))
      breaks)))

(declaim (inline style-property))
(defun style-property (name styles)
  (loop for style in styles
        do (cond ((eq style name) ; simple style
                  (return '(t)))
                 ((and (consp style) (eq (car style) name)) ; complex style
                  (return (rest style))))))

(defgeneric text-decoration-count (font markup text-length)
  (:documentation "How many quads COMPUTE-TEXT reserves after the glyph quads for FONT's decorations of a TEXT-LENGTH string under MARKUP.")
  (:method (font markup text-length) 0))

(defgeneric decorate-text (font text markup pens scale emit)
  (:documentation "Emit FONT's decorations of TEXT under MARKUP through EMIT, a function of (x y u v color outline outline-color bias) that appends one vertex; PENS holds x, y and x+ of every character's pen, three single-floats per character, in the space the glyph quads were emitted in at SCALE.")
  (:method (font text markup pens scale emit) nil))

(defgeneric decorated-text-origin (font location array text-length)
  (:documentation "The origin a text shape is drawn at once FONT has settled the decoration quads of ARRAY, which follow its TEXT-LENGTH glyph quads, against LOCATION.")
  (:method (font location array text-length) location))

(defun compute-text (font text extent scale wrap markup halign)
  (declare (optimize speed))
  (declare (type string text))
  (let* ((text (if (simple-string-p text) text (coerce text 'simple-string)))
         (text-length (length text))
         (decorated-markup markup)
         (count (text-decoration-count font markup text-length))
         (array (make-array (* 6 15 (the (signed-byte 32) (+ text-length count))) :element-type 'single-float))
         (pens (when (plusp count)
                 (make-array (* 3 text-length) :element-type 'single-float :initial-element 0f0)))
         (minx 0.0) (miny 0.0) (maxx 0.0) (maxy 0.0) (i 0)
         (base (float (3b-bmfont:base (data font)) 0f0))
         (font-sequence (compute-glyph-font-sequence text (fallback-chain font)))
         (styles ()))
    (declare (type simple-string text))
    (declare (type (unsigned-byte 32) i text-length count))
    (declare (type (or null (simple-array single-float (*))) pens))
    (declare (type single-float minx miny maxx maxy scale))
    (labels ((vertex (x y u v c o oc bias)
               (setf (aref array (+ i 0)) (float x))
               (setf (aref array (+ i 1)) (float y))
               (setf (aref array (+ i 2)) (float u))
               (setf (aref array (+ i 3)) (float v))
               (setf (aref array (+ i 4)) (chroma:r c))
               (setf (aref array (+ i 5)) (chroma:g c))
               (setf (aref array (+ i 6)) (chroma:b c))
               (setf (aref array (+ i 7)) (chroma:a c))
               (setf (aref array (+ i 8)) 0.0)
               (setf (aref array (+ i 9)) 0.0)
               (setf (aref array (+ i 10)) (float bias))
               (setf (aref array (+ i 11)) (chroma:r oc))
               (setf (aref array (+ i 12)) (chroma:g oc))
               (setf (aref array (+ i 13)) (chroma:b oc))
               (setf (aref array (+ i 14)) o)
               (incf i 15))
             (thunk (c x y x- y- x+ y+ u- v- u+ v+)
               (declare (type single-float x y x- y- x+ y+ u- v- u+ v+))
               (declare (type (unsigned-byte 32) c))
               (loop while (<= (the (unsigned-byte 32) (or (caar markup) #xFFFFFFFF)) c)
                     do (setf styles (cdr (pop markup))))
               ;; Overwrite the initial 0.0 values. The initial values must be
               ;; 0.0 instead of some extreme value since THUNK may not be
               ;; called at all. In addition, THUNK is called with fake
               ;; coordinates for space and linefeed characters so don't update
               ;; in such cases.
               (cond ((zerop i)
                      (setf minx x- miny y- maxx x+ maxy y+))
                     ((not (member (aref text c) '(#\Space #\Linefeed)))
                      (setf minx (min minx x-))
                      (setf miny (min miny y-))
                      (setf maxx (max maxx x+))
                      (setf maxy (max maxy y+))))
               (when (and pens (< c text-length))
                 (let ((p (* 3 c)))
                   (setf (aref pens p) x
                         (aref pens (+ p 1)) y
                         (aref pens (+ p 2)) x+)))
               (let* ((boldp (style-property :bold styles))
                      (italicp (style-property :italic styles))
                      (tx (if italicp
                              (* (/ (- y+ y-) base) 9.0)
                              0.0))
                      (off (if boldp (* scale 0.2) 0.0))
                      (color NIL)
                      (outline-color colors:black)
                      (outline 0.0))
                 (when boldp ; try to stay on baseline (bold glyphs extend further down)
                   (incf y- (* .5 off))
                   (incf y+ (* .5 off)))
                 (when (and italicp (/= 0 (- y+ y-)))
                   (let ((skew (* (/ (- y y-) (- y+ y-)) tx)))
                     ;; KLUDGE: Dunno if the base shift of base/16 is good?
                     (incf x- (- (/ base 16) skew))
                     (incf x+ (- (/ base 16) skew))))
                 (let ((prop (style-property :color styles)))
                   (when prop
                     (setf color (first prop))))
                 (let ((prop (style-property :rainbow styles)))
                   (when prop
                     (setf color (chroma:convert (chroma:hsv (* 10 c) 1 1) 'chroma:rgb))))
                 (let ((prop (style-property :outline styles)))
                   (when prop
                     (setf outline (float (first prop) 0f0))
                     (when (second prop)
                       (setf outline-color (second prop)))))
                 ;; This can't work because the offsets we get are absolute and we don't know the cursor pos.
                 #++
                 (let ((prop (first (style-property :size styles))))
                   (when prop
                     (setf x+ (* x+ prop))
                     (setf x- (* x- prop))
                     (setf y+ (* y+ prop))
                     (setf y- (* y- prop))))
                 (unless color (setf color (chroma:rgb 0 0 0 0)))
                 (vertex (- (+ tx x-) off) (+ y+ off) u- (- 1 v-) color outline outline-color 0.0)
                 (vertex (- x- off) (- y- off) u- (- 1 v+) color outline outline-color 0.0)
                 (vertex (+ tx x+ off) (+ y+ off) u+ (- 1 v-) color outline outline-color 0.0)
                 (vertex (+ tx x+ off) (+ y+ off) u+ (- 1 v-) color outline outline-color 0.0)
                 (vertex (- x- off) (- y- off) u- (- 1 v+) color outline outline-color 0.0)
                 (vertex (+ x+ off) (- y- off) u+ (- 1 v+) color outline outline-color 0.0))))
      (declare (dynamic-extent #'thunk))
      (let ((breaks (map-glyphs font-sequence #'thunk text extent scale wrap :halign halign)))
        (when (plusp count)
          (decorate-text font text decorated-markup pens scale #'vertex)
          ;; The decoration quads follow the glyph quads, so the last font run covers them.
          (let ((total (+ text-length count)))
            (cond ((font-sequence-p font-sequence)
                   (font-sequence-push font-sequence total
                                       (aref (font-sequence-fonts font-sequence)
                                             (1- (font-sequence-length font-sequence)))))
                  (T
                   (let ((sequence (make-font-sequence)))
                     (font-sequence-push sequence 0 font-sequence)
                     (font-sequence-push sequence text-length font-sequence)
                     (font-sequence-push sequence total font-sequence)
                     (setf font-sequence sequence))))))
        (values breaks array font-sequence minx miny maxx maxy)))))

(defclass text (simple:text)
  ((vertex-data :accessor vertex-data)
   (font-sequence :accessor font-sequence)
   (real-size :reader size :writer (setf size))
   (location :accessor location)
   (line-breaks :accessor line-breaks)
   (vertex-count :initform NIL :accessor vertex-count)
   (cached-markup :initform () :accessor markup)
   (clock :initform 0f0 :accessor clock)))

(defmethod org.shirakumo.alloy.animation:update :after ((text text) dt)
  (let* ((markup (markup text))
         (data (vertex-data text))
         (style ())
         (clock (clock text))
         (string (alloy:text text)))
    (when markup
      (incf clock dt)
      (setf (clock text) (mod clock 36.0))
      (macrolet ((fill-glyph (&body body)
                   `(loop for j from 0 below 6
                          do ,@(loop for (i val) on body by #'cddr
                                     collect `(setf (aref data (+ ,i (* 15 (+ j (* 6 i))))) ,val)))))
        (loop with i = 0
              for c from 0 below (length string)
              do (when (<= (or (caar markup) (length data)) c)
                   (setf style (pop markup)))
                 (when (style-property :rainbow (rest style))
                   (let ((color (chroma:convert (chroma:hsv (mod (+ (* 10 c) (* 200 clock)) 360.0) 1 1) 'chroma:rgb)))
                     (fill-glyph 4 (chroma:r color)
                                 5 (chroma:g color)
                                 6 (chroma:b color)
                                 7 1.0)))
                 (when (style-property :wave (rest style))
                   (let* ((s (scale text))
                          (off (* s 10 (sin (+ (* 0.5 c) (* 10 clock))))))
                     (fill-glyph 9 off)))
                 (when (style-property :shake (rest style))
                   (let* ((s (* 0.02 (scale text)))
                          (time (mod (floor (* clock 50)) 1000))
                          (xoff (* s (logand #xFF (sxhash (+ (* 97 c) time)))))
                          (yoff (* s (logand #xFF (sxhash (+ (* 11 c) time))))))
                     (fill-glyph 8 xoff
                                 9 yoff)))
                 (unless (find (char string c) '(#\Linefeed))
                   (incf i)))))))

(defmethod scale ((text text))
  (msdf-font-scale (simple:font text) (alloy:to-px (simple:size text))))

(defmethod shared-initialize :after ((text text) slots &key)
  ;; TODO: Only update the size and internal data if any of the relevant slots actually changed (text, extent, markup).
  (alloy:allocate (simple:font text))
  (multiple-value-bind (size location array font-sequence breaks markup) (alloy:suggest-size (alloy:ensure-extent (simple:bounds text)) text)
    (setf (vertex-data text) array)
    (setf (location text) location)
    (setf (size text) size)
    (setf (line-breaks text) breaks)
    (setf (markup text) markup)
    (setf (font-sequence text) font-sequence)))

(defmethod simple:text ((renderer renderer) bounds string &rest args &key font)
  (apply #'make-instance 'text :text string :bounds bounds :font font args))

(defmethod alloy:render ((renderer renderer) (shape text))
  (let* ((shader (opengl:resource 'text-shader renderer))
         (vbo (opengl:resource 'text-vbo renderer))
         (vao (opengl:resource 'text-vao renderer))
         (data (vertex-data shape))
         (count (or (vertex-count shape)
                    (length data))))
    (simple:with-pushed-transforms (renderer)
      (opengl:bind shader)
      (simple:translate renderer (location shape))
      (setf (opengl:uniform shader "transform") (simple:transform-matrix renderer))
      (setf (opengl:uniform shader "color") (simple:pattern shape))
      ;; FIXME: this seems expensive, but maybe it would be worse to statically allocate for each text...
      (opengl:update-vertex-buffer vbo data)
      (flet ((draw (font start end)
               (setf (opengl:uniform shader "pxRange")
                     (* (sqrt 2.0) (px-range font)))
               (opengl:bind (atlas font))
               (opengl:draw-vertex-array vao :triangles start (- end start))))
        (let ((font-sequence (font-sequence shape)))
          (if (font-sequence-p font-sequence)
              (let ((indices (font-sequence-indices font-sequence))
                    (fonts (font-sequence-fonts font-sequence)))
                (dotimes (i (1- (font-sequence-length font-sequence)))
                  (let ((start (* 6 (aref indices i)))
                        (end (min (* 6 (aref indices (1+ i)))
                                  count)))
                    (draw (aref fonts i) start end)
                    (when (<= count end)
                      (return)))))
              (draw font-sequence 0
                    (min (* 6 (length (alloy:text shape)))
                         count))))))))

(defmethod alloy:suggest-size (size (text text))
  (let ((bounds (simple:bounds text))
        (scale (alloy:to-px (simple:size text)))
        (markup (simple::flatten-markup (simple:markup text))))
    (etypecase bounds
      (alloy:point
       (let ((bounds (alloy:px-extent (alloy:pxx bounds) (alloy:pxy bounds) MOST-POSITIVE-SINGLE-FLOAT 1.0)))
         (multiple-value-bind (breaks array font-sequence x- y- x+ y+) (compute-text (simple:font text) (alloy:text text) bounds scale (simple:wrap text) markup (simple:halign text))
           (declare (ignore y- y+))
           (let* ((w (- x+ x-))
                  (line (msdf-line-height (simple:font text) scale))
                  (h (* line (length breaks)))
                  (p (simple:resolve-alignment bounds :start (simple:valign text)
                                               (alloy:px-size w h))))
             ;; The additional return values are not used for the layout protocol but
             ;; in the SHARED-INITIALIZE method for the TEXT class.
             (values (alloy:px-extent (alloy:pxx p) (+ (- h line) (alloy:pxy p)) w h)
                     (decorated-text-origin (simple:font text)
                                            (alloy:px-point (alloy:pxx p) (+ (- h line) (alloy:pxy p)))
                                            array (length (alloy:text text)))
                     array font-sequence breaks markup)))))
      (alloy:extent
       (multiple-value-bind (breaks array font-sequence x- y- x+ y+) (compute-text (simple:font text) (alloy:text text) bounds scale (simple:wrap text) markup (simple:halign text))
         (declare (ignore y- y+))
         (let* ((w (- x+ x-))
                (line (msdf-line-height (simple:font text) scale))
                (h (* line (length breaks)))
                (p (simple:resolve-alignment bounds :start (simple:valign text)
                                             (alloy:px-size w h))))
           ;; The additional return values are not used for the layout protocol but
           ;; in the SHARED-INITIALIZE method for the TEXT class.
           (values bounds
                   (decorated-text-origin (simple:font text)
                                          (alloy:px-point (alloy:pxx p) (+ (- h line) (alloy:pxy p)))
                                          array (length (alloy:text text)))
                   array font-sequence breaks markup))))
      (alloy:margins
       (let* ((margins bounds)
              (free-size (alloy:px-extent 0 0 (alloy:pxw size) (alloy:pxh size))))
         (multiple-value-bind (breaks array font-sequence x- y- x+ y+) (compute-text (simple:font text) (alloy:text text) free-size scale (simple:wrap text) markup (simple:halign text))
           (declare (ignore y- y+))
           (let* ((w (- x+ x-))
                  (line (msdf-line-height (simple:font text) scale))
                  (h (* line (length breaks)))
                  (p (simple:resolve-alignment margins :start (simple:valign text)
                                               (alloy:px-size w h))))
             ;; The additional return values are not used for the layout protocol but
             ;; in the SHARED-INITIALIZE method for the TEXT class.
             (values (alloy:px-size (+ w (alloy:pxl margins) (alloy:pxr margins))
                                    (+ h (alloy:pxu margins) (alloy:pxb margins)))
                     (decorated-text-origin (simple:font text)
                                            (alloy:px-point (alloy:pxx p) (+ (- h line) (alloy:pxy p)))
                                            array (length (alloy:text text)))
                     array font-sequence breaks markup))))))))

(defclass cursor (simple:cursor) ())

(defmethod simple:cursor ((renderer renderer) (text text) (start integer) &rest initargs)
  (apply #'make-instance 'cursor :text text :start start initargs))

(defun estimate-cursor-pos (text point offset)
  (let* ((location (location text))
         (font (simple:font text))
         (breaks (line-breaks text))
         (string (alloy:text text))
         (scale (alloy:to-px (simple:size text)))
         (line-height (msdf-line-height font scale))
         (x (- (alloy:pxx point) (alloy:pxx offset) (alloy:pxx location)))
         (n-lines (length breaks))
         (trailing-linefeed (and (plusp (length string))
                                 (char= #\Linefeed (char string (1- (length string))))))
         (max-line (if trailing-linefeed n-lines (max 0 (1- n-lines))))
         (line (1+ (floor (- (+ (alloy:pxy offset) (alloy:pxy location)) (alloy:pxy point))
                          line-height)))
         (line (min max-line (max 0 line))))
    (if (>= line n-lines)
        (length string)
        (let* ((line-start (if (zerop line) 0 (aref breaks (1- line))))
               (line-end (aref breaks line))
               (measure-end (if (and (< line-start line-end)
                                     (<= line-end (length string))
                                     (char= #\Linefeed (char string (1- line-end))))
                                (1- line-end)
                                line-end))
               (best line-start)
               (best-distance most-positive-single-float))
          ;; The hit test picks the pen nearest to the point.
          (loop for i from line-start to (min measure-end (length string))
                for distance = (abs (- (msdf-pen-advance font string line-start i scale) x))
                do (when (< distance best-distance)
                     (setf best-distance distance best i)))
          best))))

(defun compute-cursor-location (text point)
  (let* ((breaks (line-breaks text))
         (string (alloy:text text))
         (line (loop for prev = 0 then next
                     for next across breaks
                     for i from 0
                     do (when (and (<= prev point)
                                   (< point next))
                          (return i))
                     ;; An empty string produces no break at all, so the fallback
                     ;; would answer -1 and place the caret a line above the text.
                     finally (return (max 0 (1- (length breaks))))))
         (font (simple:font text))
         (px (alloy:to-px (simple:size text)))
         (pitch (msdf-line-height font px))
         (x (if (string= "" string)
                0.0
                (msdf-pen-advance font string
                                  (if (= 0 line) 0 (aref breaks (1- line)))
                                  (min point (length string))
                                  px)))
         (s (scale text))
         (l (location text)))
    ;; KLUDGE: Dunno how I could do this cleanly.
    (when (and (= (length string) point)
               (< 0 point)
               (char= #\Linefeed (char string (1- point))))
      (incf line))
    (alloy:px-extent (+ (alloy:pxx l) x)
                     (- (alloy:pxy l) (* pitch line))
                     (* s 4)
                     pitch)))

(defmethod shared-initialize :after ((cursor cursor) slots &key)
  (setf (simple:bounds cursor) (compute-cursor-location (simple:text-object cursor) (simple:start cursor))))

(defmethod alloy:handle :after ((event alloy:pointer-down) (component alloy:text-input-component))
  (unless (eq (alloy:kind event) :right)
    (let ((label (presentations:find-shape :label component)))
      (when label
        (alloy:with-unit-parent component
          ;; The text is drawn at the component's global location shifted by the label offset.
          (let* ((origin (alloy:global-location component))
                 (offset (presentations:offset label))
                 (pos (estimate-cursor-pos
                       label (alloy:location event)
                       (alloy:px-point (+ (alloy:pxx origin) (alloy:pxx offset))
                                       (+ (alloy:pxy origin) (alloy:pxy offset))))))
            (when pos
              (alloy:move-to pos component))))))))

(defclass selection (simple:selection)
  ((%line-rectangles :reader line-rectangles
                     :initform (make-array 0 :adjustable t :fill-pointer 0))))

(defmethod simple:selection ((renderer renderer) (text text) (start integer) (end integer) &rest initargs)
  (apply #'make-instance 'selection :text text :start start :end end initargs))

(defun selection-measure-end (string end)
  "END without the Linefeed that closes its line: a break points PAST the newline,
which carries no ink and must not stretch the rectangle to the next line."
  (if (and (< 0 end (1+ (length string)))
           (char= #\Linefeed (char string (1- end))))
      (1- end)
      end))

(defmethod shared-initialize ((selection selection) slots &key)
  (call-next-method)
  (let ((line-rectangles (line-rectangles selection))
        (start (simple:start selection))
        (end (simple:end selection)))
    (setf (fill-pointer line-rectangles) 0)
    (when (/= start end)
      ;; One rectangle per VISUAL line: the shape's own break vector, which
      ;; carries the wrapping MAP-GLYPHS performed, and not just the explicit
      ;; Linefeeds of the string -- a wrapped selection otherwise gets a single
      ;; rectangle spanning every line it covers.
      (let* ((text (simple:text-object selection))
             (string (alloy:text text))
             (breaks (line-breaks text))
             (data (data (simple:font text)))
             (pixel-size (alloy:to-px (simple:size text)))
             (scale (msdf-font-scale (simple:font text) pixel-size))
             (line-height (msdf-line-height (simple:font text) pixel-size))
             (location (location text)))
        (flet ((advance (from to)
                 ;; The break vector can be one edit behind a pending re-layout,
                 ;; so an index past the string answers the end of the string.
                 (let* ((from (max 0 (min from (length string))))
                        (to (max from (min to (length string)))))
                   (* scale (3b-bmfont:measure-glyphs data string :start from :end to)))))
          (loop for line from 0 below (length breaks)
                for line-start = (if (= 0 line) 0 (aref breaks (1- line)))
                for line-end = (aref breaks line)
                for selected-start = (max start line-start)
                for selected-end = (min end line-end)
                when (< selected-start selected-end)
                  do (let ((x1 (+ (alloy:pxx location) (advance line-start selected-start)))
                           (x2 (+ (alloy:pxx location)
                                  (advance line-start (selection-measure-end string selected-end)))))
                       (vector-push-extend
                        (alloy:px-extent x1 (- (alloy:pxy location) (* line-height line))
                                         (max 0 (- x2 x1)) line-height)
                        line-rectangles))))))))

(defmethod opengl::render-direct ((shape selection) renderer color)
  (let ((shader (opengl:resource 'opengl::basic-shader renderer)))
    (opengl:bind shader)
    (setf (opengl:uniform shader "color") color)
    (flet ((draw-rect (extent)
             (simple:with-pushed-transforms (renderer)
               (simple:translate renderer extent)
               (simple:scale renderer extent)
               (setf (opengl:uniform shader "transform") (simple:transform-matrix renderer)))
             (opengl:draw-vertex-array (opengl:resource 'opengl::rect-fill-vao renderer) :triangles 0 6)))
      (loop for extent across (line-rectangles shape)
            do (draw-rect extent)))))
