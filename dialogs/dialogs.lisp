(in-package :alloy-desktop)

(defclass dialog-service (desktop-service) ())
(defclass file-dialog-service (dialog-service) ())
(defclass color-dialog-service (dialog-service) ())
(defclass font-dialog-service (dialog-service) ())

(defgeneric choose-existing-file (service &key title default filter))
(defgeneric choose-new-file (service &key title default filter))
(defgeneric choose-directory (service &key title default))
(defgeneric choose-new-directory (service &key title default))
(defgeneric choose-color (service &key title default full-open prevent-full-open))
(defgeneric choose-font (service &key default variant))

#+(or win32 darwin)
(defun %native-dialog-owner-options ()
  (let ((owner (car *native-dialog-state*)))
    (when (window-alive-p owner)
      (list :owner #+win32 (%window-hwnd owner)
                   #+darwin (%glfw-get-cocoa-window (%glfw:pointer owner))))))

#+(or win32 darwin)
(defmethod choose-existing-file :around ((service file-dialog-service) &key title default filter)
  (call-with-native-dialog (lambda () (call-next-method))))

#+(or win32 darwin)
(defmethod choose-new-file :around ((service file-dialog-service) &key title default filter)
  (call-with-native-dialog (lambda () (call-next-method))))

#+(or win32 darwin)
(defmethod choose-directory :around ((service file-dialog-service) &key title default)
  (call-with-native-dialog (lambda () (call-next-method))))

#+(or win32 darwin)
(defmethod choose-new-directory :around ((service file-dialog-service) &key title default)
  (call-with-native-dialog (lambda () (call-next-method))))

#+(or win32 darwin)
(defmethod choose-color :around ((service color-dialog-service) &key title default full-open prevent-full-open)
  (call-with-native-dialog (lambda () (call-next-method))))

#+(or win32 darwin)
(defmethod choose-font :around ((service font-dialog-service) &key default variant)
  (call-with-native-dialog (lambda () (call-next-method))))

(defmethod choose-existing-file ((service file-dialog-service) &key title default filter)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'org.shirakumo.file-select:existing
         :title title :default default :filter filter (%native-dialog-owner-options))
  #-(or darwin win32)
  (org.shirakumo.file-select:existing
   :title title :default default :filter filter))

(defmethod choose-new-file ((service file-dialog-service) &key title default filter)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'org.shirakumo.file-select:new
         :title title :default default :filter filter (%native-dialog-owner-options))
  #-(or darwin win32)
  (org.shirakumo.file-select:new
   :title title :default default :filter filter))

(defmethod choose-directory ((service file-dialog-service) &key title default)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'org.shirakumo.file-select:existing
         :title title :default default :filter :directory (%native-dialog-owner-options))
  #-(or darwin win32)
  (org.shirakumo.file-select:existing
   :title title :default default :filter :directory))

(defmethod choose-new-directory ((service file-dialog-service) &key title default)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'org.shirakumo.file-select:new
         :title title :default default (%native-dialog-owner-options))
  #-(or darwin win32)
  (org.shirakumo.file-select:new
   :title title :default default))

(defmethod choose-color ((service color-dialog-service)
                         &key title default full-open prevent-full-open)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'color-select:choose-color :title title :default default
         :full-open full-open :prevent-full-open prevent-full-open
         (%native-dialog-owner-options))
  #-(or win32 darwin)
  (color-select:choose-color :title title
                             :default default
                             :full-open full-open
                             :prevent-full-open prevent-full-open))

(defmethod choose-font ((service font-dialog-service) &key default variant)
  (declare (ignore service))
  #+(or win32 darwin)
  (apply #'font-select:select :default default :variant variant
         (%native-dialog-owner-options))
  #-(or win32 darwin)
  (font-select:select :default default :variant variant))
