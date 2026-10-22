(in-package #:org.shirakumo.deploy)

(defvar *template-readtable* (copy-readtable))

(set-macro-character #\} (get-macro-character #\) *template-readtable*) NIL *template-readtable*)

(defun parse-template (object template &optional (key #'funcall))
  (with-open-file (in template :direction :input)
    (with-output-to-string (out)
      (loop for c = (read-char in NIL)
            while c
            do (cond ((char/= c #\{)
                      (write-char c out))
                     ((char= #\\ (peek-char NIL in))
                      (write-char c out)
                      (read-char in))
                     (T
                      (let* ((*readtable* *template-readtable*)
                             (list (read-delimited-list #\} in)))
                        (loop for symbol in list
                              for value = (funcall key symbol object)
                              do (when value
                                   (write-sequence
                                    (xml-escape (princ-to-string value))
                                    out)
                                   (return))))))))))

(defun create-template (object template output &optional (key #'funcall))
  (with-open-file (out output
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
    (write-sequence (parse-template object template key) out)))
