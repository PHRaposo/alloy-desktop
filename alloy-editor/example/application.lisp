(defpackage #:alloy-editor-example
  (:nicknames #:allex)
  (:use #:cl)
  (:local-nicknames (#:alloy #:org.shirakumo.alloy)
                    (#:animation #:org.shirakumo.alloy.animation)
                    (#:window #:org.shirakumo.alloy.windowing)
                    (#:glfw #:org.shirakumo.fraf.glfw)
                    (#:%glfw #:org.shirakumo.fraf.glfw.cffi)
                    (#:glfw-renderer #:org.shirakumo.alloy.renderers.glfw)
                    (#:simple #:org.shirakumo.alloy.renderers.simple)
                    (#:colors #:org.shirakumo.alloy.chroma.colors)
                    (#:discovery #:org.shirakumo.font-discovery)
                    (#:bt #:bordeaux-threads)
                    (#:alle #:alloy-editor))
  (:export #:run #:make-application #:frame #:closing-p #:application #:live-window
           #:application-window #:application-editor #:application-search
           #:application-listener #:application-status #:application-document
           #:application-font-name #:application-message #:application-frames
           #:*application* #:*prompt* #:*monospaced-families* #:*welcome*
           #:*poll-timeout* #:*font-points* #:*host-keys* #:*search-keys*))

(in-package #:alloy-editor-example)

(defparameter *monospaced-families* '("Consolas" "DejaVu Sans Mono" "Courier New")
  "Faces the panes ask for by name, in order; the first one answered for is taken.")

(defparameter *monospaced-files*
  (list #p"C:/Windows/Fonts/consola.ttf"
        #p"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
        #p"/System/Library/Fonts/Menlo.ttc")
  "Files a face is taken from when the system answers for no name.")

(defparameter *font-points* 11
  "Size the panes ask for, in typographic points.")

(defparameter *prompt* "> "
  "What stands before the text handed to the pane at the bottom.")

(defparameter *welcome*
  ";; A pane of the editor, reading its text as code.
;; Ctrl+S writes the file, Ctrl+F opens the bar above the pane below,
;; F3 and Shift+F3 walk the matches, F6 crosses to that pane and back,
;; Ctrl+Z and Ctrl+Y walk the history, Ctrl+Space opens the names.
(defun greet (name)
  (format t \"~&hello, ~A~%\" name))
"
  "What the pane holds when it was opened on no file.")

(defvar *application* nil
  "The window the commands of this file act on.")

(defstruct (application (:constructor %make-application) (:copier nil)
                        (:predicate nil))
  "One window: the three panes, the line under them, its document and its stream."
  window editor search listener status document stream
  (font-name "") (message "") (evaluated nil) (frames 0))

;;; the face

(defun %pick-font (renderer)
  "(values FONT NAME) of the first monospaced face that can be had, NIL for none."
  (dolist (family *monospaced-families*)
    (when (discovery:find-font :family family)
      (return-from %pick-font (values (simple:request-font renderer family) family))))
  (dolist (file *monospaced-files* (values nil "default face"))
    (when (probe-file file)
      (return (values (simple:request-font renderer file) (file-namestring file))))))

(defun %font-size (points)
  "POINTS as a unit of the toolkit, at the ninety-six dots an inch a unit is."
  (alloy:un (* points 4/3)))

;;; the line

(defun %note (app format &rest arguments)
  "Keep one line to show under the panes."
  (setf (application-message app) (apply #'format nil format arguments)))

(defun %status-line (app)
  "Where the caret stands, how the file is written, the face, and the last line."
  (let* ((view (application-editor app))
         (buffer (alle:text-view-buffer view))
         (caret (or (alle:text-view-caret view) 0))
         (line (alle:buffer-line-of-index buffer caret))
         (document (application-document app)))
    (format nil "~D:~D~:[~; *~]   ~A ~A   ~A   ~A"
            (1+ line) (- caret (alle:buffer-line-start buffer line))
            (alle:buffer-modified-p buffer)
            (alle:document-encoding document) (alle:document-eol-style document)
            (application-font-name app) (application-message app))))

(defun %refresh-status (app)
  "Put that line on the label, writing only when it really changed."
  (let ((line (%status-line app))
        (label (application-status app)))
    (unless (equal line (alloy:value label))
      (setf (alloy:value label) line)
      (alloy:mark-for-render label))))

;;; the keys

(alle:define-command :host-save (view)
  "Write the document the top pane holds back to the file it came from."
  (declare (ignore view))
  (let* ((app *application*)
         (document (application-document app))
         (path (alle:document-pathname document)))
    (cond ((null path) (%note app "this text belongs to no file"))
          ((alle:document-changed-on-disk-p document)
           (%note app "~A changed on disk; nothing was written"
                  (file-namestring path)))
          (t (handler-case (progn (alle:write-document document)
                                  (%note app "wrote ~A" (file-namestring path)))
               (alle:document-error (condition) (%note app "~A" condition)))))))

(alle:define-command :host-find (view)
  "Open the bar with whatever the pane it was asked from has marked already in it."
  (let ((app *application*)
        (bar (application-search *application*)))
    (multiple-value-bind (start end) (alle:text-view-selection view)
      (when (and start (not (eq view bar)))
        (setf (alle:text-view-text bar)
              (alle:buffer-substring (alle:text-view-buffer view) start end))))
    (setf (alloy:focus bar) :strong)
    (alle:run-command bar :select-all)
    (%note app "searching")))

(defun %find (app direction)
  "Take the top pane to the next place the bar's text stands, or to the one before."
  (let ((string (alle:text-view-text (application-search app)))
        (view (application-editor app)))
    (if (zerop (length string))
        (%note app "nothing to look for")
        (multiple-value-bind (ran found)
            (alle:run-command view (if (eq direction :backward) :find-previous :find-next)
                             string :wrap t)
          (declare (ignore ran))
          (%note app (if found "~A: found" "~A: no more") string)))))

(alle:define-command :host-find-next (view)
  "Take the top pane to the next place the bar's text stands."
  (declare (ignore view))
  (%find *application* :forward))

(alle:define-command :host-find-previous (view)
  "Take the top pane to the place before that."
  (declare (ignore view))
  (%find *application* :backward))

(alle:define-command :host-focus-editor (view)
  "Give the keyboard back to the top pane."
  (declare (ignore view))
  (setf (alloy:focus (application-editor *application*)) :strong))

(alle:define-command :host-other-pane (view)
  "Cross between the pane holding the file and the pane text is handed to."
  (let* ((app *application*)
         (other (if (eq view (application-listener app))
                    (application-editor app)
                    (application-listener app))))
    (setf (alloy:focus other) :strong)))

(defparameter *host-keys*
  '((:s (:control) :host-save)
    (:f (:control) :host-find)
    (:f3 () :host-find-next)
    (:f3 (:shift) :host-find-previous)
    (:f6 () :host-other-pane)
    (:y (:control) :redo)
    (:space (:control) :complete))
  "What the window binds of its own, in every one of its three panes.")

(defparameter *search-keys*
  '((:enter () :host-find-next)
    (:kp-enter () :host-find-next)
    (:enter (:shift) :host-find-previous)
    (:kp-enter (:shift) :host-find-previous)
    (:escape () :host-focus-editor))
  "What the bar answers to over and above the window's own table and its family's.")

;;; handing over

(defun %evaluate (app text)
  "Read and run TEXT away from the thread that draws, printing into the pane."
  (let ((stream (application-stream app)))
    (bt:make-thread
     (lambda ()
       (unwind-protect
            (let ((*standard-output* stream)
                  (*error-output* stream)
                  (*package* (find-package "COMMON-LISP-USER")))
              (handler-case
                  (dolist (value (multiple-value-list (eval (read-from-string text))))
                    (format stream "~&~S~%" value))
                (error (condition) (format stream "~&~A~%" condition))))
         (setf (application-evaluated app) t)))
     :name "alloy-editor-example evaluator")))

;;; the window

(defclass live-window (glfw-renderer:window)
  ((application :initform nil :accessor window-application))
  (:documentation "A window that draws its own frame from the callbacks the desktop calls."))

(defun %apply-content-scale (win)
  "Take the desktop's own scale for WIN into the toolkit's unit, once."
  (let ((scale (first (glfw:content-scale win)))
        (ratio (/ (float (first (glfw:framebuffer-size win)) 0f0)
                  (max 1.0 (float (first (glfw:size win)) 0f0)))))
    (setf (alloy:base-scale win) (/ (float scale 0f0) ratio))))

(defun %own-input-map (win)
  "Give WIN a table of its own, without the toolkit's own paste in it."
  ;; that entry reads the desktop's clipboard for the key ITSELF, and the read
  ;; signals when the desktop holds something that is not text
  (let ((map (make-instance 'alloy:input-map :name "alloy-editor-example"
                                             :inherit t)))
    (setf (alloy:mappings map)
          (remove-if (lambda (mapping)
                       (string= "C-v" (alloy:print-input-sequence
                                       (alloy:event-sequence mapping) t)))
                     (alloy:mappings map)))
    (setf (alloy:input-map win) map)))

(defun %place-frame (win)
  "Put the whole frame of the still hidden WIN inside the desktop's usable area."
  (destructuring-bind (left top right bottom) (glfw:frame-size win)
    (destructuring-bind (mx my mw mh) (glfw:work-area (glfw:primary-monitor))
      (destructuring-bind (w h) (glfw:size win)
        (setf (glfw:location win)
              (list (+ mx left (max 0 (floor (- mw left w right) 2)))
                    (+ my top (max 0 (floor (- mh top h bottom) 2)))))))))

(defun %size-tree (win)
  "Size the tree and build the projection from the size WIN really has."
  (destructuring-bind (w h) (glfw:size win)
    (glfw:window-resized win w h)))

(defun %install-keys (editor search listener)
  "Give each pane the window's own table on top of the one of its family."
  (setf (alle:text-view-keymap editor) (append *host-keys* alle:*editor-keymap*)
        (alle:text-view-keymap search) (append *search-keys* *host-keys*
                                              alle:*field-keymap*)
        (alle:text-view-keymap listener) (append *host-keys* alle:*input-keymap*)))

(defun %make-view (buffer font &rest arguments)
  (apply #'alle:make-text-view buffer :font font :mode :lisp
                                     :font-size (%font-size *font-points*)
                                     arguments))

(defun make-application (screen &key file (state :normal) (width 900) (height 700))
  "Open one window of WIDTH by HEIGHT on SCREEN and answer it, shown unless STATE is :HIDDEN."
  ;; the hints of the toolkit are state of the process and are never reset by it
  (%glfw:default-window-hints)
  (let* ((win (window:make-window screen
                                  :title "alloy-editor example"
                                  :class 'live-window
                                  :bounds (alloy:px-size width height)
                                  :state :hidden
                                  :background-color colors:white))
         (document (if file
                       (alle:read-document file)
                       (let ((buffer (alle:make-buffer *welcome*)))
                         (alle:make-document :buffer buffer))))
         (layout (make-instance 'alloy:grid-layout
                                :col-sizes '(t) :row-sizes '(t 26 220 22)
                                :cell-margins (alloy:margins 0)
                                :layout-parent (alloy:layout-tree win)))
         (focus (make-instance 'alloy:focus-list
                               :focus-parent (alloy:focus-tree win)))
         (app nil))
    (%place-frame win)
    (%apply-content-scale win)
    (%own-input-map win)
    ;; the panes stand on white, so what the toolkit draws of its own takes dark ink
    (setf (simple:palette win) 'simple:light)
    (multiple-value-bind (font name) (%pick-font win)
      (let* ((editor (%make-view (alle:document-buffer document) font
                                 :gutter-p t :wrap-marker-p t))
             (search (%make-view (alle:make-buffer "") font
                                 :mode nil :gesture-policy :field :single-line-p t
                                 :wrap-p nil :bg-color colors:white-smoke))
             (listener (%make-view (alle:make-buffer "") font :wrap-p t))
             (status (make-instance 'alloy:label* :value "")))
        (setf app (%make-application :window win :editor editor :search search
                                     :listener listener :status status
                                     :document document :font-name name))
        (setf (window-application win) app)
        (setf (application-stream app) (alle:make-text-view-stream listener))
        (setf *application* app)
        (%install-keys editor search listener)
        (dolist (view (list editor search listener))
          (setf (alle:text-view-message view)
                (lambda (v kind string)
                  (declare (ignore v))
                  (%note app "~(~A~): ~A" kind string))))
        (setf (alle:text-view-accept listener)
              (lambda (view string)
                (declare (ignore view))
                (%evaluate app string)))
        (setf alle:*clipboard-writer*
              (lambda (view text)
                (declare (ignore view))
                (setf (glfw:clipboard-string win) text))
              alle:*clipboard-reader*
              (lambda (view) (declare (ignore view)) (glfw:clipboard-string win)))
        (loop for view in (list editor search listener)
              for row from 0
              do (alloy:enter view layout :row row :col 0)
                 (alloy:enter view focus))
        (alloy:enter status layout :row 3 :col 0)
        (alle:text-view-write-prompt listener *prompt*)
        (setf (alloy:focus editor) :strong)
        (%size-tree win)
        (%refresh-status app)
        (alloy:render win win)
        (unless (eq state :hidden)
          (glfw:show win))
        app))))

(defun %draw (app dt)
  "Everything one frame draws: the queued text, the prompt owed, the line under the panes, the animations and the render."
  (let ((win (application-window app)))
    (incf (application-frames app))
    (alle:drain-pending (application-listener app))
    (when (application-evaluated app)
      (setf (application-evaluated app) nil)
      (alle:text-view-write-prompt (application-listener app) *prompt*))
    (%refresh-status app)
    (animation:update win (float dt 0f0))
    (alloy:render win win)))

(defun frame (app &optional (dt 0.016) (timeout 0d0))
  "One whole frame: the events, then everything a frame draws, waiting TIMEOUT seconds for an event before going on."
  (glfw:poll-events :timeout timeout)
  (%draw app dt))

(defun %draw-from-callback (win)
  "Draw the whole frame inside the callback: the desktop holds its own loop while a border is dragged, so the host's loop does not turn until the border is let go."
  (let ((app (window-application win)))
    ;; the clock does not move here: nothing of the window is animated while a
    ;; border is held, and a frame drawn from a callback answers to no cadence
    (when app (%draw app 0.0))))

(defmethod glfw:window-resized :after ((win live-window) width height)
  "Follow the new size at once, with the pixels the new size asks for."
  (declare (ignore width height))
  (%draw-from-callback win))

(defmethod glfw:window-refreshed :after ((win live-window))
  "Draw again at once: this is what the desktop asks for in place of a resize."
  (%draw-from-callback win))

(defun closing-p (app)
  (glfw:should-close-p (application-window app)))

(defparameter *poll-timeout* (float 1/30 0d0)
  "Seconds a frame of the loop waits for an event before going on.")

(defun run (&optional file &key (state :normal) (width 900) (height 700))
  "Open the window on FILE and keep it until it is closed, saying on the way out whether the text was changed and not written."
  (glfw:init)
  (unwind-protect
       (let* ((screen (make-instance 'glfw-renderer:screen))
              (app (make-application screen :file file :state state
                                            :width width :height height))
              (last (get-internal-real-time)))
         (loop until (closing-p app)
               do (let ((now (get-internal-real-time)))
                    (frame app (/ (float (- now last) 0f0)
                                  internal-time-units-per-second)
                           *poll-timeout*)
                    (setf last now)))
         (when (alle:buffer-modified-p (alle:document-buffer (application-document app)))
           (format t "~&The text was changed and not written.~%")
           (finish-output))
         (alloy:deallocate (application-window app)))
    (glfw:shutdown)))
