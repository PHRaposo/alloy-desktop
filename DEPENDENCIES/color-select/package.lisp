(defpackage #:color-select
  (:use #:cl)
  ;; protocol.lisp
  (:export
   #:*default-backend*
   #:color-select-error
   #:choose-color
   #:backend
   #:finalize
   #:choose-color-with)
  ;; defaults.lisp
  (:export
   #:no-backend-found
   #:determine-default-backend))

(defpackage #:color-select.win32
  (:use #:cl #:color-select)
  (:export #:win32))

(defpackage #:color-select.macos
  (:use #:cl #:color-select)
  (:export #:macos))

(defpackage #:color-select.zenity
  (:use #:cl #:color-select)
  (:export #:zenity))

(defpackage #:color-select.kdialog
  (:use #:cl #:color-select)
  (:export #:kdialog))

(defpackage #:color-select.yad
  (:use #:cl #:color-select)
  (:export #:yad))

(defpackage #:color-select.gtk
  (:use #:cl #:color-select)
  (:export #:gtk))
