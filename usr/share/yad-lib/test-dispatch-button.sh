#!/bin/sh
# initialize
. yad-lib.sh

yad_lib_dispatch "$@"

# parse script arguments

# script main body
# wait for yad to terminate
yad $YAD_GEOMETRY \
  --form --field=Date "$(date +%T)" \
  --button="_Capture Output:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" \
  | awk \
    -v YAD="yad --no-focus --no-buttons --window-icon=gtk-info --text-info" \
    '{print | YAD} END {close(YAD)}'

