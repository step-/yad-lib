#!/bin/sh
. yad-lib.sh

YAD_TITLE=$$
! [ -e /tmp/messages ] && mkfifo /tmp/messages

yad $YAD_GEOMETRY --title="$YAD_TITLE" \
  --form --field=Pid $$ \
  --button="_Message:echo hello from $$" \
  --button="_Restart:echo restart" \
  --button=gtk-quit:0 \
  > /tmp/messages &
  yad_pid=$!

while read message; do
  case $message in
    restart ) yad_lib_at_restart_app --exit --yad-pid=$yad_pid ;;
    * ) echo "Message from yad: $message" ;;
  esac
done < /tmp/messages

rm -f /tmp/messages
