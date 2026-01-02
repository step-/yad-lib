#!/bin/sh

# initialize
info_geom='--geometry=200x80+400+400'
info_opts='--no-focus --button=_Quit --timeout=3 --timeout-indicator=bottom'
yad=${YAD_BIN:-yad}
. yad-lib.sh

yad_lib_dispatch "$@"

# Parse script arguments.
# ...

### MAIN ###

where=${YAD_GEOMETRY:---center}

# Wait for yad to terminate and print output data.
$yad $where \
  --form --field=Now "$(date +%T)" \
  --button='_Quit:0' \
  --button="_Restart:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" |

    # Process output data, it's just an example.
    awk -v YAD="$yad --text-info $info_geom $info_opts" \
      '{print "Before", $0 | YAD} END {close(YAD)}'
