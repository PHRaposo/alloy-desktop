(defmethod staple:packages ((sys (eql (asdf:find-system :deploy))))
  (list (find-package "ORG.SHIRAKUMO.DEPLOY")))
