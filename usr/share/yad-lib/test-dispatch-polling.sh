#!/bin/sh
# initialize
. yad-lib.sh
POLLING=3

yad_lib_dispatch "$@"

# parse script arguments

# script main body
YAD_TITLE=$$
yad ${YAD_GEOMETRY:---width=400} --title="$YAD_TITLE" \
  --form --field=Date "$(date +"Yad $$ says it's %T")" > /tmp/output &
yad_pid=$!

# polling at $POLLING second intervals
while sleep $POLLING; do

  if ps $yad_pid >/dev/null; then
    yad_lib_at_restart_app --yad-pid=$yad_pid
    echo "YAD $$ restarted with output: $(cat /tmp/output)"
    exit
  else
    echo "Yad $$ exited with output: $(cat /tmp/output)"
    break
  fi

done

