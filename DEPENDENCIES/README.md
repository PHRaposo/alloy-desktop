# alloy-desktop dependencies

The Common Lisp libraries alloy-desktop depends on, one folder per project.

## Direct dependencies

Named in `alloy-desktop.asd` and `alloy-editor/alloy-editor.asd`.

| Library | Description | Author | License |
|---|---|---|---|
| [3b-bmfont](https://github.com/3b/3b-bmfont) | BMFont file format readers and writers | Bart Botta | MIT |
| [3d-math](https://shinmera.com/docs/3d-math/) | Linear algebra for 2D and 3D computations | Yukari Hafner | zlib |
| [alloy](https://shirakumo.org/project/alloy) | User interface toolkit (`alloy`, `alloy-glfw`, `alloy-simple-presentations`) | Yukari Hafner | zlib |
| [babel](https://github.com/cl-babel/babel) | Charset conversion | Luis Oliveira | MIT |
| [bordeaux-threads](https://github.com/sionescu/bordeaux-threads) | Portable multi-threading | Stelian Ionescu | MIT |
| [cffi](https://github.com/cffi/cffi) | Common Foreign Function Interface | James Bielman; maintained by Luis Oliveira | MIT |
| [cl-ppcre](https://github.com/edicl/cl-ppcre) | Perl-compatible regular expressions | Edi Weitz | BSD |
| [color-select](https://codeberg.org/PHRaposo/color-select) | Native colour selection dialog | PHRaposo | MIT |
| [colored](https://shinmera.com/docs/colored) | Colour representation, conversion and operations | Yukari Hafner | zlib |
| [com-on](https://shinmera.com/docs/com-on/) | Utilities for COM interfaces | Yukari Hafner | zlib |
| [file-select](https://shinmera.com/docs/file-select/) | Native file selection dialogs | Yukari Hafner | zlib |
| [font-select](https://codeberg.org/PHRaposo/font-select) | Native font selection dialogs | PHRaposo | MIT |
| [imagine](https://shirakumo.org/docs/imagine/) | Image decoding and manipulation (`imagine/formats`) | Yukari Hafner | zlib |
| [os-fonts](https://codeberg.org/PHRaposo/os-fonts) | Native operating-system UI font roles | PHRaposo | MIT |
| [paper-print](https://codeberg.org/PHRaposo/paper-print) | Native paper printing of raster pages | PHRaposo | MIT |
| [swank](https://github.com/slime/slime) | Lisp server of SLIME | SLIME contributors | Public domain |
| [trivial-gray-streams](https://github.com/trivial-gray-streams/trivial-gray-streams) | Compatibility layer for Gray streams | David Lichteblau; maintained by Anton Vodonosov | MIT |
| [zpb-ttf](https://github.com/xach/zpb-ttf) | TrueType font metrics and outlines | Zach Beane | BSD |

## Indirect dependencies

Loaded through the direct dependencies.

| Library | Description | Author | License |
|---|---|---|---|
| [3b-hdr](https://github.com/3b/3b-hdr) | Radiance HDR reader and writer | Bart Botta | MIT |
| [3bz](https://github.com/3b/3bz) | Deflate decompressor | Bart Botta | MIT |
| [alexandria](https://gitlab.common-lisp.net/alexandria/alexandria) | Portable utilities | Nikodemus Siivola and others | Public domain / 0-clause MIT |
| [array-utils](https://shinmera.com/docs/array-utils/) | Utilities for arrays | Yukari Hafner | zlib |
| [binary-structures](https://shinmera.com/docs/binary-structures/) | Reading and writing binary structures | Yukari Hafner | zlib |
| [binpack](https://github.com/3b/binpack) | Rectangle packer for texture atlases | Bart Botta, Pavel Korolev, Michael Fiano | MIT |
| [chroma](https://shinmera.com/docs/chroma) | Colour representation, conversion and operations | Yukari Hafner | zlib |
| [cl-bmp](https://shinmera.com/docs/cl-bmp/) | Windows bitmaps (BMP, DIB, ICO, CUR) | Yukari Hafner | zlib |
| [cl-jpeg](https://github.com/sharplispers/cl-jpeg) | Baseline JPEG codec | Eugene Zaikonnikov and contributors | BSD |
| [cl-ktx](https://shinmera.com/docs/cl-ktx/) | Khronos KTX image format | Yukari Hafner | zlib |
| [cl-opengl](https://github.com/3b/cl-opengl) | OpenGL bindings | maintained by Bart Botta | BSD |
| [cl-resvg](https://shirakumo.org/docs/cl-resvg/) | Bindings to the resvg SVG renderer | Yukari Hafner | zlib |
| [cl-sf3](https://shirakumo.org/docs/cl-sf3) | SF3 file formats | Yukari Hafner | zlib |
| [cl-tga](https://github.com/fisxoj/cl-tga) | TGA image loader | Matt Novenstern | MIT |
| [cl-turbojpeg](https://shirakumo.org/docs/cl-turbojpeg/) | Bindings to libjpeg-turbo | Yukari Hafner | zlib |
| [cl-vectors](https://github.com/fjolliton/cl-vectors) | Vector paths and anti-aliased rasterization | Frédéric Jolliton | MIT |
| [closer-mop](https://codeberg.org/pcostanza/closer-mop) | Portable CLOS Meta-Object Protocol | Pascal Costanza | MIT-style |
| [com.gigamonkeys.binary-data](https://github.com/gigamonkey/monkeylib-binary-data) | Reading and writing binary data | Peter Seibel | BSD |
| [deflate](https://github.com/pmai/Deflate) | Deflate decompression | Pierre R. Mai | MIT |
| [depot](https://shinmera.com/docs/depot) | Protocol for collections of files | Yukari Hafner | zlib |
| [documentation-utils](https://shinmera.com/docs/documentation-utils/) | Tools for documenting libraries | Yukari Hafner | zlib |
| [fast-io](https://github.com/rpav/fast-io) | Fast octet-vector and stream I/O | Ryan Pavlik | MIT |
| [flexi-streams](https://github.com/edicl/flexi-streams) | Flexible bivalent streams | Edi Weitz | BSD-2-Clause |
| [float-features](https://shinmera.com/project/float-features) | IEEE float features beyond the standard | Yukari Hafner | zlib |
| [font-discovery](https://shinmera.com/project/font-discovery) | Finding system font files | Yukari Hafner | zlib |
| [form-fiddle](https://shinmera.com/docs/form-fiddle/) | Destructuring lambda forms | Yukari Hafner | zlib |
| [glfw](https://shirakumo.org/docs/glfw/) | Bindings to GLFW | Yukari Hafner | zlib |
| [global-vars](https://github.com/lmj/global-vars) | Efficient global variables | James M. Lawrence | MIT |
| [ieee-floats](https://github.com/marijnh/ieee-floats) | IEEE 754 binary representation of floats | Marijn Haverbeke | BSD |
| [jsown](https://github.com/madnificent/jsown) | JSON parser | Aad Versteden | MIT |
| [memory-regions](https://shinmera.com/docs/memory-regions/) | Memory region abstraction | Yukari Hafner | zlib |
| [mmap](https://shinmera.com/docs/mmap/) | Portable file memory mapping | Yukari Hafner | zlib |
| [nibbles](https://github.com/sharplispers/nibbles) | Octet-addressed data in either byte order | Nathan Froyd; maintained by Sharp Lispers | BSD-3-Clause |
| [observables](https://shinmera.com/docs/observables/) | Observable changes on objects | Yukari Hafner | zlib |
| [opticl](https://github.com/slyrus/opticl) | Image representation and processing | Cyrus Harmon | BSD |
| [opticl-core](https://github.com/slyrus/opticl-core) | Core of opticl | Cyrus Harmon | BSD |
| [parse-float](https://github.com/soemraws/parse-float) | Parsing floats from strings | Sumant Oemrawsingh | Public domain |
| [parse-number](https://github.com/sharplispers/parse-number) | Parsing numbers | Matthew Danish; maintained by Sharp Lispers | BSD-3-Clause |
| [pathname-utils](https://shinmera.com/docs/pathname-utils/) | Pathname utilities | Yukari Hafner | zlib |
| [pngload](https://github.com/3b/pngload) | PNG reader | Michael Fiano, Bart Botta | MIT |
| [qoi](https://github.com/bpanthi977/qoi) | QOI image format | Bibek Panthi | MIT |
| [retrospectiff](https://github.com/slyrus/retrospectiff) | Reading and writing TIFF images | Cyrus Harmon | BSD |
| [salza2](https://github.com/xach/salza2) | ZLIB, DEFLATE and GZIP compression | Zachary Beane | BSD |
| [sdf](https://github.com/3b/sdf) | Signed distance field font atlases | Bart Botta, Pavel Korolev | MIT |
| [skippy](https://github.com/xach/skippy) | Reading and writing GIF files | Zachary Beane | BSD |
| [skippy-renderer](https://github.com/phoe/skippy-renderer) | GIF renderer for skippy | Michał "phoe" Herda | MIT |
| [split-sequence](https://github.com/sharplispers/split-sequence) | Splitting sequences | Arthur Lemmens; maintained by Sharp Lispers | MIT |
| [static-vectors](https://github.com/sionescu/static-vectors) | Vectors in static memory | Stelian Ionescu | MIT |
| [stealth-mixin](https://github.com/robert-strandh/Stealth-mixin) | Stealth mixin classes | Robert Strandh | FreeBSD |
| [swap-bytes](https://github.com/sionescu/swap-bytes) | Byte-swapping primitives | Stas Boukarev; maintained by Stelian Ionescu | MIT |
| [terrable](https://shirakumo.org/project/terrable) | Terragen TER reader | Yukari Hafner | zlib |
| [trivial-extensible-sequences](https://shinmera.com/docs/trivial-extensible-sequences/) | Extensible sequences protocol | Yukari Hafner | zlib |
| [trivial-features](https://github.com/trivial-features/trivial-features) | Consistent `*FEATURES*` across implementations | Luis Oliveira | MIT |
| [trivial-garbage](https://github.com/trivial-garbage/trivial-garbage) | Finalizers, weak hash tables and weak pointers | Luis Oliveira | Public domain |
| [trivial-indent](https://shinmera.com/docs/trivial-indent/) | Indentation hints for SWANK | Yukari Hafner | zlib |
| [type-templates](https://shinmera.com/docs/type-templates/) | Templated functions | Yukari Hafner | zlib |
| [uax-14](https://shinmera.com/project/uax-14) | Unicode line breaking (UAX #14) | Yukari Hafner | zlib |
| [zpb-exif](https://github.com/xach/zpb-exif) | Reading EXIF data | Zachary Beane | BSD |
| [zpng](https://github.com/xach/zpng) | Writing PNG files | Zachary Beane | BSD |

## Delivery

Used to build stand-alone applications.

| Library | Description | Author | License |
|---|---|---|---|
| [deploy](https://shinmera.com/docs/deploy/) | Builds of stand-alone deployable applications | Yukari Hafner | zlib |
| [sha3](https://github.com/pmai/sha3) | SHA-3 (Keccak), used by deploy | Pierre R. Mai | MIT/X11 |

## Copies taken from forks

- alloy: https://codeberg.org/PHRaposo/alloy, branch `om`
- cl-bmp: https://codeberg.org/PHRaposo/cl-bmp
- file-select: https://codeberg.org/PHRaposo/file-select
- font-discovery: https://codeberg.org/PHRaposo/font-discovery
- imagine: https://codeberg.org/PHRaposo/imagine
- observables: https://codeberg.org/PHRaposo/observables
- retrospectiff: https://github.com/PHRaposo/retrospectiff
