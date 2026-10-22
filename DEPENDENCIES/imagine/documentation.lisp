(in-package #:org.shirakumo.fraf.imagine)

;; conditions.lisp
(docs:define-docs
  (type imagine-error
    "Supertype for all errors in this library.")

  (type invalid-view
    "Error signalled when a view designates an area that is outside of the image.

See IMAGINE-ERROR
See VIEW")

  (function view
    "Returns the related view.

See INVALID-VIEW")

  (type pixel-data-incompatible
    "Error signalled when the pixel data of an image is in an incompatible format.

The SOURCE is always an IMAGE. The TARGET may be an IMAGE or a spec
for compatible image formats.

See SOURCE
See TARGET")

  (function source
    "Returns the related source image.

See PIXEL-DATA-INCOMPATIBLE
See UNSUPPORTED-FORMAT")

  (function target
    "Returns the related target image.

See PIXEL-DATA-INCOMPATIBLE")

  (type unsupported-format
    "Error signalled when the requested image format is unsupported.

See SOURCE
See FORMAT-TYPE
See SUPPORTED-FORMATS")

  (function format-type
    "Returns the requested format type that is unavailable.

See UNSUPPORTED-FORMAT")

  (function supported-formats
    "Returns a list of the supported format types.

See UNSUPPORTED-FORMAT"))

;; protocol.lisp
(docs:define-docs
  (type layout
    "Type for valid layout indicators.

Can be one of :R :RA :RGB :BGR :RGBA :BGRA :ARGB :ABGR")

  (type origin
    "Type for valid origin indicators.

Can be one of :TOP-LEFT :TOP-RIGHT :BOTTOM-LEFT :BOTTOM-RIGHT")

  (type channel-type
    "Type for valid channel-type indicators.

Can be one of
 :UNSIGNED-BYTE :UNSIGNED-SHORT :UNSIGNED-INT :UNSIGNED-LONG
 :SIGNED-BYTE :SIGNED-SHORT :SIGNED-INT :SIGNED-LONG
 :HALF-FLOAT :FLOAT :DOUBLE
or a specific channel type as a keyword, defined by an extension to
Imagine.")

  (type dimension
    "Type for the dimension of an image.

Equivalent to (UNSIGNED-BYTE 32)")

  (type stride
    "Type for the stride between elements in an image.

Equivalent to (UNSIGNED-BYTE 32)")

  (function load-image
    "Load an image from the backing storage.

The file format type may be specified as T, in which case the type is
inferred from the source pathname name, if any. If the file format
type is not recognised or supported, an error of type
UNSUPPORTED-FORMAT is signalled. If the operation succeeds, either an
IMAGE instance is returned, or a list of IMAGE instances if multiple
disconnected images are contained in the file.

Depending on the format, additional keyword arguments may be supported
to direct selection of the image or its properties in the decoded
format. All formats must support the keyword DECODE, which is T by
default. If NIL, then the returned IMAGE's DATA field may be NIL, but
the metadata entries such as the dimensions of the image must be
filled in.

See IMAGE (type)
See UNSUPPORTED-FORMAT (type)
See SAVE-IMAGE")

  (function save-image
    "Save an image to the backing storage.

The file format type may be specified as T, in which case the type is
inferred from the source pathname name, if any. If the file format
type is not recognised or supported, an error of type
UNSUPPORTED-FORMAT is signalled. If the IMAGE's pixel data is not in a
suitable format for the file format, an error of type
PIXEL-DATA-INCOMPATIBLE is signalled and a restart called ADJUST will
be available to adjust the image pixel destructively to match the
closest suitable format for the file format.

Depending on the format, additional keyword arguments may be supported
to direct the properties in the encoded format.

See IMAGE (type)
See UNSUPPORTED-FORMAT (type)
See PIXEL-DATA-INCOMPATIBLE (type)
See LOAD-IMAGE")

  (function transfer
    "Transfer pixels between two images or views.

The behaviour is undefined if the source and destination are the same
image or views to the same image and the view regions overlap.

An error of type INVALID-VIEW is signalled if either the source or
target are a VIEW that is invalid.

See IMAGE (type)
See VIEW (type)
See INVALID-VIEW (type)")

  (function adjust
    "Adjust the pixel data storage for the given image.

This will destructively modify the given image and return it. The DATA
in the image will be replaced if necessary. The image will not be
changed if all of the requested attributes already match those of the
image.

If any of W, H, D are specified the image will be resized using
RESIZE, meaning the storage is extended while keeping the original
image anchored towards the 0 point. If you want to scale the image
instead, use SCALE.

If a different LAYOUT is requested, then the pixel colours will be
converted on a \"best effort\" basis. For the case of gray to rgb, the
gray value is simply repeated to all channels. For the case of rgb to
gray, the colour's approximate sRGB luminance value is used as the
gray point. For the case of a new alpha channel, the channel is set to
opaque (1). For the case of a removed alpha channel, it is simply
discarded.

If a different CHANNEL-TYPE is requested, the image colour channels
are converted to the requested storage type on a \"best effort\"
basis. Naturally conversion to a different storage type (such as
floats) or a lower bittage (such as int to short) will potentially
lose colour depth.

If a different ORIGIN is requested, the image's origin is adjusted
such that the image will still be displayed the same way after the
origin change (meaning the data is mirrored as required to achieve the
change of coordinate system).

See IMAGE (type)
See LAYOUT (type)
See ORIGIN (type)
See RESIZE")

  (function pixel-stride
    "Returns the number of octets in stride for the given thing.

THING can be an IMAGE, a LAYOUT, or a CHANNEL-TYPE. In case of a
IMAGE, it returns the stride between pixels. In case of a LAYOUT, it
returns the number of channels, and in case of a CHANNEL-TYPE the
number of octets for that channel-type.

See ROW-STRIDE
See LAYER-STRIDE
See IMAGE (type)
See LAYOUT (type)")

  (function row-stride
    "Returns the number of octets in stride for a whole row of pixels.

This is the PIXEL-STRIDE multiplied by the W of the image.

See IMAGE (type)
See PIXEL-STRIDE
See W")

  (function layer-stride
    "Returns the number of octets in stride for a whole layer of pixels.

This is the ROW-STRIDE multiplied by the H of the image.

See IMAGE (type)
See ROW-STRIDE
See H")

  (function data
    "Returns the backing storage of packed pixel data for the image.

The backing storage is \"opaque\" in the sense that it can be NIL if
the image is invalid, a (SIMPLE-ARRAY (UNSIGNED-BYTE 8) (*)), or
another data type if an extension to Imagine provides it, such as a
foreign pointer or something like that.

In order to access data transparently, you should use WITH-PIXEL-DATA
or WITH-IMAGE-PIXELS. Alternatively you will need to write bespoke
handling for the data storage types that you are interested in. What
is true for all storage types is that they must provide constant time
random access to an arbitrary index within it, addressable to octet
boundaries. The storage must also guarantee access to at least up to
and excluding the index at (* W H D PIXEL-STRIDE) of the image. Access
beyond that range however results in undefined behaviour.

See IMAGE (type)
See WITH-PIXEL-DATA
See WITH-IMAGE-PIXELS
See PIXEL-STRIDE")

  (function channel-type
    "Returns the channel-type of pixel data in the image.

See IMAGE (type)
See CHANNEL-TYPE (type)
See PIXEL-STRIDE
See DATA")

  (function layout
    "Returns the channel layout of pixel data in the image.

See IMAGE (type)
See LAYOUT (type)
See PIXEL-STRIDE
See DATA")

  (function origin
    "Returns the image's origin placement.

See IMAGE (type)
See ORIGIN (type)")

  (function channel-reader
    "Returns a function to read a pixel channel's value.

The function accepts two arguments: the backing data storage and the
*octet* index in that data storage at which to read the channel. The
returned value is a REAL number.

Note that the returned function is only valid to be called for indices
that are valid for the backing data storage array (see DATA). Passing
any other data object to the function as was passed to CHANNEL-READER,
or passing any index outside the specified range will lead to
undefined behaviour and potentially data corruption.

See DATA
See PIXEL-READER
See CHANNEL-TYPE (type)")

  (function channel-writer
    "Returns a function to read a pixel channel's value.

The function accepts two arguments: the backing data storage and the
*octet* index in that data storage at which to read the channel. The
returned value is a REAL number.

Note that the returned function is only valid to be called for indices
that are valid for the backing data storage array (see DATA). Passing
any other data object to the function as was passed to CHANNEL-READER,
or passing any index outside the specified range will lead to
undefined behaviour and potentially data corruption.

See DATA
See PIXEL-WRITER
See CHANNEL-TYPE (type)")

  (function pixel-reader
    "Returns a function to read a standardised pixel.

The function accepts three arguments: a function of one argument to
read a pixel channel's value at the passed index, the index at which
the pixel starts, and the stride between channels.

Returns four values: the R, G, B, and A of the pixel, each as a REAL
number as by CHANNEL-READER.

Note that the returned function is only valid to be called for indices
that are valid for the backing data storage array (see DATA). Passing
any other data object to the function as was passed to CHANNEL-READER,
or passing any index outside the specified range will lead to
undefined behaviour and potentially data corruption.

See DATA
See CHANNEL-READER
See PIXEL-WRITER
See LAYOUT (type)")

  (function pixel-writer
    "Returns a function to write a standardised pixel.

The function accepts seves arguments: a function of two arguments to
write a pixel channel's value at the passed index, the index at which
the pixel starts, the stride between channels, and the R, G, B, and A
channels of the pixel. The writer will reinterpret the values to match
the layout as necessary.

Note that the returned function is only valid to be called for indices
that are valid for the backing data storage array (see DATA). Passing
any other data object to the function as was passed to CHANNEL-READER,
or passing any index outside the specified range will lead to
undefined behaviour and potentially data corruption.

See DATA
See CHANNEL-WRITER
See PIXEL-READER
See LAYOUT (type)")

  (function w
    "Returns the width of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function h
    "Returns the height of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function d
    "Returns the depth of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function x
    "Returns the X offset of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function y
    "Returns the Y offset of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function z
    "Returns the Z offset of the view area in pixels.

See IMAGE (type)
See VIEW (type)")

  (function with-pixel-data
    "Convenience to access pixel data in a standardised way.

ACCESSOR will be FBOUND to an accessor that accepts one argument, the
index at which to read a single channel of pixel data from the
PIXEL-DATA backing storage, using the specified CHANNEL-TYPE to decode
the data. The accessor is dynamic-extent within BODY, and *must not*
be leaked outside.

The accessor has restrictions placed on its valid access patterns. See
DATA and PIXEL-READER.

See DATA
See PIXEL-READER
See PIXEL-WRITER
See CHANNEL-TYPE (type)")

  (function with-image-pixels
    "Convenience to access pixel data of an image.

See IMAGE (type)
See WITH-PIXEL-DATA")

  (function with-image-pixels*
    "Convenience to access pixel data of images.

See IMAGE (type)
See WITH-IMAGE-PIXELS*
See WITH-PIXEL-DATA")

  (function with-view
    "Convenience to access pixel data in a view.

ACCESSOR will be FBOUND to an accessor that accepts one argument, the
index at which to read a single channel of pixel data from the
PIXEL-DATA backing storage, using the image's CHANNEL-TYPE to decode
the data. The accessor is dynamic-extent within BODY, and *must not*
be leaked outside.

The accessor has restrictions placed on its valid access patterns. See
DATA and PIXEL-READER.

See DATA
See PIXEL-READER
See PIXEL-WRITER
See WITH-PIXELS
See CHANNEL-TYPE (type)")

  (function image-compatible-p
    "Returns true if the image's pixel data is compatible with the given set of layouts and channel types.

LAYOUTS and CHANNEL-TYPES should be lists of acceptable layout and
channel-type indicators.

See IMAGE (type)
See LAYOUT (type)
See CHANNEL-TYPE (type)
See ORIGIN (type)")

  (function check-image-compatible
    "Check if the image's pixel data is compatible and signal an error otherwise.

If an error is signalled, a restart named ADJUST is available, which
will call ADJUST on the image to modify it to the closest compatible
pixel format.

See IMAGE-COMPATIBLE-P
See PIXEL-DATA-INCOMPATIBLE (type)
See ADJUST")

  (function make-image
    "Create a new image and return it.

See MAKE-IMAGE*
See IMAGE (type)
See DATA
See CHANNEL-TYPE (type)
See LAYOUT (type)
See ORIGIN (type)
See W
See H
See D")

  (function copy-image
    "Copy the image and return it.

This will *not* create a deep copy of the backing DATA.
Both the original and the copy will point to the same DATA storage.

See MAKE-IMAGE
See IMAGE (type)")

  (type image
    "Representation of an image.

An image is a raw, uncompressed pixel storage combined with the
metadata necessary to interpret those pixel contents in the intended
way. Each image is composed of one or more layers, which is composed
of one or more rows, which is composed of one or more pixels, which is
composed of one or more channels.

The number of channels (and their order and purpose) per pixel is
indicated by the LAYOUT, the storage for each channel by the
CHANNEL-TYPE, the number of pixels in a row by the Width, number of
rows per layer by the Height, and the number of layers by the Depth.

Where the zero point is located and in which direction the image
\"grows\" is indicated by the ORIGIN. Layers are always stacked
\"behind\", meaning layer 0 is on top in front of layer 1 and so on.

The image's pixel data is stored in an opaque backing storage, which
may or may not be an octet vector. The only restriction is that the
storage is addressable via functions returned by CHANNEL-READER and
CHANNEL-WRITER.

See W
See H
See D
See CHANNEL-TYPE
See LAYOUT
See ORIGIN
See DATA
See MAKE-IMAGE
See CHANNEL-READER
See CHANNEL-WRITER
See PIXEL-STRIDE
See WITH-IMAGE-PIXELS
See ADJUST
See LOAD-IMAGE
See SAVE-IMAGE
See MIRROR
See ROTATE
See RESIZE
See SCALE")

  (function image-data
    "Access the image's data directly.

See DATA
See IMAGE (type)")

  (function image-channel-type
    "Access the image's channel-type directly.

See CHANNEL-TYPE
See IMAGE (type)")

  (function image-layout
    "Access the image's layout directly.

See LAYOUT
See IMAGE (type)")

  (function image-origin
    "Access the image's origin directly.

See ORIGIN
See IMAGE (type)")

  (function image-w
    "Access the image's width directly.

See W
See IMAGE (type)")

  (function image-h
    "Access the image's height directly.

See H
See IMAGE (type)")

  (function image-d
    "Access the image's depth directly.

See D
See IMAGE (type)")

  (function make-image*
    "Shorthand to create an image.

See MAKE-IMAGE
See IMAGE (type)")

  (function make-view
    "Create a new view on an image.

See VIEW (type)
See IMAGE (type)
See X
See Y
See Z
See W
See H
See D")

  (function copy-view
    "Create a copy of the view.

See VIEW (type)")

  (type view
    "Representation of a view into an image.

A view is a sub-range of the image data and provides transparent
access into that data. Views let you transfer data between image
regions.

See IMAGE (type)
See X
See Y
See Z
See W
See H
See D
See WITH-VIEW
See TRANSFER
See SUPERFLUOUS-VIEW-P
see VALID-VIEW-P
See CHECK-VIEW")

  (function view-image
    "Access the view's backing image.

See IMAGE (type)
See VIEW (type)
See IMAGE")

  (function view-x
    "Access the view's X coordinate.

See VIEW (type)
See X")

  (function view-y
    "Access the view's Y coordinate.

See VIEW (type)
See Y")

  (function view-z
    "Access the view's Z coordinate.

See VIEW (type)
See Z")

  (function view-w
    "Access the view's width.

See VIEW (type)
See W")

  (function view-h
    "Access the view's height.

See VIEW (type)
See H")

  (function view-d
    "Access the view's depth.

See VIEW (type)
See D")

  (function superfluous-view-p
    "Returns true if the view is superfluous (equivalent to the whole image).

See VIEW (type)")

  (function valid-view-p
    "Returns true if the view is valid (is contained within the image).

See VIEW (type)")

  (function check-view
    "Checks if the view is valid and signals an error otherwise.

See VALID-VIEW-P
See VIEW (type)
See INVALID-VIEW (type)")

  (function ensure-image
    "Turns the given thing into an IMAGE if possible.

See IMAGE (type)
See VIEW (type)
See LOAD-IMAGE"))

;; ops.lisp
(docs:define-docs
  (function mirror
    "Mirror's the image's pixels destructively.

The direction can be either :VERTICALLY or :HORIZONTALLY.

See IMAGE (type)")

  (function rotate
    "Rotates the image destructively.

The amount can be either 90, -90 or 270, or 180.
In the case of 90 degree rotations, the image's W and H will be
swapped.

See IMAGE (type)")

  (function resize
    "Resizes the image destructively.

The image bounds are extended with \"empty\" pixels and the existing
pixels will be bound as per GRAVITY, which can either be a keyword or
a list of keywords separate for each dimension. The keywords can be
either:

  :ZERO     --- Stick to the origin edge in this dimension
  :CENTER   --- Center pixels in this dimension
  :OPPOSITE --- Stick to the opposing edge in this dimension

See IMAGE (type)
See ADJUST")

  (function scale
    "Scales the image destructively.

The image is scaled using the given interpolation argument. By default
only :LINEAR and :NEAREST are supported.

Users may extend the available interpolation algorithms by defining
methods on SCALE-IMAGE.

See IMAGE (type)
See SCALE-IMAGE")

  (function scale-image
    "Scales the image destructively.

Users may define methods on this function to define additional
interpolation algorithms. By default only :LINEAR and :NEAREST are
supported.

See SCALE"))
