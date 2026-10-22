(in-package #:org.shirakumo.alloy.renderers.simple.code-palettes)

(defvar *here* #.(or *compile-file-pathname* *load-pathname* (error "Load please.")))

(defun lispify-name (name)
  (with-output-to-string (out)
    (loop with dash = T
          for char across name
          do (cond ((or #+sbcl (sb-unicode:whitespace-p char)
                        #-sbcl (find char '(#\Space #\Tab #\Linefeed #\Return))
                        (find char "-_,'`\"#;"))
                    (when (or (not dash) (eql dash :upcase))
                      (setf dash T)
                      (write-char #\- out)))
                   ((upper-case-p char)
                    (unless dash
                      (write-char #\- out))
                    (setf dash :upcase)
                    (write-char char out))
                   (T
                    (write-char (char-upcase char) out)
                    (setf dash NIL))))))

(defun translate-style (style)
  (cl-ppcre:register-groups-bind (var) ("#([0-9a-fA-F]+)" style)
    (parse-integer var :radix 16)))

(defun parse-style (xml)
  (let* ((plump:*tag-dispatchers* plump:*xml-tags*)
         (xml (plump:parse xml)))
    (list* (intern (string-upcase (lquery:$1 xml "style" (attr "name"))))
           (loop for entry across (lquery:$ xml "entry")
                 for style = (translate-style (plump:attribute entry "style"))
                 when style collect (intern (lispify-name (plump:attribute entry "type")) "KEYWORD")
                 when style collect style))))

(defun print-style (style &optional (stream *standard-output*))
  (let ((*package* #.*package*)
        (*print-case* :downcase))
    (destructuring-bind (name &rest keys) style
      (format stream "~&~%(~s ~s~{~%  (~s~32t#x~6,'0x)~})~%"
              'define-palette name keys))))

(defun translate-styles (&optional (stream *standard-output*))
  (dolist (file (directory (merge-pathnames "**/*.xml" *here*)))
    (print-style (parse-style file) stream)))

(defun compile-palettes-file ()
  (with-open-file (out (merge-pathnames "palettes.lisp" *here*)
                       :direction :output :if-exists :supersede)
    (format out ";;;; Auto-generated using XML sources from the alecthomas/Chroma project.~%")
    (format out "(in-package ~s)" (package-name #.*package*))
    (translate-styles out)))
