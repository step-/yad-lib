#!/bin/sh

# Initialize: Optional: set the initial position/size of the first yad window.
YAD_DEFAULT_POS="--mouse" # or --center, --width and other yad position/size arguments
# Initialize: the yad window title
YAD_TITLE="Main Window Title"

info_geom='--geometry=200x80+400+400'
info_opts='--no-focus --button=_Quit --timeout=3 --timeout-indicator=bottom'

yad=${YAD_BIN:-yad}
. yad-lib.sh
yad_lib_dispatch "$@"

### Main ###

# Wait for yad to terminate and print output data.
$yad ${YAD_GEOMETRY:-$YAD_DEFAULT_POS} \
  --title="$YAD_TITLE" \
    --form --field="Script pid" $$ \
    --text="$(date +%T) Resize and move the window, then click a button..." \
    --button="_Capture and Restart:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" \
    --button="_No Capture:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\"" \
    --button="_Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --window-icon=gtk-dialog-info --title=Popup --text='Parent ID $$'\"" \
    --button='_Quit:0' |

    # Popup example
    awk -v YAD="$yad --text-info $info_geom $info_opts --text \"PID $$'s output...\"" \
      '{print | YAD} END {close(YAD)}'

