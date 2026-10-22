(in-package #:org.shirakumo.deploy)

(defvar *here* #.(make-pathname :name NIL :type NIL :defaults (or *compile-file-pathname* *load-pathname*)))
(defparameter *data-location* #p"")
(defparameter *library-location* #+nx #p"nro/" #-nx #p"")
(defparameter *base-location* #p"")
(defparameter *status-output* T)

(defun make-lib-pathname (name)
  (make-pathname :name (string name)
                 :type #+(and unix (not darwin)) "so"
                 #+darwin "dylib"
                 #+windows "dll"
                 #+nx "nro"
                 #-(or unix darwin windows nx)
                 (error "Unknown target platform. No idea what its shared library pathname is!")))

(defun pathname-filename (path)
  (format NIL "~a~@[.~a~]"
          (pathname-name path) (pathname-type path)))

(defun status (level format-string &rest format-args)
  (when *status-output*
    (format *status-output*
            "~& ~a ~?~%" (case level
                           (0 "==>")
                           (1 "  ->")
                           (T "    >"))
            format-string format-args)))

(defun query-for-library-path ()
  (format *query-io* "~&[DEPLOY] Enter the library path: ")
  (finish-output *query-io*)
  (list (pathname-utils:parse-native-namestring (read-line *query-io*))))

(defun command-line-arguments ()
  #+abcl ext:*command-line-argument-list*
  #+allegro (sys:command-line-arguments)
  #+(or clasp ecl) (loop :for i :from 0 :below (si:argc) :collect (si:argv i))
  #+clisp (coerce (ext:argv) 'list)
  #+clozure ccl:*command-line-argument-list*
  #+cmucl  extensions:*command-line-strings*
  #+mezzano nil
  #+lispworks sys:*line-arguments-list*
  #+sbcl sb-ext:*posix-argv*)

(defun envvar (x)
  (declare (ignorable x))
  #+(or abcl clasp clisp ecl xcl) (ext:getenv x)
  #+allegro (sys:getenv x)
  #+clozure (ccl:getenv x)
  #+cmucl (unix:unix-getenv x)
  #+lispworks (lispworks:environment-variable x)
  #+sbcl (sb-ext:posix-getenv x))

(defun envvar-directory (var)
  (let ((var (envvar var)))
    (when (and var (string/= "" var))
      (pathname-utils:parse-native-namestring var :as :directory :junk-allowed T))))

(defun envvar-directories (variable)
  (mapcar (lambda (s) (pathname-utils:parse-native-namestring s :as :directory))
          (split #+windows #\; #-windows #\: (or (envvar variable) ""))))

(defun env-set-p (envvar)
  (let ((value (envvar envvar)))
    (when (and value (string/= "" value))
      value)))

(defun redirect-output (target)
  (let ((file (open target
                    :direction :output
                    :if-exists :append
                    :if-does-not-exist :create)))
    (setf *standard-output* file)
    (setf *error-output* file)
    (setf *trace-output* file)
    (setf *debug-io* (make-echo-stream *debug-io* file))
    (multiple-value-bind (ss mm hh d m y) (decode-universal-time (get-universal-time))
      (status 0 "Deploy log started on ~d.~2,'0d.~2,'0d ~d:~2,'0d:~2,'0d"
              y m d hh mm ss))
    file))

(defun featurep (feature)
  (member feature *features* :test #'string=))

(defun runtime-directory ()
  (cond ((and (featurep :nx) (deployed-p))
         (make-pathname :device "rom" :directory '(:absolute)))
        ((first (command-line-arguments))
         (or (ignore-errors
              (pathname-utils:to-directory
               (truename
                (pathname-utils:parse-native-namestring
                 (first (deploy:command-line-arguments))))))
             #+cffi
             (ignore-errors
              (pathname-utils:to-directory
               (truename
                (pathname-utils:parse-native-namestring
                 (cffi:foreign-funcall "getcwd" :string)
                 :as :directory))))
             *default-pathname-defaults*))
        (T
         *default-pathname-defaults*)))

(defun data-directory ()
  (let ((run (runtime-directory)))
    (pathname-utils:normalize-pathname
     (make-pathname :host (pathname-host run)
                    :defaults (merge-pathnames *data-location* run))
     :up-as-back T)))

(defun library-directory ()
  (let ((run (runtime-directory)))
    (pathname-utils:normalize-pathname
     (make-pathname :host (pathname-host run)
                    :defaults (merge-pathnames *library-location* run))
     :up-as-back T)))

(defun base-directory ()
  (let ((run (runtime-directory)))
    (pathname-utils:normalize-pathname
     (make-pathname :host (pathname-host run)
                    :defaults (merge-pathnames *base-location* run))
     :up-as-back T)))

(defun directory-contents (path &key (type :wild))
  (directory (make-pathname :name :wild :type type :defaults path)))

(defun copy-file (source target &key (if-exists :supersede))
  (flet ((copy-file (source target)
           (with-open-file (in source :element-type '(unsigned-byte 8) :direction :input)
             (with-open-file (out target :element-type '(unsigned-byte 8) :direction :output :if-exists :supersede)
               (when out (loop with buffer = (make-array 4096 :element-type '(unsigned-byte 8))
                               for read = (read-sequence buffer in)
                               while (< 0 read)
                               do (write-sequence buffer out :end read)))))))
    (cond ((null (probe-file target))
           (copy-file source target))
          ((equal (truename target) (truename source)))
          (T
           (ecase if-exists
             (:update
              (when (< (file-write-date target) (file-write-date source))
                (copy-file source target)))
             ((:replace :supersede :overwrite) 
              (copy-file source target))
             ((NIL :ignore))
             (:error
              (error "The file~%  ~a~%already exists." target)))))))

(defun copy-directory-tree (source target &key (copy-root T) (exclude (constantly NIL)) (if-exists :supersede))
  (labels ((r (path destination)
             (unless (funcall exclude path destination)
               (if (pathname-utils:directory-p path)
                   (let ((tpath (merge-pathnames (format NIL "~a/" (car (last (pathname-directory path))))
                                                 destination)))
                     (dolist (subpath (directory-contents path))
                       (r subpath tpath)))
                   (let ((destination (make-pathname :name (pathname-name path)
                                                     :type (pathname-type path)
                                                     :defaults destination)))
                     (ensure-directories-exist destination)
                     (copy-file path destination :if-exists if-exists))))))
    (if copy-root
        (r source target)
        (dolist (subpath (directory-contents source))
          (r subpath target)))))

(defun xml-escape (string)
  (with-output-to-string (out)
    (loop for c across string
          do (case c
               (#\< (format out "&lt;"))
               (#\> (format out "&gt;"))
               (#\& (format out "&amp;"))
               (T (write-char c out))))))

(defun system-applicable-p (system-spec)
  (or (eql T system-spec)
      (and (symbolp system-spec)
           (featurep (string-upcase system-spec)))
      (and (consp system-spec)
           (ecase (first system-spec)
             ((or :or)
              (loop for sub in (rest system-spec)
                    thereis (system-applicable-p sub)))
             ((and :and)
              (loop for sub in (rest system-spec)
                    always (system-applicable-p sub)))
             ((not :not)
              (not (system-applicable-p (second system-spec))))))))

(defun resolve-cffi-spec (spec)
  (labels ((resolve-inner-spec (spec)
             (etypecase spec
               ((or string pathname)
                (list (pathname spec)))
               (cons
                (ecase (first spec)
                  (:or
                   (loop for other in (rest spec)
                         append (resolve-inner-spec other)))
                  (:framework
                   (warn "Deploy does not currently support Darwin frameworks.")
                   ())
                  (:default
                   (list (make-lib-pathname (second spec)))))))))
    (loop for (system-spec spec) in spec
          when (system-applicable-p system-spec)
          append (resolve-inner-spec spec))))

(defun split (split string &key (start 0) (end (length string)))
  (let ((out (make-string-output-stream))
        (pieces ()))
    (flet ((add ()
             (let ((string (get-output-stream-string out)))
               (unless (string= string "")
                 (push string pieces)))))
      (loop for i from start below end
            for c = (char string i)
            do (if (char= c split)
                   (add)
                   (write-char c out))
            finally (add))
      (nreverse pieces))))

(defun parse-vars (file)
  (with-open-file (stream file)
    (remove NIL
            (loop for line = (read-line stream NIL NIL)
                  while line
                  collect (let ((pos (position #\= line)))
                            (when pos
                              (cons (subseq line 0 pos)
                                    (split #\ (subseq line (1+ pos))))))))))

(defun determine-output-width (&optional (default 80))
  (or #+unix
      (ignore-errors
       (cffi:with-foreign-objects ((ent :char 2048))
         #+darwin (cffi:load-foreign-library "libncursesw.dylib")
         #-darwin (cffi:load-foreign-library "libncursesw.so")
         (when (<= 0 (cffi:foreign-funcall "tgetent" :pointer ent :string (envvar "TERM") :int))
           (cffi:foreign-funcall "tgetnum" :string "co" :int))))
      #+linux
      (ignore-errors
       (cffi:with-foreign-objects ((winsize :ushort 4))
         (cffi:foreign-funcall "ioctl" :int 1 #|STDOUT_FILENO|# :int #x5413 #|TIOCGWINSZ|# :pointer winsize :int)
         (when (< (cffi:mem-ref winsize :ushort) 8000)
           (cffi:mem-ref winsize :ushort))))
      #+windows
      (ignore-errors
       (cffi:with-foreign-objects ((winsize :ushort 12))
         (when (cffi:foreign-funcall "GetConsoleScreenBufferInfo"
                                     :pointer (cffi:foreign-funcall "GetStdHandle" :uint32 4294967285 :pointer)
                                     :pointer winsize :bool)
           (cffi:mem-ref winsize :ushort))))
      default))

(defvar *run-output* :string)
(defun run (program &rest args)
  (labels ((fixup (arg)
             (etypecase arg
               (string (list arg))
               (null ())
               (cons (loop for a in arg append (fixup a)))
               (pathname (list (pathname-utils:native-namestring arg))))))
    (let ((ret (uiop:run-program (list* program (fixup args)) :output *run-output* :error-output *error-output*)))
      (if (stringp ret)
          (string-right-trim '(#\Linefeed #\Return) ret)
          ret))))
