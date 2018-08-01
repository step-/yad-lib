# A shell library for yad

The main goal of this library is easily restarting a
[yad](https://github.com/v1cont/yad) dialog in a way that makes the dialog
position and size predictable and repeatable.

A structure for scripts that can control yad dialog position and size is proposed.

Restarting yad from a yad button or from the main script body is discussed
--including the polling case-- with example scripts.

The remaining sections describe other functions that can be useful when dealing
with yad, such as theming GTK2 yad, etc.

The following projects are known to use yad-lib:

* [dndmate](https://github.com/step-/scripts-to-go/blob/master/dndmate/usr/bin/dndmate)
* [fatdog-wireless-antenna](https://github.com/step-/scripts-to-go/blob/master/fatdog-wireless-antenna/usr/sbin/fatdog-wireless-antenna.sh)
