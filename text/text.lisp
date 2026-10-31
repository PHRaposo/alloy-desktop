(in-package :alloy-desktop)

(defclass text-buffer (editor:buffer) ())

(defclass text-document (editor:document) ())

;;; A text pane of a desktop window: the editor's text view under its :CLASSIC
;;; family, given what a pane of a window owes the desktop around it -- the press
;;; it owns and the click that leaves it, the pointer it holds while it drags, the
;;; context menu of its right button, the I-beam, the desktop's clipboard, a caret
;;; that blinks and a marking that shows only while its window may show it, the
;;; selection the window tracks, a frame.
;;;
;;; Every method here is specialised on TEXT-PANE: the view's own methods (on
;;; EDITOR:TEXT-VIEW) keep running as the next method, none is replaced.

(defclass text-pane (editor:text-view)
  ;; the view's own slots, given the defaults of a pane as INITFORMs: an argument the
  ;; caller passes, NIL included, still wins, and so do a subclass's default initargs
  ((editor::gesture-policy :initform :classic)
   (editor::wrap-p :initform nil)
   (editor::buffer :initform (editor:make-buffer ""))
   (frame-color :initarg :frame-color :initform nil :accessor text-pane-frame-color
                :documentation "Colour of the 1-px frame drawn inside the pane's edges, or NIL for none.")
   (frame-shapes :initform nil
                 :documentation "(WIDTH HEIGHT COLOR . RECTANGLES) of the frame last drawn.")
   (window-focused :initform :unknown
                   :documentation "Whether the pane's window held the desktop's focus when the pane was last drawn.")
   (caret-shown :initform :unknown
                :documentation "Whether the pane showed its caret when it was last drawn.")
   (keyboard-held :initform nil
                  :documentation "Whether the pane held the strong focus after its last focus change."))
  (:documentation "A text view that answers the desktop as a pane of its window."))

(defclass editable-text (text-pane)
  ((editor::single-line-p :initform t))
  (:documentation "A text pane held to one line, as a field of a form."))

(defclass text-edit-view (text-pane scroll-mixin)
  ((scroll-reported :initform (cons 0 0)
                    :documentation "(X . Y) of the scroll last told to SCROLL-CHANGED.")
   (bars-read :initform nil
              :documentation "(WIDTH HEIGHT LEFT TOP) of the content the bars were last drawn for."))
  (:documentation "A text pane over a whole document, with the window's scroll bars its host asks for (:SCROLLBARS)."))

(defclass editor-scrollbar (editor:scrollbar) ())

;;; ------------------------------------------------------------------ the hooks

(defgeneric text-pane-focus-changed (pane focus)
  (:documentation "Called after PANE took the keyboard (FOCUS :STRONG) or lost it (FOCUS NIL); the toolkit's own passes through :WEAK while it repairs its chains are not reported.")
  (:method ((pane text-pane) focus)
    (declare (ignore focus))
    nil))

(defgeneric text-pane-written (pane character)
  (:documentation "Called after a key typed into PANE changed its text, with the character that stood before the caret as the key arrived (NIL when there was none).")
  (:method ((pane text-pane) character)
    (declare (ignore character))
    nil))

(defmethod (setf alloy:focus) :after (focus (pane text-pane))
  (let ((held (eql focus :strong)))
    (unless (eq held (slot-value pane 'keyboard-held))
      (setf (slot-value pane 'keyboard-held) held)
      (text-pane-focus-changed pane (and held :strong)))))

(defun %pane-character-before (pane index)
  "The character of PANE's text before INDEX, or NIL at the start."
  (when (and index (plusp index))
    (let ((buffer (editor:text-view-buffer pane)))
      (when (<= index (editor:buffer-size buffer))
        (editor:buffer-char buffer (1- index))))))

(macrolet ((written-after (class)
             `(defmethod alloy:handle :around ((event ,class) (pane text-pane))
                (let* ((buffer (editor:text-view-buffer pane))
                       (revision (editor:buffer-revision buffer))
                       (caret (editor:text-view-caret pane)))
                  (multiple-value-prog1 (call-next-method)
                    (unless (= revision (editor:buffer-revision buffer))
                      (text-pane-written pane (%pane-character-before pane caret))))))))
  (written-after alloy:text-event)
  (written-after alloy:key-down))

;;; ------------------------------------------------------------------ the pointer

;;; A press inside is the pane's; a press outside is noted so the release that ends
;;; it, with the pane still holding the keyboard, takes the focus away (the click
;;; that leaves the pane), while the release of a press that began inside never does.
(defvar *text-pane-press* (make-hash-table :test 'eq :weakness :key)
  "Pane -> :INSIDE or :OUTSIDE, where the press it is still waiting the release of landed.")

(defun text-pane-press (pane)
  "Where the press PANE is waiting the release of landed: :INSIDE, :OUTSIDE or NIL."
  (values (gethash pane *text-pane-press*)))

(defgeneric text-pane-menu-items (pane)
  (:documentation "Entries of the menu PANE's right button opens, in the form the desktop's popup menus take."))

(defgeneric open-text-pane-menu (pane items)
  (:documentation "Open ITEMS as PANE's context menu at the pointer."))

(defun %pane-take (pane)
  "Give PANE the keyboard of its window and make it the window's selection owner, undoing the selection of the pane that owned it when the window asks for it."
  (let ((window (element-window pane)))
    (when window
      (let ((owner (window-selected-text-pane window)))
        (when (and owner (not (eq owner pane)) (click-clears-selection-p window))
          (drop-text-selection owner)))
      (setf (window-selected-text-pane window) pane))
    (focus-pane window pane)))

(defmethod alloy:handle :around ((event alloy:pointer-down) (pane text-pane))
  (let ((inside (alloy:contained-p (alloy:location event) pane)))
    (case (alloy:kind event)
      (:right
       (cond (inside
              (let ((items (text-pane-menu-items pane)))
                (when items (open-text-pane-menu pane items)))
              t)
             (t
              (when (eql :strong (alloy:focus pane))
                (unfocus-pane (element-window pane) pane))
              (alloy:decline))))
      ;; every other button presses as the left one does
      (t
       (setf (gethash pane *text-pane-press*) (if inside :inside :outside))
       (cond (inside
              (call-next-method)
              (%pane-take pane)
              (capture-pointer pane)
              t)
             (t (call-next-method)))))))

(defmethod alloy:handle :around ((event alloy:pointer-up) (pane text-pane))
  ;; the release of any button ends the press, as it ends the view's own
  (let ((press (gethash pane *text-pane-press*)))
    (remhash pane *text-pane-press*)
    (cond ((eq pane (pointer-capture (pointer-state)))
           (release-pointer-capture pane)
           (call-next-method)
           t)
          ((and (eq press :outside)
                (eql :strong (alloy:focus pane))
                (not (alloy:contained-p (alloy:location event) pane)))
           (unfocus-pane (element-window pane) pane)
           (alloy:decline))
          (t (call-next-method)))))

;;; The desktop hands the second press of a double click as an event of its own, never
;;; as a press (input/pointer.lisp, %glfw:mouse-button-changed for window): it marks
;;; the run around the caret, whichever the button -- the first press of the left or
;;; middle one put the caret under the pointer, the right one leaves it where it was.
(defmethod alloy:handle ((event alloy:pointer-double-click) (pane text-pane))
  (cond ((alloy:contained-p (alloy:location event) pane)
         (editor:text-view-select-run pane (editor:text-view-caret pane))
         t)
        (t (call-next-method))))

;;; the shape the toolkit's own text input gives the pointer over it
(defmethod alloy:handle :before ((event alloy:pointer-move) (pane text-pane))
  (when (and (alloy:contained-p (alloy:location event) pane) (alloy:ui pane))
    (setf (alloy:cursor (alloy:ui pane)) :text)))

;;; ------------------------------------------------------------------ the menu

(defclass text-pane-menu-item (menu-item)
  ((title :initarg :title :reader menu-entry-title)
   (action :initarg :action :reader menu-entry-action))
  (:documentation "One row of a text pane's context menu."))

(defmethod menu-entry-accelerator ((entry text-pane-menu-item)) nil)
(defmethod menu-entry-enabled ((entry text-pane-menu-item)) t)
(defmethod menu-entry-selected ((entry text-pane-menu-item)) nil)
(defmethod menu-entry-items ((entry text-pane-menu-item)) nil)

(defmethod text-pane-menu-items ((pane text-pane))
  (flet ((row (title command)
           (make-instance 'text-pane-menu-item
                          :title title
                          :action (lambda () (editor:run-command pane command)))))
    (list (row "Cut" :cut) (row "Copy" :copy) (row "Paste" :paste) (row "Select All" :select-all))))

(defmethod open-text-pane-menu ((pane text-pane) items)
  (let ((window (element-window pane))
        (at (cursor-location (pointer-state))))
    (when window
      (popup-close-stack window)
      (multiple-value-bind (left top) (popup-owner-point-to-screen window (alloy:pxx at) (alloy:pxy at))
        (popup-open-menu-at (popup-normalize-entries items window) 0 window left top
                            :return-focus pane)))))

;;; ------------------------------------------------------------------ the clipboard

;;; The desktop's clipboard, for these panes only: every other view keeps the
;;; reader and the writer the editor is given.
(defmethod editor:clipboard-text ((pane text-pane))
  (clipboard-read-text (default-clipboard-service)))

(defmethod (setf editor:clipboard-text) (text (pane text-pane))
  (clipboard-write-text (default-clipboard-service) text)
  text)

;;; ------------------------------------------------------------------ caret and marking

(defmethod editor:text-view-caret-shown-p ((pane text-pane))
  (not (caret-hidden-p pane (element-window pane))))

(defun %pane-marking-hidden-p (pane)
  (let ((window (element-window pane)))
    (and window (not (window-focused-p window)) (not (selection-survives-blur-p window)))))

(defmethod editor:text-view-marking-shown-p ((pane text-pane))
  (not (%pane-marking-hidden-p pane)))

(defmethod editor:text-view-marking-inked-p ((pane text-pane))
  (not (%pane-marking-hidden-p pane)))

;;; The caret blinks with the desktop's cycle (the host's TICK-CARET-BLINK marks the
;;; pane on each flip) and the marking follows the window's focus; neither moves the
;;; text, so a frame only lays out again what changed since the last one.  The pane's
;;; frame is drawn here too, under the glyphs.
(defmethod alloy:render :before ((renderer alloy:renderer) (pane text-pane))
  (let* ((window (element-window pane))
         (focused (and window (window-focused-p window) t))
         (shown (editor:text-view-caret-shown-p pane)))
    (cond ((not (eq focused (slot-value pane 'window-focused)))
           (setf (slot-value pane 'window-focused) focused
                 (slot-value pane 'caret-shown) shown)
           (editor:text-view-refresh pane))
          ((not (eq shown (slot-value pane 'caret-shown)))
           (setf (slot-value pane 'caret-shown) shown)
           (editor:text-view-refresh-caret pane))))
  (%draw-pane-frame renderer pane))

;;; The pane holding the keyboard runs the desktop's blink cycle (text/caret.lisp:
;;; tick-caret-blink) from its own frames, so any window of the desktop blinks its caret
;;; with no host ticking it; a frame between two flips marks nothing.
(defmethod org.shirakumo.alloy.animation:update :after ((pane text-pane) dt)
  (declare (ignore dt))
  (when (eql :strong (alloy:focus pane))
    (let ((window (element-window pane)))
      (when window
        (tick-caret-blink window #'strong-focus-pane)))))

;;; ------------------------------------------------------------------ the face

;;; A pane given no face draws with its window's, the one the window's dialog items
;;; draw with (widgets/dialog-item.lisp: widget-font-entry), as a pane of CAPI does.
(defmethod presentations:realize-renderable :before ((renderer window) (pane text-pane))
  ;; before the view lays anything out: realizing builds its measurement afresh
  (unless (slot-value pane 'editor::font)
    (setf (slot-value pane 'editor::font) (font-entry-font (widget-font-entry pane renderer)))))

(defmethod alloy:handle :after ((event alloy:text-event) (pane text-pane))
  (when (eql :strong (alloy:focus pane)) (reset-caret-blink)))

(defmethod alloy:handle :after ((event alloy:key-down) (pane text-pane))
  (when (eql :strong (alloy:focus pane)) (reset-caret-blink)))

;;; ------------------------------------------------------------------ the frame

(defun %pane-frame-edges (pane)
  "The four 1-px rects (x y w h) just inside PANE's box."
  (let* ((bounds (alloy:bounds pane))
         (w (alloy:pxw bounds))
         (h (alloy:pxh bounds)))
    (list (list 0 (- h 1) w 1) (list 0 0 w 1) (list 0 0 1 h) (list (- w 1) 0 1 h))))

(defun %pane-frame (renderer pane color)
  "The frame's four rectangles for PANE's present size, made again only when the size or COLOR changed."
  (let* ((bounds (alloy:bounds pane))
         (w (alloy:pxw bounds))
         (h (alloy:pxh bounds))
         (kept (slot-value pane 'frame-shapes)))
    (if (and kept (= w (first kept)) (= h (second kept)) (eq color (third kept)))
        (cdddr kept)
        (cdddr (setf (slot-value pane 'frame-shapes)
                     (list* w h color
                            (loop for (x y ew eh) in (%pane-frame-edges pane)
                                  collect (simple:rectangle renderer (alloy:px-extent x y ew eh)
                                                            :pattern color))))))))

(defmethod (setf text-pane-frame-color) :after (color (pane text-pane))
  (declare (ignore color))
  (alloy:mark-for-render pane))

(defun %draw-pane-frame (renderer pane)
  "Draw PANE's frame, if it has one, before the view's own shapes: the ground, drawn at a lower depth, leaves it standing, and the glyphs, drawn at a higher one, go over it."
  (let ((color (text-pane-frame-color pane)))
    ;; inside the toolkit's own render :around of a layout element, which has already
    ;; moved the origin to the pane's corner
    (when color
      (alloy:with-unit-parent pane
        (if (editor:text-view-gutter-p pane)
            ;; the column of line numbers paints its ground and rule over the rows' depth
            ;; (alloy-editor/view.lisp: %view-place-gutter-chrome, at 4 and 5): the top, bottom
            ;; and left edges, which cross that column, go over it; the right one stays under
            ;; the glyphs
            (destructuring-bind (top bottom left right) (%pane-frame renderer pane color)
              (simple:with-pushed-transforms (renderer)
                (incf (simple:z-index renderer) 6)
                (alloy:render renderer top)
                (alloy:render renderer bottom)
                (alloy:render renderer left))
              (alloy:render renderer right))
            (dolist (shape (%pane-frame renderer pane color))
              (alloy:render renderer shape)))))))

;;; ------------------------------------------------------------------ the scroll bars

;;; A text-edit-view scrolls as every pane of the window does (view/scroll.lisp:
;;; SCROLL-MIXIN), over one place: the view's own.  The window's scrolling reads and
;;; writes it in device pixels through SCROLL-OFFSET, whose slot is never used here.
;;; The horizontal travel is coupled when the host allows a horizontal bar and the lines
;;; are not wrapped; otherwise the content is reported as wide as the narrowest viewport,
;;; so no horizontal bar appears and the view keeps its horizontal travel.

(defvar *scroll-writing* nil
  "The text-edit-view whose place SET-SCROLL is writing: SET-SCROLL tells of that move itself.")

;;; a pane its host gives no bars stays out of the window's scrolling altogether
(defmethod scroll-passive-p ((pane text-edit-view))
  (null (scrollbars pane)))

;;; The view cuts its drawing itself, short of the bars (the render :around for
;;; editor:text-view, which hands its rect over as an extent).  The cut the window's
;;; scrolling asks for again, on the whole pane (view/render.lisp: render :around for
;;; scroll-mixin), would be a second cut at the same depth, which the renderer refuses.
(defmethod alloy:constrain-visibility ((pane text-edit-view) (renderer alloy:renderer))
  nil)

;;; The view draws its shapes as every presented element does, and that is all it
;;; draws: the drawing pass of the window's scrolling (view/render.lisp: render for
;;; scroll-mixin) is the one of a layout, whose children a text view does not have.
(defmethod alloy:render ((renderer presentations:renderer) (pane text-edit-view))
  (render-presentation-shapes renderer pane))

(defmethod scroll-offset ((pane text-edit-view))
  (alloy:px-point (editor:text-view-scroll-x pane) (editor:text-view-scroll-top pane)))

;;; PANE's horizontal travel is the window's: its host allows a horizontal bar and its
;;; lines are not wrapped
(defmethod editor:text-view-travels-across-p ((pane text-edit-view))
  (and (scroll-axis-h-p (scrollbars pane))
       (not (slot-value pane 'editor::wrap-p))
       (editor:text-view-layout pane)
       t))

(defmethod (setf scroll-offset) (offset (pane text-edit-view))
  (let ((*scroll-writing* pane))
    ;; the place SET-SCROLL hands over is rounded: a view standing between two pixels
    ;; across is left there by a move down
    (when (and (editor:text-view-travels-across-p pane)
               (/= (alloy:pxx offset) (round (scroll-x pane))))
      (setf (editor:text-view-scroll-left pane) (alloy:pxx offset)))
    (unless (= (alloy:pxy offset) (scroll-y pane))
      (setf (editor:text-view-scroll-top pane) (alloy:pxy offset))))
  (setf (slot-value pane 'scroll-reported) (cons (scroll-x pane) (scroll-y pane)))
  offset)

(defmethod scroll-content-size ((pane text-edit-view))
  ;; as wide as the widest line when the travel across is the window's, else as the
  ;; viewport left beside a vertical bar; as tall as the view's content, the view's
  ;; own height before it is laid out
  (multiple-value-bind (width height) (scroll-view-size pane)
    (values (if (editor:text-view-travels-across-p pane)
                (editor:text-view-content-width pane)
                (- width *scrollbar-track-px*))
            (if (editor:text-view-layout pane)
                (editor:text-view-content-height pane)
                height))))

;;; the place moved by the wheel, a key, the caret or a refit: the bars follow it and the
;;; host is told, as SET-SCROLL tells of its own moves
(defmethod editor:text-view-scrolled ((pane text-edit-view))
  (when (scrollbars pane)
    (mark-scrollbars pane)
    (unless (eq pane *scroll-writing*)
      (let ((x (scroll-x pane))
            (y (scroll-y pane))
            (reported (slot-value pane 'scroll-reported)))
        (setf (slot-value pane 'scroll-reported) (cons x y))
        (unless (= x (car reported)) (scroll-changed pane :horizontal :move x))
        (unless (= y (cdr reported)) (scroll-changed pane :vertical :move y))))))

;;; The bands the bars cover are the bars': a press, a move or a release there goes on to
;;; them, though the pane holding the keyboard is handed every event first, unless the pane
;;; holds the pointer for a press of its own.  The wheel stays the pane's over its bars too.
;;; One method per kind of event, each outranking the pane's own (pointer-down and
;;; pointer-up :around for text-pane).  NIL, not a decline: these run outside the toolkit's
;;; own restart for the call.
(macrolet ((bars-take (class)
             `(defmethod alloy:handle :around ((event ,class) (pane text-edit-view))
                (let ((right (editor:text-view-reserve-right pane))
                      (bottom (editor:text-view-reserve-bottom pane))
                      (at (alloy:location event)))
                  (if (and (or (plusp right) (plusp bottom))
                           (not (eq pane (pointer-capture (pointer-state))))
                           (alloy:with-unit-parent pane
                             (alloy::with-global-bounds (bounds pane)
                               (and (alloy:contained-p at bounds)
                                    (or (>= (alloy:pxx at) (- (+ (alloy:pxx bounds) (alloy:pxw bounds)) right))
                                        (< (alloy:pxy at) (+ (alloy:pxy bounds) bottom)))))))
                      nil
                      (call-next-method))))))
  (bars-take alloy:pointer-down)
  (bars-take alloy:pointer-up)
  (bars-take alloy:pointer-move)
  (bars-take alloy:pointer-double-click))

;;; The content of a wrapped view is measured a slice a frame after its width changed
;;; (alloy-editor/view.lisp: animation:update :after for text-view), which moves no text:
;;; so is the widest line of an unwrapped one after its widest line went: the bars are
;;; drawn again when the size or the place they read has changed.
(defmethod org.shirakumo.alloy.animation:update :after ((pane text-edit-view) dt)
  (declare (ignore dt))
  (when (and (scrollbars pane) (editor:text-view-layout pane))
    (multiple-value-bind (width height) (scroll-content-size pane)
      (let ((left (scroll-x pane))
            (top (scroll-y pane))
            (read (slot-value pane 'bars-read)))
        (unless (and read (= width (first read)) (= height (second read))
                     (= left (third read)) (= top (fourth read)))
          (setf (slot-value pane 'bars-read) (list width height left top))
          (mark-scrollbars pane))))))

;;; the bands the bars cover, decided in this same pass by the window's scrolling
;;; (view/render.lisp: prepare-for-render :before for scroll-mixin): the text gives
;;; them up in the frame the bars appear
(defmethod alloy:prepare-for-render :after ((pane text-edit-view) (renderer alloy:renderer))
  (multiple-value-bind (horizontal vertical) (scrollbar-axes pane)
    (setf (editor:text-view-reserve-right pane) (if vertical *scrollbar-track-px* 0.0)
          (editor:text-view-reserve-bottom pane) (if horizontal *scrollbar-track-px* 0.0))))
