(asdf:load-system :staple-markless)
(defmethod staple:subsystems ((_ (eql (asdf:find-system :imagine)))) ())
