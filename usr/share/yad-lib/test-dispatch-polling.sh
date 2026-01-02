#!/bin/sh

yad=${YAD_BIN:-yad}
. yad-lib.sh
POLLING=3

yad_lib_dispatch "$@"

# Parse script arguments.

### MAIN ###

YAD_TITLE=$$
$yad ${YAD_GEOMETRY:---width=400} --title="$YAD_TITLE" \
  --text="Resize/move the window; read stdout; finally click Quit..." \
  --button=_Quit:0 \
  --form --field=Date "$(date +"Yad $$ says it's %T")" > /tmp/output &

# Use PID with yad_lib_at_restart_app in a polling scenario.
yad_pid=$!

# $POLLING-second polling interval.
while sleep $POLLING; do
  if kill -0 $yad_pid; then
    yad_lib_at_restart_app --yad-pid=$yad_pid
    echo "YAD $$ restarted with output: $(cat /tmp/output)"
    exit
  else
    echo "Yad $$ exited with output: $(cat /tmp/output)"
    break
  fi
done

rm -f /tmp/output
