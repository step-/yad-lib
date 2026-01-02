#!/bin/sh

yad=${YAD_BIN:-yad}
. yad-lib.sh

YAD_TITLE=$$
! [ -e /tmp/messages ] && mkfifo /tmp/messages

$yad $YAD_GEOMETRY --title="$YAD_TITLE" \
  --text="Resize/move the window; click a button; read stdout..." \
  --form --field=Pid $$ \
  --button="_Message:echo hello from $$" \
  --button="_Restart:echo restart" \
  --button=_Quit:0 \
  > /tmp/messages &

# Use PID if yad_lib_at_restart_app isn't within a --button.
  yad_pid=$!

while read message; do
  case $message in
    restart ) yad_lib_at_restart_app --exit --yad-pid=$yad_pid ;;
    * ) echo "Message from yad: $message" ;;
  esac
done < /tmp/messages

rm -f /tmp/messages
