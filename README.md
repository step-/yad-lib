# yad-lib

_Enhance yad dialogs in your shell scripts._

To use `yad-lib` in your project you only need the [yad-lib.sh]
file ([download]), and a copy of the LICENSE file. Copy `yad-lib.sh`
to a directory in your `$PATH`, and set execute permissions. Your
scripts need to source `yad-lib.sh`. Refer to the [manual].

The other files in this repository are some [test scripts] for developers.

## Introduction

This shell library simplifies and enhances yad
dialog management by providing functions to:

  * Check yad version and capabilities to ensure compatibility.

  * Restart yad dialogs in the same screen position and size as before.

  * Start yad sub-dialogs over or at the four edges of the
    current dialog, for intuitive and visually consistent popups.

## Compatibility

The library is tested against my [yad] fork for GTK-2 and GTK-3. The
library should also work with the [original yad] because it does not
rely on yad, other than to run it once to determine its version number.

## Projects using yad-lib.sh

Several [Fatdog64 Linux] system utilities use yad-lib.sh.

## Documentation

Refer to the released [manual]. Up-to-date Markdown documentation is embedded
in the library source file. To extract it run the following command:

```sh
( . /path/to/yad-lib.sh && yad_lib_doc /path/to/yad-lib.sh ) > yad-lib-doc.md
```

Conversely, to strip off markdown text and produce a smaller library file:

```sh
( . /path/to/yad-lib.sh && yad_lib_doc --strip /path/to/yad-lib.sh ) > yad-lib-new.sh
```

## License

This work is dual-licensed under MIT and GNU GPL 3.0 (or any later version).

SPDX-License-Identifier: MIT OR GPL-3.0-or-later

## Links

* Home page:
[github.com/step-/yad-lib](https://github.com/step-/yad-lib)

* Releases:
[github.com/step-/yad-lib/releases](https://github.com/step-/yad-lib/releases)

* My yad GTK-2 and GTK-3 fork:
[github.com/step-/yad](https://github.com/step-/yad)

* Yad tips thread at Puppy Linux forum:
[forum.puppylinux.com/viewtopic.php?t=3922](https://forum.puppylinux.com/viewtopic.php?t=3922)

* Yad tips thread Puppy Linux _OLD_ forum:
[oldforum.puppylinux.com/puppy/viewtopic.php?t=97458](https://oldforum.puppylinux.com/puppy/viewtopic.php?t=97458)

* The original yad:
[github.com/v1cont/yad](https://github.com/v1cont/yad/)

* Fatdog64 Linux:
[distro.ibiblio.org/fatdog/web/](http://distro.ibiblio.org/fatdog/web/)

[yad-lib.sh]: <https://github.com/step-/yad-lib/blob/master/usr/bin/yad-lib.sh>
[download]: <https://raw.githubusercontent.com/step-/yad-lib/master/usr/bin/yad-lib.sh>
[manual]: <https://github.com/step-/yad-lib/blob/master/usr/share/doc/yad-lib/index.md>
[test scripts]: <https://github.com/step-/yad-lib/tree/master/usr/share/yad-lib>
[yad]: <https://github.com/step-/yad>
[Fatdog64 Linux]: <https://distro.ibiblio.org/fatdog/web/>
[original yad]: <https://github.com/v1cont/yad>

