(in-package :cl-user)

(defpackage "ALLOY-DESKTOP"
  (:nicknames "ALLD")
  (:use "COMMON-LISP")
  (:local-nicknames ("ALLOY"          "ORG.SHIRAKUMO.ALLOY")
                    ("WINDOWING"      "ORG.SHIRAKUMO.ALLOY.WINDOWING")
                    ("GLFW"           "ORG.SHIRAKUMO.ALLOY.RENDERERS.GLFW")
                    ("%GLFW"          "ORG.SHIRAKUMO.FRAF.GLFW")
                    ("SIMPLE"         "ORG.SHIRAKUMO.ALLOY.RENDERERS.SIMPLE")
                    ("PRESENTATIONS"  "ORG.SHIRAKUMO.ALLOY.RENDERERS.SIMPLE.PRESENTATIONS")
                    ("CHROMA"         "ORG.SHIRAKUMO.ALLOY.CHROMA")
                    ("COLORS"         "ORG.SHIRAKUMO.ALLOY.CHROMA.COLORS")
                    ("COM"            "ORG.SHIRAKUMO.COM-ON")
                    ("EDITOR"         "ALLOY-EDITOR"))
  ;; The widget protocol and the colour constructor are Alloy's and chroma's own
  ;; symbols, re-exported: a consumer names them through this package only.
  (:import-from "ORG.SHIRAKUMO.ALLOY" "VALUE" "ORIENTATION" "RANGE" "ACTIVATE" "DECLINE")
  (:import-from "ORG.SHIRAKUMO.ALLOY.CHROMA" "RGB" "COLOR")
  (:export
   ;; Widget protocol and colour (Alloy and chroma symbols).
   #:rgb

   ;; Core callback seam.
   #:pane-scrolled
   #:window-activated
   #:window-closing
   #:window-closed
   #:window-shown
   #:files-dropped

   ;; Desktop UI executor.
   #:ui-thread
   #:on-ui-thread-p
   #:post-to-ui-thread
   #:call-on-ui-thread

   ;; Float traps and threads.
   #:mask-float-traps
   #:*process-initial-bindings*
   #:desktop-thread-entry
   #:make-desktop-thread
   #:kill-thread
   #:find-thread
   #:thread-state

   ;; Serial worker.
   #:serial-worker
   #:make-serial-worker
   #:serial-worker-name
   #:serial-worker-thread
   #:serial-worker-queue
   #:serial-worker-stop-p
   #:serial-worker-initial-bindings
   #:serial-worker-live-p
   #:serial-worker-start
   #:serial-worker-run
   #:serial-worker-enqueue
   #:serial-worker-request-stop
   #:serial-worker-destroy-thread
   #:serial-worker-abort
   #:with-serial-worker-lock

   ;; Finalization.
   #:finalize-on-gc
   #:cancel-finalize

   ;; Desktop session.
   #:desktop-screen
   #:with-desktop-application

   ;; Desktop event pump / frame scheduling.
   #:call-with-abort-restart
   #:capture-backtrace
   #:call-guarded-iteration
   #:call-guarded-on-window
   #:frame-once
   #:run-event-loop

   ;; Window protocol and structure.
   #:window
   #:window-registered-p
   #:registered-windows
   #:find-window
   #:window-alive-p
   #:share-window
   #:reap-dead-windows
   #:raise-window
   #:show-window-without-focus
   #:window-owner
   #:make-window
   #:window-root-layout
   #:window-focus-list
   #:window-chrome
   #:*default-window-background*
   #:place-window-frame
   #:set-window-size
   #:screen-size
   #:set-window-size-limits
   #:set-window-min-size
   #:window-content-to-frame
   #:place-window-relative-to
   #:set-native-window-background
   #:window-icon-supported-p
   #:set-window-icon
   #:set-window-icon-from-picture
   #:maximize-window
   #:minimize-window
   #:restore-window
   #:window-maximized-p
   #:window-render-suspended-p
   #:window-scale-changed
   #:acquire-gl-context
   #:release-gl-context
   #:call-with-gl-context
   #:register-gl-context-cleanup
   #:show-window
   #:hide-window
   #:close-window
   #:window-close-allowed-p
   #:window-visible-p
   #:window-bounds
   #:window-focused-p
   #:window-focus-root
   #:focused-window
   #:front-window
   #:focus-pane
   #:unfocus-pane
   #:strong-focus-pane
   #:repair-window-focus
   #:*hover-move-p*
   #:note-input-source
   #:keyboard-cues-p
   #:keyboard-cues-changed
   #:init-keyboard-cues
   #:note-keyboard-cue-event
   #:current-modal-window
   #:run-modal-dialog
   #:exit-modal
   #:abort-modal
   #:register-window-retirement

   ;; Input: modifiers, pointer, wheel.
   #:*shift-key-p*
   #:shift-key-p
   #:command-key-p
   #:option-key-p
   #:note-modifiers
   #:pointer-state
   #:pointer-capture
   #:clicked-element
   #:tooltip-hover-element
   #:cursor-location
   #:capture-pointer
   #:release-pointer-capture
   #:element-window
   #:dispatch-to-children
   #:find-ancestor-clip-view
   #:clear-hover
   #:*wheel-step*
   #:pane-editing-p
   #:element-at-location
   #:layout-owner
   #:install-magnify-handler

   ;; Lisp/desktop process and system services.
   #:run-shell-command
   #:pipe-exit-status
   #:call-system
   #:call-system-showing-output
   #:shell-command-form
   #:shell-command-options
   #:hidden-console-options
   #:*system-open-command*
   #:open-with-system
   #:run-application
   #:bring-process-to-front
   #:find-application-window
   #:compile-file-if-needed
   #:current-pathname
   #:directory-pathname-p
   #:directory-entries
   #:detect-cr-only-external-format
   #:variant-compiled-file-pathname
   #:compile-source-checked
   #:with-default-external-format
   #:open-url
   #:get-user-name
   #:user-home
   #:date-string

   ;; View structure.
   #:fixed-layout
   #:invalidate
   #:view
   #:view-background
   #:view-border
   #:view-border-width
   #:item-view
   #:tab-layout

   ;; Pane scrolling: state, engine, chrome bars, host policy generics.
   #:scroll-mixin
   #:scrollbars
   #:field-width
   #:field-height
   #:*scrollbar-track-px*
   #:scroll-active-p
   #:scroll-axis-v-p
   #:scroll-x
   #:scroll-y
   #:scroll-passive-p
   #:scroll-content-size
   #:scroll-view-size
   #:scroll-applied
   #:scrollbars-forced-p
   #:scroll-changed
   #:field-size
   #:scrollbar-axes
   #:scroll-viewport
   #:scroll-maxima
   #:set-scroll
   #:drop-scrollbars

   ;; View placement (Y-down over Alloy Y-up) and attach/detach.
   #:*size-constraint*
   #:constrain-size
   #:layout-attached-p
   #:set-element-position
   #:element-position
   #:set-element-size
   #:element-size
   #:place-element
   #:place
   #:add-element
   #:detach-focus-subtree

   ;; Flat pinboard realization and tab layout.
   #:enter-flat
   #:leave-flat
   #:current-page
   #:make-tab
   #:make-focus-list
   #:store-tab-style
   #:forget-tab-styles
   #:*tab-face*
   #:*tab-active-face*
   #:*tab-border*

   ;; Pane render pass: paint order, clip, scroll translate, drawing-pass state.
   #:render-contents
   #:draws-contents-p
   #:call-with-drawing-pass

   ;; Widget structure.
   #:dialog-item
   #:static-text
   #:text-view
   #:button
   #:scroller

   ;; Widget style protocol and looks: dialog-item base, static text, push button, chrome.
   #:*dialog-item-z-elevation*
   #:widget-background
   #:widget-foreground
   #:widget-font-entry
   #:widget-font
   #:widget-enabled-p
   #:widget-label
   #:widget-text
   #:widget-border
   #:widget-mnemonic-index
   #:widget-frame
   #:widget-frame-border
   #:label-drop
   #:apply-font-to-label-shape
   #:text-wrap-pix
   #:static-text-edge-bounds
   #:*button-face*
   #:*button-hover-face*
   #:*button-active-face*
   #:button-default-p
   #:button-cancel-p
   #:scroll-corner-visible-p
   #:scroll-grip-visible-p
   #:check-box
   #:radio-button
   #:slider

   ;; Indicators (check box, radio button) and slider: geometry, state, policy, colours.
   #:indicator-label-px
   #:indicator-label
   #:focus-on-click
   #:click-outside-indicator
   #:release-outside-indicator
   #:radio-may-uncheck-p
   #:indicator-activated
   #:radio-cluster-candidates
   #:uncheck-radio-cluster-siblings
   #:slider-increment
   #:slider-bevel-light

   ;; Choice widgets: lists and pop-up, selection, gestures, CAPI callback channel.
   #:*programmatic-set*
   #:with-programmatic-set
   #:test-function
   #:callback-argument
   #:list-changed
   #:notify-list-change
   #:list-label
   #:item-list
   #:single-item-list
   #:multi-item-list
   #:committed-index
   #:mark-list-children-for-render
   #:choice-focus-pane
   #:items
   #:set-items
   #:selected-index
   #:selected-indices
   #:set-selected-index
   #:set-selected-indices
   #:select-index
   #:unselect-index
   #:selected-item
   #:set-selected-item
   #:list-label-selected-p
   #:list-label-text-width
   #:combo-item
   #:pop-up-dialog-item
   #:popup-chevron-mark

   ;; Choice dropdown: the scrolled list a choice control drops on the popup chain.
   #:*choice-popup-max-visible-items*
   #:choice-popup-frame
   #:choice-popup-item
   #:choice-popup-rows
   #:choice-popup-row-height
   #:choice-popup-row-width
   #:choice-popup-visible
   #:choice-popup-top
   #:choice-popup-place-rows
   #:choice-popup-add-bar
   #:popup-open-choice-list

   ;; Filter strip state: three independent axes, the decision, the strip measures.
   #:*filter-bar-height*
   #:*filter-field-height*
   #:*filter-clear-width*
   #:*filter-matches-width*
   #:*filter-field-width*
   #:*filter-clear-color*
   #:*filter-clear-hover*
   #:*filter-text-color*
   #:filter-host
   #:filter-text
   #:filter-regexp-p
   #:filter-exclude-p
   #:filter-case-p
   #:filter-field
   #:filter-mode-menu
   #:filter-clear
   #:filter-matches
   #:filter-bar
   #:filter-apply
   #:filter-window
   #:filter-mode-place
   #:filter-pass-p
   #:filter-mode-label
   #:*filter-mode-items*
   #:filter-axis-on-p
   #:filter-chord-axis

   ;; Grid: cells, selection, keyboard navigation, host policy seams.
   #:grid-view
   #:grid-cell
   #:grid-row-labels
   #:grid-column-labels
   #:grid-selected-row
   #:grid-row-map
   #:grid-cells
   #:grid-cell-row
   #:grid-focus-root
   #:grid-header-activated
   #:grid-edit-cell
   #:grid-clear-cells
   #:grid-build-cells
   #:grid-select-cell
   #:grid-order-before-p

   ;; Menu structure.
   #:menu-object
   #:menu
   #:menu-item
   #:menu-component
   #:add-menu-items
   #:remove-menu-items
   #:find-menu-item
   #:menu-item-at
   #:set-window-menu-items 
   #:popup-window #:make-popup-window 

   ;; Menu engine: neutral model, menu bar, popup chains, accelerators, host seams.
   #:menu-entry-title
   #:menu-entry-items
   #:menu-entry-action
   #:menu-entry-accelerator
   #:menu-entry-enabled
   #:menu-entry-selected
   #:set-menu-entry-enabled
   #:popup-repair-focus
   #:popup-focus-pane
   #:window-menubar
   #:*popup-menu-item-height*
   #:*popup-menu-border-width*
   #:popup-consume-opener-suppression-p
   #:popup-resolve-focus-loss
   #:popup-close-stack
   #:popup-normalize-entries
   #:popup-fit-screen-rect
   #:popup-owner-point-to-screen
   #:popup-drop-anchor
   #:popup-attach-surface
   #:popup-present-frame
   #:popup-open-menu-at
   #:open-popup-menu

   ;; macOS native menu bar (NSMenu), built from the same menu model.
   #:macos-install-window-menu

   ;; Alloy-editor-backed text structure.
   #:text-edit-view

   ;; Caret blink and text selection.
   #:reset-caret-blink
   #:tick-caret-blink
   #:caret-hidden-p
   #:window-selected-text-pane
   #:selection-survives-blur-p
   #:click-clears-selection-p
   #:selection-hidden-p
   #:release-text-selection

   ;; Generic Lisp desktop structure.
   #:find-definitions

   ;; Graphics structure and protocol.
   #:screen-port
   #:*current-port*
   #:port-draw-text
   #:port-draw-line
   #:port-draw-rect
   #:port-fill-rect
   #:port-draw-ellipse
   #:port-draw-ellipse-arc
   #:port-draw-polygon

   ;; Graphics-port engine.
   #:*port-transform*
   #:polygon-vertices
   #:transform-xy
   #:call-with-transform
   #:call-with-composite-mode
   #:call-with-mask
   #:image-paint
   #:call-with-pattern-repeat
   #:call-with-shape-mode
   #:call-with-pattern-clip-scope
   #:render-filled-polygon
   #:stroke-polyline
   #:transform-scale

   ;; Images: decode, texture, table, draw, raster, offscreen record.
   #:picture
   #:picture-p
   #:picture-image
   #:picture-width
   #:picture-height
   #:load-picture
   #:make-rgba-picture
   #:ensure-texture
   #:find-picture
   #:store-picture
   #:loaded-pictures
   #:kill-picture
   #:port-draw-image
   #:save-picture
   #:rasterize-picture
   #:begin-record
   #:end-record
   #:metafile-port
   #:call-with-recorded-picture

   ;; Drawing pass state and primitives.
   #:*current-renderer*
   #:*current-fg-color*
   #:*current-bg-color*
   #:*current-pen-size*
   #:*current-line-style*
   #:*current-dash-pattern*
   #:*current-view-height*
   #:*pox*
   #:*poy*
   #:call-with-clip
   #:dash-line-segments
   #:draw-line-segments
   #:draw-point
   #:normalize-rectangle
   #:fill-rectangles
   #:fill-rectangle
   #:draw-round-rect
   #:fill-round-rect
   #:fill-polygon
   #:fill-triangle-strip

   ;; Display scale.
   #:typography-dpi
   #:framebuffer-ratio
   #:apply-window-content-scale
   #:note-content-scale
   #:window-content-scale

   ;; Font sources and native metrics.
   #:*baked-metrics-names*
   #:pen-advance
   #:line-advance

   ;; Text measurement.
   #:string-advance
   #:ascender-px

   ;; Text rendering.

   ;; The host application.
   #:*application-name*

   ;; Font atlas registry, per-renderer font cache, native font roles.
   #:*font-atlases*
   #:*bundled-font-directory*
   #:*fallback-families*
   #:*native-role-fallback*
   #:*default-font-role*
   #:find-font-source
   #:make-font-entry
   #:font-entry-font
   #:font-entry-size-unit
   #:cached-font-entry
   #:request-font-variant
   #:resolve-font
   #:native-role
   #:native-role-family
   #:native-role-points
   #:native-role-weight
   #:native-role-slant
   #:native-role-host-font
   #:invalidate-native-fonts
   #:refresh-native-fonts
   #:role-font-entry

   ;; Desktop services.
   #:drag-view
   #:drop-view
   #:drop-object
   #:drop-object-pane
   #:drop-object-pane-x
   #:drop-object-pane-y
   #:drop-object-proposed-effect
   #:drop-object-origin
   #:drop-object-drop-effect
   #:drop-object-allows-drop-effect-p
   #:negotiate-drop-effect
   #:set-drop-object-supported-formats
   #:drop-object-provides-format
   #:drop-object-get-object
   #:*tooltip-max-width-px*
   #:close-active-tooltip
   #:open-tooltip
   #:transient-drawing-view
   #:default-clipboard-service
   #:clipboard-read-text
   #:clipboard-write-text
   #:default-timer-service
   #:start-timer
   #:load-cursor-image
   #:take-drag-cursor
   #:*drag-source*
   #:*drag-active-p*
   #:*drag-drop-object*
   #:drag-target-at
   #:drag-candidate-windows
   #:drag-cursor
   #:drag-enter
   #:drag-leave
   #:drag-leave-final
   #:drag-over
   #:drag-effect
   #:drag-commit
   #:drag-cleanup
   #:drag-move-epilogue
   #:drag-up-epilogue
   #:drag-involves-window-p

   ;; Native dialogs and printing.
   #:file-dialog-service
   #:color-dialog-service
   #:font-dialog-service
   #:choose-directory
   #:choose-new-directory
   #:choose-color
   #:choose-font
   #:types->filter
   #:as-directory-pathname
   #:dialog-title
   #:file-filter-name-for
   #:normalize-file-filters
   #:full-file-pathname
   #:check-file-selection
   #:*last-directory*
   #:directory-to-remember
   #:run-file-dialog
   #:prompt-host
   #:prompt-measure-width
   #:prompt-line-height
   #:prompt-wrapped-rows
   #:prompt-make-window
   #:prompt-make-static-text
   #:prompt-make-editable-text
   #:prompt-make-button
   #:prompt-add-items
   #:prompt-run-modal
   #:prompt-item-text
   #:prompt-exit-modal
   #:message-dialog
   #:yes-or-no-dialog
   #:yes-no-cancel-dialog
   #:prompt-for-string
   #:system-beep

   ;; Progress window.
   #:make-progress-surface

   ;; Printing.
   #:printing-service
   #:activate-print-window
   #:choose-print-output-file
   #:note-printing-window
   #:logical-screen-dpi
   #:start-print-task
   #:close-printer-settings
   #:page-size
   #:print-page-scale
   #:page-setup
   #:opaque-raster-page
   #:capture-raster-page
   #:run-print-job
   #:print-one-page
   #:print-document
   #:printer-port
   #:call-with-printer-port
   #:register-private-fonts

   ;; Native backend abstraction.
   #:with-autorelease-pool
   ))

