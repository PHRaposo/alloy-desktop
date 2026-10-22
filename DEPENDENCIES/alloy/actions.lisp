(in-package #:org.shirakumo.alloy)

(defclass action-event (direct-event) ())

(defmacro define-action-event (name &body options)
  (form-fiddle:with-body-options (mappings options superclasses slots) options
    `(progn
       (defclass ,name (,@superclasses action-event)
         ,slots ,@options)
       
       ,@(loop for (input-map event-sequence . args) in mappings
               collect `(define-input-mapping ,event-sequence ,name
                          :input-map ',input-map
                          ,@args))
       ',name)))

(define-action-event paste-event
  :slots ((content :initarg :content :initform (arg! :content) :reader content))
  (default "C-v" :content (clipboard ui)))

(define-action-event copy-event
  (default "C-c"))

(define-action-event cut-event
  (default "C-x"))

(define-action-event reset-event)

(define-action-event focus-event)

(define-action-event focus-next
  :superclasses (focus-event)
  (default "TAB"))

(define-action-event focus-prev
  :superclasses (focus-event)
  (default "S-TAB"))

(define-action-event focus-up
  :superclasses (focus-event)
  (default "<Up>"))

(define-action-event focus-down
  :superclasses (focus-event)
  (default "<Down>"))

(define-action-event focus-left
  :superclasses (focus-event)
  (default "<Left>"))

(define-action-event focus-right
  :superclasses (focus-event)
  (default "<Right>"))

(define-action-event activate
  :superclasses (focus-event)
  (default "RET"))

(define-action-event exit
  :superclasses (focus-event)
  (default "ESC"))
