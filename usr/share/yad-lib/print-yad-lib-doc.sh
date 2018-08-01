#!/bin/sh
viewer=mdview
type $viewer >/dev/null 2>&1 || viewer=defaulttexteditor
. yad-lib.sh && yad_lib_doc > /tmp/yad-lib.md && $viewer /tmp/yad-lib.md &
