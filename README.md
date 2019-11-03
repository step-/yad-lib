title: YAD-LIB  
date: 2019-11-03  
homepage: <https://github.com/step-/yad-lib>  

---

If you came here looking for `yad-lib` to fulfill a dependency for another
script or application, you need one file,
[yad-lib.sh](https://github.com/step-/yad-lib/blob/master/usr/bin/yad-lib.sh)
[>download](https://raw.githubusercontent.com/step-/yad-lib/master/usr/bin/yad-lib.sh),
and a copy of the LICENSE file.
Copy `yad-lib.sh` to a directory in your `$PATH`, and set it executable.

The other files in this repository are the
[manual](https://github.com/step-/yad-lib/blob/master/usr/share/doc/yad-lib/index.md)
and some [test scripts](https://github.com/step-/yad-lib/tree/master/usr/share/yad-lib)
for developers.

---

# yad-lib

A shell library for yad

## Introduction

This library provides a method to programmatically start and restart a
yad[:1](#LINKS) process in a way that makes its window position and size
predictable and repeatable. The method extends to other yad instances used as
sub-windows -- automatically resized and centered over or snapped to the main
window.

## Compatibility

This library was tested with yad version 0.42, the last version to support GTK2.
A fork of version 0.42 is being maintained for Fatdog64 Linux[:2](#LINKS), which
includes this library in the base system.

The library should work also with newer yad versions as it does not rely on yad,
other than running yad once to determine its version number.

## Documentation

Markdown documentation is embedded in the
library source file. To extract the markdown text run the following
command:

```sh
( . /path/to/yad-lib.sh && yad_lib_doc /path/to/yad-lib.sh ) > yad-lib-doc.md
```

Conversely, to strip off markdown text and produce a smaller library file:

```sh
( . /path/to/yad-lib.sh && yad_lib_doc --strip /path/to/yad-lib.sh ) > yad-lib-new.sh
```

## License

This work is dual-licensed under MIT and GNU GPL 3.0 (or any later version).
You can choose between one of them if you use this work.

SPDX-License-Identifier: MIT OR GPL-3.0-or-later

<a name="LINKS"></a>

## LINKS

**Homepage**
[github.com/step-/scripts-to-go](https://github.com/step-/yad-lib)

**Release page**
[github.com/step-/scripts-to-go/releases](https://github.com/step-/yad-lib/releases)

**:1** yad - a GTK dialog program
[github.com/v1cont/yad](https://github.com/v1cont/yad/)

* Fatdog64 800 binary package
[distro.ibiblio.org/fatdog/packages/800/yad_gtk2-0.42.0_5](http://distro.ibiblio.org/fatdog/packages/800/yad_gtk2-0.42.0_5-x86_64-1.txz)

* Fatdog64 800 source (the build recipe can be found under `/usr/src` in the binary package)
[distro.ibiblio.org/fatdog/source/800/yad_gtk2-62d54eb5bf5ae2457c6986c33c6de89a6284f969.tar.gz](http://distro.ibiblio.org/fatdog/source/800/yad_gtk2-62d54eb5bf5ae2457c6986c33c6de89a6284f969.tar.gz)

* Puppy Linux forum - yad tips thread
[murga-linux.com/puppy/viewtopic.php?p=908353#908353](http://murga-linux.com/puppy/viewtopic.php?p=908353#908353)

**:2** Fatdog64 Linux
[distro.ibiblio.org/fatdog/web/](http://distro.ibiblio.org/fatdog/web/)

