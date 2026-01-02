#!/bin/sh

yad=${YAD_BIN:-yad}
. yad-lib.sh

trap 'rm -f $STYLEFILE' INT 0 # remove style file on Ctrl+C and exit

if [ "${YAD_VER_CAP#*:gtk2:}" = "$YAD_VER_CAP" ]; then
  $yad --center --text "
yad_lib_set_gtk2_STYLEFILE() affects GTK-2 but not GTK-3 dialogs.

The upcoming two yad dialogs will look the same.

Try using a GTK-2 yad binary to see a difference.
  " --button=gtk-ok:0 --timeout=5 --timeout-indicator=bottom
fi

options="
--button=!gtk-ok:0 --button=!gtk-cancel:1
--list --column=Lines --height=700 --width=400
"

if ! yad_lib_set_gtk2_STYLEFILE "compact"; then
  $yad --text="Error" >&2
else
  $yad --on-top --title="With style file" --text="With style file" \
    --gtkrc="$STYLEFILE" --posx=300 $options < "$STYLEFILE" &
  $yad --on-top --title="Without style file" --text="Without" \
    --posx=700 $options < "$STYLEFILE" &
  wait
fi
