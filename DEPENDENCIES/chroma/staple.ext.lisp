(asdf:load-system :staple-markless)

(defpackage "chroma-docs"
  (:use #:cl)
  (:local-nicknames
   (#:chroma #:org.shirakumo.alloy.chroma)))

(defclass page* (staple:simple-page)
  ()
  (:default-initargs :document-package (find-package "chroma-docs")))

(defmethod staple:page-type ((system (eql (asdf:find-system :chroma))))
  'page*)

(defmethod staple:subsystems ((system (eql (asdf:find-system :chroma))))
  ())

(defmethod staple:definition-wanted-p ((_ definitions:source-transform) (page page*)) NIL)
