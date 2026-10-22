(defpackage #:os-fonts
  (:use #:cl)
  (:export
   #:os-fonts-error
   #:no-backend-found
   #:backend
   #:font-spec
   #:font-spec-role
   #:font-spec-family
   #:font-spec-native-family
   #:font-spec-size
   #:font-spec-weight
   #:font-spec-slant
   #:font-spec-source
   #:font-state
   #:font-state-fonts
   #:font-state-logical-dpi
   #:font-state-source
   #:font-state-dpi-awareness
   #:font-state-metrics
   #:*default-backend*
   #:default-backend
   #:determine-default-backend
   #:font-for-role
   #:system-font
   #:system-fixed-font
   #:snapshot
   #:logical-dpi
   #:dpi-awareness
   #:metrics
   #:metric
   #:native-advance-block
   #:generation
   #:refresh
   #:poll
   #:add-change-listener
   #:remove-change-listener
   #:finalize))

(defpackage #:os-fonts.linux
  (:use #:cl #:os-fonts)
  (:export #:linux))

(defpackage #:os-fonts.windows
  (:use #:cl #:os-fonts)
  (:export #:windows))

(defpackage #:os-fonts.macos
  (:use #:cl #:os-fonts)
  (:export #:macos))
