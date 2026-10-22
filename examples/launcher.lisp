(defpackage #:alloy-desktop-examples
  (:use #:cl)
  (:export #:define-example #:launcher))

(in-package #:alloy-desktop-examples)

;;; The examples launcher. Every example runs in this one desktop session: an example
;;; file holds a DEFINE-EXAMPLE whose body opens and shows its windows on SCREEN and
;;; returns; the launcher's event loop serves them. Closing the launcher window ends
;;; the session and closes every window still open.

(defvar *example* nil
  "The example function the file being loaded defines.")

(defmacro define-example ((screen) &body body)
  "Define the example of the file being loaded: BODY opens and shows its windows on SCREEN."
  `(setf *example* (lambda (,screen) ,@body)))

(defparameter *examples-directory*
  (make-pathname :name nil :type nil :defaults *load-truename*)
  "The folder holding this file and one folder per category.")

(defparameter *categories*
  '(("Windows" "windows") ("Layout" "layout") ("Widgets" "widgets"))
  "Button text and folder of each category.")

(defparameter *margin* 16)
(defparameter *gap* 8)
(defparameter *title-height* 32)
(defparameter *button-height* 34)
(defparameter *category-button-width* 140)
(defparameter *example-button-width* 300)
(defparameter *rows-per-column* 8)

(defun font (points)
  "The platform's UI family at POINTS."
  (list (first alloy-desktop:*fallback-families*) points))

(defun example-label (file)
  "\"NN - Words of the name\" for the example FILE named NN-words-of-the-name."
  (let* ((name (pathname-name file))
         (dash (position #\- name))
         (words (substitute #\Space #\- (subseq name (1+ dash)))))
    (format nil "~A - ~@(~A~)" (subseq name 0 dash) words)))

(defun load-category (folder)
  "List of (LABEL . FUNCTION), one per example file of FOLDER, in file-name order."
  (loop for file in (sort (uiop:directory-files
                           (merge-pathnames (format nil "~A/" folder) *examples-directory*)
                           "*.lisp")
                          #'string< :key #'pathname-name)
        collect (let ((*example* nil))
                  (load file)
                  (unless *example*
                    (error "~A defines no example." file))
                  (cons (example-label file) *example*))))

(defun make-launcher-window (screen title width height)
  "A hidden fixed-size window whose content is WIDTH x HEIGHT logical units."
  (let* ((window (alloy-desktop:make-window screen :title title :width width :height height
                                                   :resizable-p nil))
         (scale (alloy-desktop:window-content-scale window)))
    ;; make-window takes px and PLACE logical units
    (alloy-desktop:set-window-size window (round (* scale width)) (round (* scale height)))
    window))

(defun place-button (root text action x y width)
  (alloy-desktop:place root
                       (make-instance 'alloy-desktop:button :text text :font (font 12)
                                                            :on-activate action)
                       x y width *button-height*))

(defun open-category (screen title examples)
  "Open a window with a button for each of EXAMPLES, a list of (LABEL . FUNCTION)."
  (let* ((count (length examples))
         (columns (ceiling count *rows-per-column*))
         (rows (ceiling count columns))
         (window (make-launcher-window
                  screen (format nil "ALLOY-DESKTOP: ~:@(~A~)" title)
                  (+ (* 2 *margin*) (* columns *example-button-width*) (* (1- columns) *gap*))
                  (+ (* 2 *margin*) (* rows *button-height*) (* (1- rows) *gap*))))
         (root (alloy-desktop:window-root-layout window)))
    (loop for (label . function) in examples
          for index from 0
          do (let ((function function))
               (multiple-value-bind (column row) (floor index rows)
                 (place-button root label (lambda () (funcall function screen))
                               (+ *margin* (* column (+ *example-button-width* *gap*)))
                               (+ *margin* (* row (+ *button-height* *gap*)))
                               *example-button-width*))))
    (alloy-desktop:show-window window)
    window))

(defun launcher ()
  "Open the examples launcher and serve every window until the launcher window is closed."
  (let ((categories (loop for (title folder) in *categories*
                          collect (list title (load-category folder)))))
    (alloy-desktop:with-desktop-application (screen)
      (let* ((width (+ (* 2 *margin*) (* 3 *category-button-width*) (* 2 *gap*)))
             (main (make-launcher-window screen "ALLOY-DESKTOP: EXAMPLES" width
                                         (+ (* 2 *margin*) *title-height* *gap* *button-height*)))
             (root (alloy-desktop:window-root-layout main))
             (open (make-hash-table :test 'equal)))
        (alloy-desktop:place root (make-instance 'alloy-desktop:static-text
                                                 :text "ALLOY-DESKTOP: EXAMPLES" :font (font 16))
                             *margin* *margin* (- width (* 2 *margin*)) *title-height*)
        (loop for (title examples) in categories
              for index from 0
              do (let ((title title) (examples examples))
                   (place-button root title
                                 (lambda ()
                                   (let ((window (gethash title open)))
                                     (if (and window (alloy-desktop:window-alive-p window))
                                         (alloy-desktop:raise-window window)
                                         (setf (gethash title open)
                                               (open-category screen title examples)))))
                                 (+ *margin* (* index (+ *category-button-width* *gap*)))
                                 (+ *margin* *title-height* *gap*)
                                 *category-button-width*)))
        (alloy-desktop:show-window main)
        (alloy-desktop:run-event-loop screen
                                      :until (lambda () (not (alloy-desktop:window-alive-p main))))))))

(launcher)
