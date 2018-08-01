#!/bin/sh
# Initialize: Optional: set the initial position/size of the first yad window.
YAD_DEFAULT_POS="--mouse" # or --center, --width and other yad position/size arguments
# Initialize: the yad window title
YAD_TITLE="Main Window Title"

# Main
. yad-lib.sh
yad_lib_dispatch "$@"

yad ${YAD_GEOMETRY:-$YAD_DEFAULT_POS} \
  --title="$YAD_TITLE" \
    --form --field="Script pid" $$ \
    --text="$(date +%T) Try resizing and moving this window then click a button..." \
    --button="_Capture Restart:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" \
    --button="_No Capture:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\"" \
    --button="_Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --window-icon=gtk-dialog-info --title=Popup --text='Parent ID $$'\"" \
    --button=gtk-quit \
|
awk \
  -v YAD="yad --window-icon=gtk-save --no-focus --text \"Output by pid $$...\" --text-info" \
  '{print | YAD} END {close(YAD)}'

