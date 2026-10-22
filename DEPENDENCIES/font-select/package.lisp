(defpackage #:font-select
  (:use #:cl)
  ;; protocol.lisp
  (:export
   #:*default-backend*
   #:font-select-error
   #:select
   #:backend
   #:finalize
   #:select-with)
  ;; defaults.lisp
  (:export
   #:no-backend-found
   #:determine-default-backend))

(defpackage #:font-select.win32
  (:use #:cl #:font-select)
  #+windows (:local-nicknames (#:com #:org.shirakumo.com-on))
  (:export #:win32))

(defpackage #:font-select.macos
  (:use #:cl #:font-select)
  (:export #:macos))

(defpackage #:font-select.yad
  (:use #:cl #:font-select)
  (:export #:yad))

(defpackage #:font-select.gtk
  (:use #:cl #:font-select)
  (:export #:gtk))
