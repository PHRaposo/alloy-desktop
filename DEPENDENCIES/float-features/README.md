## About Float-Features
This is a wrapper library for IEEE floating point features not present in the Common Lisp standard.

## Implementation Support
The following implementations are currently partially or entirely supported:

* abcl
* allegro
* ccl
* clasp
* cmucl
* ecl
* mezzano
* mkcl
* sbcl
* lispworks

## Features
The system will also push the following features if appropriate:

- `short-floats-are-single-floats`
- `long-floats-are-double-floats`
- `XX-bit-short-floats` where XX is the number of bits of the representation.
- `XX-bit-single-floats` where XX is the number of bits of the representation.
- `XX-bit-double-floats` where XX is the number of bits of the representation.
- `XX-bit-longe-floats` where XX is the number of bits of the representation.
