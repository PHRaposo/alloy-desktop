(in-package #:org.shirakumo.bmp)

(bs:define-io-structure rgb-mask
  (r uint32)
  (g uint32)
  (b uint32))

(bs:define-io-structure rgba-mask
  (:include rgb-mask)
  (a uint32))

(bs:define-io-structure xyz
  (x sint32)             ; FXPT2DOT30, 2 bits int, 30 bits fractional.
  (y sint32)
  (z sint32))

(bs:define-io-structure bitmapcoreheader
  (width uint16)
  (height uint16)
  (planes uint16)
  (bits/pixel uint16))

(defmethod print-object ((header bitmapcoreheader) stream)
  (print-unreadable-object (header stream :type T)
    (format stream "~ax~a ~db/p"
            (width header)
            (height header)
            (bits/pixel header))))

(bs:define-io-alias bitmapcompression
    (case uint32
      (0 :rgb)
      (1 :rle8)
      (2 :rle4)
      (3 :bitfields)
      (4 :jpeg)
      (5 :png)
      (6 :alpha-bitfields)
      (11 :cmyk)
      (12 :cmyk-rle8)
      (13 :cmyk-rle4)))

(bs:define-io-structure os22xbitmapheader/short
  (width uint32)
  (height uint32)
  (planes uint16)
  (bits/pixel uint16))

(bs:define-io-structure bitmapinfoheader
  (width uint32)
  (height sint32)
  (planes uint16)
  (bits/pixel uint16)
  (compression bitmapcompression)
  (image-size uint32)
  (horizontal-resolution sint32)
  (vertical-resolution sint32)
  (palette-size uint32)
  (important-color-count uint32))

(bs:define-io-structure bitmapv2infoheader
  (:include bitmapinfoheader)
  (mask rgb-mask))

(bs:define-io-structure bitmapv3infoheader
  (:include bitmapinfoheader)
  (mask rgba-mask))

(bs:define-io-structure bitmapv4infoheader
  (:include bitmapv3infoheader)
  (cs-type uint32)
  (red-endpoint xyz)
  (green-endpoint xyz)
  (blue-endpoint xyz)
  (gamma rgb-mask))

(bs:define-io-structure bitmapv5infoheader
  (:include bitmapv4infoheader)
  (intent uint32)
  (profile-offset uint32)
  (profile-size uint32)
  uint32)

(bs:define-io-alias halftoning-algorithm
    (case uint16
      (0 NIL)
      (1 :error-diffusion)
      (2 :panda)
      (3 :super-circle)))

(bs:define-io-structure os22xbitmapheader
  (:include bitmapinfoheader)
  (resolution-unit uint16)
  uint16
  (origin uint16)
  (halftoning halftoning-algorithm)
  (halftoning-parameter-1 sint32)
  (halftoning-parameter-2 sint32)
  (color-encoding uint32)
  (identifier uint32))

(defun %bmp-palette-read-size (header)
  (let ((bits/pixel (bits/pixel header))
        (palette-size (bitmapinfoheader-palette-size header)))
    (* 4 (if (and (zerop palette-size) (<= bits/pixel 8))
             (expt 2 bits/pixel)
             palette-size))))

(defun %bmp-palette-size (header)
  (let ((bits/pixel (bits/pixel header)))
    (if (<= bits/pixel 8)
        (* 4 (expt 2 bits/pixel))
        (%bmp-palette-read-size header))))

(defun %bmp-image-size (header)
  (flet ((uncompressed-size ()
           (* 4
              (ceiling (* (width header)
                          (bits/pixel header))
                       32)
              (abs (height header)))))
    (typecase header
      (bitmapinfoheader
       (let ((image-size (bitmapinfoheader-image-size header)))
         (if (and (zerop image-size)
                  (eql :rgb (compression header)))
             (uncompressed-size)
             image-size)))
      ((or bitmapcoreheader os22xbitmapheader/short)
       (uncompressed-size)))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defclass padded-octet-vector (bs:io-type)
    ((read-size :initarg :read-size :accessor read-size)
     (size :initarg :size :accessor size)))

  (defmethod bs:lisp-type ((type padded-octet-vector))
    '(array (unsigned-byte 8) (*)))

  (defmethod bs:default-value ((type padded-octet-vector))
    (declare (ignore type))
    '(make-array 0 :element-type '(unsigned-byte 8)))

  (defmethod bs:octet-size ((type padded-octet-vector))
    (declare (ignore type))
    '*)

  (defmethod org.shirakumo.binary-structures::octet-size-form
      ((type padded-octet-vector) value-variable)
    (declare (ignore value-variable))
    (read-size type))

  (defmethod bs:initargs append ((type padded-octet-vector))
    (list :read-size (read-size type)
          :size (size type)))

  (defmethod bs:read-form (backend (type padded-octet-vector))
    (let ((raw (make-instance 'bs:io-vector
                              :element-type 'uint8
                              :element-count (read-size type))))
      `(let* ((data ,(bs:read-form backend raw))
              (size ,(size type)))
         (if (< (length data) size)
             (let ((padded (make-array size
                                       :element-type '(unsigned-byte 8)
                                       :initial-element 0)))
               (replace padded data)
               padded)
             data))))

  (defmethod bs:write-form (backend (type padded-octet-vector) value-variable)
    (let ((raw (make-instance 'bs:io-vector
                              :element-type 'uint8
                              :element-count (read-size type))))
      `(let* ((size ,(read-size type))
              (data (if (= size (length ,value-variable))
                        ,value-variable
                        (subseq ,value-variable 0 (min size (length ,value-variable))))))
         ,(bs:write-form backend raw 'data))))

  (bs:define-io-type-parser padded-octet-vector (read-size size)
    (make-instance 'padded-octet-vector :read-size read-size :size size)))

(bs:define-io-structure bmp
  (type (case (string 2) ("BM" :BM) ("BA" :BA) ("CI" :CI) ("CP" :CP) ("IC" :IC) ("PT" :PT)))
  (size uint32)
  uint16 uint16
  (bitmap-offset uint32)
  (header (case uint32
            (124 bitmapv5infoheader)
            (108 bitmapv4infoheader)
            (64 os22xbitmapheader)
            (56 bitmapv3infoheader)
            (52 bitmapv2infoheader)
            (40 bitmapinfoheader)
            (16 os22xbitmapheader/short)
            (12 bitmapcoreheader)))
  (bit-masks (typecase (bs:slot header)
               (bitmapinfoheader
                (typecase (bs:slot header compression)
                  ((eql :bitfields) rgb-mask)
                  ((eql :alpha-bitfields) rgba-mask)))))
  (colors (typecase (bs:slot header)
            (bitmapinfoheader
             (padded-octet-vector (%bmp-palette-read-size (bs:slot header))
                                  (%bmp-palette-size (bs:slot header))))
            (bitmapcoreheader
             (vector uint8 (* 3 (expt 2 (bs:slot header bits/pixel)))))
            (os22xbitmapheader/short
             (vector uint8 (* 3 (expt 2 (bs:slot header bits/pixel)))))
            (T NIL)))
  (pixels (vector uint8 (%bmp-image-size (bs:slot header)))
          :offset (bs:slot bitmap-offset))
  #++ ;; FIXME: This does NOT work as the offset is emitted BEFORE the typecase.
  (color-profile (typecase (bs:slot header)
                   (bitmapv5infoheader
                    (vector uint8 (bs:slot header profile-size))))
                 :offset (bs:slot header profile-offset)))

(defmethod print-object ((bmp bmp) stream)
  (print-unreadable-object (bmp stream :type T)
    (let ((header (slot-value bmp 'header)))
      (format stream "~ax~a ~db/p"
              (width header)
              (height header)
              (bits/pixel header)))))

(bs:define-io-structure ico-entry
  (width uint8)
  (height uint8)
  (palette-size uint8)
  uint8
  (property-1 uint16)
  (property-2 uint16)
  (octet-size uint32)
  (offset uint32))

(bs:define-io-structure bmpcontent
  (header (case uint32
            (124 bitmapv5infoheader)
            (108 bitmapv4infoheader)
            (64 os22xbitmapheader)
            (56 bitmapv3infoheader)
            (52 bitmapv2infoheader)
            (40 bitmapinfoheader)
            (16 os22xbitmapheader/short)
            (12 bitmapcoreheader)))
  (bit-masks (typecase (bs:slot header)
               (bitmapinfoheader
                (typecase (bs:slot header compression)
                  ((eql :bitfields) rgb-mask)
                  ((eql :alpha-bitfields) rgba-mask)))))
  (colors (typecase (bs:slot header)
            (bitmapinfoheader
             (padded-octet-vector (%bmp-palette-read-size (bs:slot header))
                                  (%bmp-palette-size (bs:slot header))))
            (bitmapcoreheader
             (vector uint8 (* 3 (expt 2 (bs:slot header bits/pixel)))))
            (os22xbitmapheader/short
             (vector uint8 (* 3 (expt 2 (bs:slot header bits/pixel)))))
            (T NIL)))
  (pixels (vector uint8 (%bmp-image-size (bs:slot header)))))

(defmethod print-object ((bmp bmpcontent) stream)
  (print-unreadable-object (bmp stream :type T)
    (let ((header (slot-value bmp 'header)))
      (format stream "~ax~a ~db/p"
              (width header)
              (height header)
              (bits/pixel header)))))

(bs:define-io-structure ico
  #(0 0)
  (type (case uint16
          (1 :ico)
          (2 :cur)))
  (count uint16)
  (entries (vector ico-entry (bs:slot count)))
  (images (vector bmpcontent (bs:slot count) (bs:slot (aref (bs:slot entries) bs:i) offset))))

(defmethod print-object ((ico ico) stream)
  (print-unreadable-object (ico stream :type T)
    (format stream "~a (~{~{~ax~a~}~^, ~})" (ico-type ico)
            (loop for entry across (ico-entries ico)
                  collect (list (ico-entry-width entry) (ico-entry-height entry))))))
