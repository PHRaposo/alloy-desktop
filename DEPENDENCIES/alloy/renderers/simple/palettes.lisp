(in-package #:org.shirakumo.alloy.renderers.simple)

;; States should be one of the following. If no specific pattern is
;; defined for the given state, the default state's pattern is used.
;; - NIL
;;   For the "default" state
;; - :disabled
;;   For elements that are uninteractable
;; - :weak-focus
;;   For elements with :weak focus
;; - :strong-focus
;;   For elements with :strong focus
;; - :activated
;;   For elements that are currently in a special "active" state such
;;   as buttons in their pressed state, and so on.
;;
;; Pattern names can be one of the following, where a background is
;; the general "fill" pattern of an element, and the foreground is the
;; text pattern of the element.
;; - :window
;;   Used for the background of the top-level window, if any
;; - :border
;;   The general border colour to be used around elements
;; - :background
;; - :foreground
;;   Generic patterns for all layout elements
;; - :background-alt
;;   Alternate pattern for use in tables and listings
;; - :tooltip-background
;; - :tooltip-foreground
;;   Patterns for tooltip popups, which should stand out from the rest
;; - :component-background
;; - :component-foreground
;;   Generic patterns for interactable components
;; - :input-background
;; - :input-foreground
;;   Specific overrides for text input components, though usually
;;   aliased to the :component patterns
;; - :placeholder-foreground
;;   Text pattern for the placeholder value in text input components
;; - :alert-background
;; - :alert-foreground
;;   Patterns for use in elements that signify an alert, warning, or
;;   similar element that needs special highlighting
;; - :notice-background
;; - :notice-foreground
;;   Patterns for use in elements that signify a message, notice, or
;;   similar informational text to the user

(define-palette dark
  (:window                 #x151515)
  (:border                 #x505050)
  (:background             #x303030)
  (:foreground             #xF0F0F0)
  (:background-alt         #x383838)
  (:tooltip-background     #x404040)
  (:tooltip-foreground     #xF0F0FF)
  (:component-background   #x0088EE)
  (:component-foreground   #xF0F0F0)
  (:input-background       #x383838)
  (:input-foreground       #xF0F0F0)
  (:placeholder-foreground #x808080)
  (:alert-background       #xFF0000)
  (:alert-foreground       #xFFFFFF)
  (:notice-background      #x0088EE)
  (:notice-foreground      #xFFFFFF)
  :weak-focus
  (:border                 #x808080)
  (:component-background   #x1199FF)
  (:input-background       #x404040)
  :strong-focus
  (:border                 #xD0D0D0)
  (:component-background   #x33AAFF)
  (:input-background       #x484848)
  (:placeholder-foreground #xA0A0A0)
  :disabled
  (:component-background   #x40484E)
  (:component-foreground   #x808080)
  (:input-background       #x343434)
  (:input-foreground       #x808080)
  (:placeholder-foreground #x606060)
  :activated
  (:component-background   #xE0E0E0)
  (:component-foreground   #x303030))

(define-palette light
  (:window                 #xF0F0F0)
  (:border                 #xD0D0D0)
  (:background             #xE0E0E0)
  (:foreground             #x151515)
  (:background-alt         #xE8E8E8)
  (:tooltip-background     #xD8D8D8)
  (:tooltip-foreground     #x202020)
  (:component-background   #x0088EE)
  (:component-foreground   #xF0F0F0)
  (:input-background       #xD0D0D0)
  (:input-foreground       #x505050)
  (:placeholder-foreground #x808080)
  (:alert-background       #xFF0000)
  (:alert-foreground       #xFFFFFF)
  (:notice-background      #x0088EE)
  (:notice-foreground      #xFFFFFF)
  :weak-focus
  (:border                 #xA0A0A0)
  (:component-background   #x1199FF)
  :strong-focus
  (:border                 #x33AAFF)
  (:component-background   #x33AAFF)
  (:input-background       #xE0E0E0)
  (:placeholder-foreground #xA0A0A0)
  :disabled
  (:component-background   #xB0B8BF)
  (:component-foreground   #x808080)
  (:input-background       #xA0A0A0)
  (:input-foreground       #x606060)
  (:placeholder-foreground #x808080)
  :activated
  (:component-background   #x80D0FF)
  (:component-foreground   #xFFFFFF))
