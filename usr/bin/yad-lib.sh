# This file is sourced not run.
# vim:ft=sh:

# META-begin
# yad-lib.sh - YAD Scripting Enhancement Library
# Copyright (C) step, 2018-2026
# Dual license: GNU GPL Version 3 or MIT
# Homepage=https://github.com/step-/yad-lib
# Requirements: see section _Compatibility and Requirements_
# Version=1.4.0
# META-end
YAD_LIB_VERSION=1.4.0

# If you are reading this file in vim, run the following vim
# command to extract the markdown documentation to a new buffer:
#    :new | 0read !sh -c '(. # && yad_lib_doc #)'

: << 'MARKDOWNDOC' # {{{1 Title; Do You Need This Library?
---
title: YAD-LIB @VERSION@  
section: 1  
date: @DATE@  
version: @VERSION@
author: <https://github.com/step-/yad-lib>  
---

# SYNOPSIS

```sh
    [ENVIRONMENT] . yad-lib.sh               # if installed in your $PATH
    [ENVIRONMENT] . /path/to/yad-lib.sh      # otherwise
```

# DESCRIPTION

This shell library enhances yad scripting by providing functions to:

  * Check yad version and capabilities
  * Restart a yad dialog keeping the same size and position
  * Start a subdialog centered in or snapped to the current dialog

The library is compatible with `sh`, `bash`, `dash`, and BusyBox `ash`.
It requires `xwininfo`, `awk`, and the `proc` file system.

[Source code](https://github.com/step-/yad-lib) is hosted on GitHub.
For support questions please open a new [issue](https://github.com/step-/yad-lib/issues).
[Pull requests](https://github.com/step-/yad-lib/pulls) are welcome.

This library is developed and tested on [Fatdog64 Linux](http://distro.ibiblio.org/fatdog/web/),
where the following yad package flavors are available:

  * `yad_gtk2` (GTK-2 binary), `yad_gtk2_doc` (documentation), `yad_gtk3` (GTK-3 binary) built
     from the [GTK2 maintenance](https://github.com/step-/yad/tree/maintain-gtk2) repository.
  * `yad_ultimate` (GTK-3 binary and documentation)
     built from the [upstream yad](https://github.com/v1cont/yad) repository.

Some features between the various flavors are different, with `yad_gtk2` being Fatdog64's default;
refer to <https://github.com/step-/yad/blob/maintain-gtk2/feature-comparison.md>.
MARKDOWNDOC

: << 'MARKDOWNDOC' # {{{1 TOC

# TABLE OF CONTENTS

| | |
|-|-|
| _[Library Initialization]_       | Effects on script's environment   |
| _[Restarting Yad]_               | Window position and restarts      |
| _[Yad Window Position and Size]_ | Place the main window and a popup |
| _[Blocking and Polling]_         | Advanced topic                    |
| _[Yad Version Tests]_            | Require version and features      |
| _[Miscellaneous Functions]_      | Theming                           |
| _[Documentation]_                | Export Markdown and Manual        |

# FUNCTIONS
MARKDOWNDOC

: << 'MARKDOWNDOC' # {{{1 Library Initialization

## Library Initialization

Source the file from your script. This sets the global variable `YAD_LIB_VERSION`.

Initialization and other library functions that need to run the yad binary
take the command binary name from the `YAD_LIB_YAD` environment variable,
falling back to the `YAD_BIN` environment variable, and finally to `yad`.
Your script may preset these variables before sourcing the library file.

By default, initialization is automatic when the library file is
sourced and the `YAD_LIB_INIT` variable is not "-1". Your script may
preset this variable, then call the initialization function directly.

### yad\_lib\_init

**Usage**

```sh
    [YAD_LIB_INIT=-1 ;] yad_lib_init [$1-yad-version]
```

**Parameters**

`$1-yad-version` -- An optional version string in `major`.`minor`.`revision`
format setting the exported `YAD_LIB_YAD_VERSION` variable. If the parameter is
empty, `yad_lib_init` will run yad, set, and export the `YAD_LIB_YAD_VERSION`,
`YAD_VER_CAP`, and `YAD_STOCK_BTN` variables.

**Return Value**

`yad_lib_init` returns 0 and sets the following global variables:

| Name                    | Notes | Used by                    |
|-------------------------|-------|----------------------------|
| `YAD_LIB_SCREEN_HEIGHT` | e     | `yad_lib_set_YAD_GEOMETRY` |
| `YAD_LIB_SCREEN_WIDTH`  | e     | `yad_lib_set_YAD_GEOMETRY` |
| `YAD_LIB_YAD_VERSION`   | e     | `yad_lib_set_YAD_GEOMETRY` |
| `YAD_VER_CAP`           | e¹    | `yad_lib_set_YAD_GEOMETRY` |
| `YAD_STOCK_BTN`         | e¹    |                            |

e = exported  
¹ = exported if `$1-yad-version` is empty; otherwise, call
`yad_lib_require_yad` and export the variable manually if necessary.  

**Example**

In summary, either let the library perform automatic initialization:

```sh
    . yad-lib.sh
```

or load the library and initialize it manually:

```sh
    YAD_LIB_INIT=-1
    . yad-lib.sh '0.42.81' # exports YAD_LIB_YAD_VERSION=0.42.81

    # Optionally verify that $YAD_LIB_YAD_VERSION is at least 0.42.81
    yad_lib_require_yad '0 42 81' || die "yad is too old"
```

### Debugging

To enable library debugging, set the `YAD_LIB_DEBUG` environment variable
before running your application. `YAD_LIB_DEBUG` is a colon-separated list
of keywords. Each keyword enables a specific debugging tool. Option values,
if required, follow the keyword separated by an equal sign `=`.

| Keyword                      | Refer To                   |
|------------------------------|----------------------------|
| `geometry_popup`             | `yad_lib_set_YAD_GEOMETRY` |
| `geometry_popup_bash_caller` | `yad_lib_set_YAD_GEOMETRY` |
| `geometry_popup_fontsize`    | `yad_lib_set_YAD_GEOMETRY` |
| `geometry_popup_icon`        | `yad_lib_set_YAD_GEOMETRY` |
MARKDOWNDOC

yad_lib_init () { # [$1-yad-version] {{{1
  if [ -z "$1" ]; then
    yad_lib_require_yad 0 0 0 || :
    set -- ${YAD_VER_CAP%%:*}
    set -- "$1.$2.$3"
    export YAD_VER_CAP YAD_STOCK_BTN
  fi
  export YAD_LIB_YAD_VERSION="$1"
  set -- $(xwininfo -root | awk -F: '
/Width/  {w = $2; next}
/Height/ {h = $2; exit}
END {
  printf "%d %d", w, h
} ')
  [ $# = 0 ] && return 1
  export YAD_LIB_SCREEN_WIDTH=$1 YAD_LIB_SCREEN_HEIGHT=$2
  return 0
}

: << 'MARKDOWNDOC' # {{{1 Dispatching yad

## Restarting Yad

**Dialog Size and Position Problem Statement**

With yad, it is often necessary to capture its output and reuse the captured
data in the same dialog. In most cases, this is not directly possible but
can be achieved by terminating the dialog and immediately restarting a new,
identical one. This dialog replacement would appear nearly imperceptible to
an observer, were it not for the window manager's tendency to place the new
dialog at a different screen position. Additionally, if the user resized the
initial dialog, the new one will not match that size.

We need a method for the new dialog to inherit the position and
size of the previous one. This library implements such a method
by restarting the script that runs yad. We refer to this method
with the jargon "dispatching yad", as discussed further below.

Note that if yad's main dialog type supports a cycle-read option, you should
first try that -- it bypasses the size and position problem entirely. Using
cycle reading often involves restructuring your code and named pipes, but the
result is well worth the effort.

"Dispatching yad" means restarting the main script in a way that allows
reopening the dialog at the same position and size the window occupied
immediately before termination. Dispatching yad involves terminating
the currently running script when yad closes, then restarting another
instance of the script, which relaunches yad.

To recap how to terminate yad and how this impacts dialog output:

1. Clicking the `OK` button or pressing ENTER outputs dialog
   data, while clicking `Cancel` or pressing ESC suppresses output.

2. Closing the dialog window from the title bar suppresses output.

3. Killing yad with `SIGUSR1` outputs data, while `SIGUSR2` suppresses output.

In all three cases, before yad terminates, the library exports global
variables that the restarting script uses to open the replacement
dialog in the same screen position. Script termination is performed by
the `yad_lib_dispatch` "dispatcher" function, while restart is handled
by the `yad_lib_at_restart_app` "dispatch target" function.

Let's now demonstrate some practical examples.

### Dispatching From a Yad Button

First, your script performs its initialization, then calls `yad_lib_dispatch`
near the start of the main function, before parsing script parameters.
When the script runs yad, a button invokes the dispatch target function.

***Caveat***  
Start your script with a shebang line, such as `#!/bin/sh`.
Without it, `yad_lib_dispatch` will fail in subtle ways.

Save and run the following code as an executable shell script.
Run the script. Resize and move the window, then click a button.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-button.sh).

```sh
    #!/bin/sh

    # initialize
    info_geom='--geometry=200x80+400+400'
    info_opts='--no-focus --button=_Quit --timeout=3 --timeout-indicator=bottom'
    yad=${YAD_BIN:-yad}
    . yad-lib.sh

    yad_lib_dispatch "$@"

    # Parse script arguments.
    # ...

    ### MAIN  ###

    where=${YAD_GEOMETRY:---center}

    # Wait for yad to terminate and print output data.
    $yad $where \
      --form --field=Now "$(date +%T)" \
      --button='_Quit:0' \
      --button="_Restart:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" |

        # Process output data, it's just an example.
        awk -v YAD="$yad --text-info $info_geom $info_opts" \
          '{print "Before", $0 | YAD} END {close(YAD)}'
```

In this example, the dispatcher function is `yad_lib_dispatch`, and
`yad_lib_at_restart_app` is the dispatch target function. The action of
the `Restart` button terminates the current yad piping output to `awk` for
further processing. `yad_lib_at_restart_app`'s options are described further
below. Suffice it to note that an explicit `--exit` is needed to end the
calling script -- otherwise, multiple running yad dialogs would arise.

The _[Yad Window Position and Size]_ section discusses `$YAD_GEOMETRY`
and presents an elaborate sample script for button dispatching.

Now let's discuss two button action variants.

1. A button can restart the dialog while inhibiting dialog output:

   ```sh
       yad \
         --button="_Quit:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\""
   ```

   The word "capture" in `--no-capture` is an unfortunate historical
   misnomer, because `yad_lib_at_restart_app` obviously cannot capture data
   of its own. The `--no-capture` option simply inhibits yad dialog output.

2. A button can start _another_ yad dialog, such as a popup prompt:

   ```sh
       yad \
         --button="_Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --text='Is everything OK?'\""
   ```
   The `Popup` button does not terminate yad. Instead, it opens a new yad
   instance -- the "popup" dialog—over the current yad dialog, which keeps
   running. Although one might mistake the popup for a child window of the
   background dialog, yad cannot create child windows. The popup is a whole
   new process, and the script must handle its entire life cycle.

### Dispatching From the Main Script

`yad_lib_at_restart_app` can be used directly from the main script, instead
of from a yad button. A detailed discussion is premature now; refer to the
_[Blocking and Polling]_ section. Let's first look at the full syntax of the
dispatching functions and learn how to preserve yad position and size.

### yad_lib_dispatch

**Usage**

```sh
    yad_lib_dispatch [$@-arguments]
    shift $?
```

**Parameters**

`$@-arguments` -- The command-line arguments for the instance of your
script that is about to start. The first positional parameter must be
the name of one of the dispatch target functions presented further below.
The remaining parameters are passed to the dispatch target function.

**Return Value**

This function returns the return value of the dispatch target function. This
is most useful when the dispatch target is `yad_lib_at_restart_app` and
`yad_lib_dispatch` is passed the target's options and script arguments. Then
add `shift $?` after `yad_lib_dispatch` to consume the target's options.

### yad_lib_at_restart_app

**Usage**

```sh
    yad_lib_at_restart_app [options] ['--' $@-script-arguments]
```

When `yad_lib_at_restart_app` is called, a new yad instance starts, then the
old yad instance terminates (outputting its data). The termination/restart
order can be swapped. The script that spawned the terminating yad instance
can handle the data with a shell pipe or by redirecting output to a file.
Optionally, data output can be inhibited.

**Parameters**

`$@-script-arguments` -- Pass these arguments to the restarting script (`$0`).
The new process gets a new PID. `yad_lib_at_restart_app` terminates the calling
yad instance. It is an error to omit `--` in front of the passed arguments.

`--exit[=STATUS]` -- Exit the current process after terminating the
calling yad instance. The process exits with (integer) STATUS (default 0).

`--get-cmdline=PID` -- If `$@-script-arguments` is empty, restart the script
passing the command line that started the (integer) PID process. This option
requires the `proc` filesystem. In most cases, pass the value of `$$` as the
PID. Typical usage:

```sh
    yad --button="label:sh -c \"exec '$0' yad_lib_at_restart_app --get-cmdline=$$\""
```

```sh
    # Faster, when $0 contains no spaces.
    yad --button="label:$0 yad_lib_at_restart_app --get-cmdline=$$"
```

`--no-capture` -- Inhibit output of the terminating yad dialog.

`--terminate-then-restart[=SLEEP]` — By default, a new script instance
starts before the running yad terminates. With `--terminate-then-restart`,
the order swaps: first terminate yad, then restart the script. Use this when
the restarting script needs to read the terminating yad's output. SLEEP is
the fractional seconds to wait between terminating yad and restarting the
script (default `0.5`).

`--yad-pid=PID` -- Terminate the yad dialog whose process ID is (integer) PID.
Use this option when `yad_lib_at_restart_app` is not called from a button of
the terminating yad dialog.

**Return Value**

`123` for invalid options, otherwise the number of parsed
options. This function does not return if `--exit` is given.

### yad_lib_at_exec_popup_yad

**Usage**

```sh
    yad_lib_at_exec_popup_yad [$@-yad-arguments]
```

When `yad_lib_at_exec_popup_yad` is called, a new yad window process starts.
The script is responsible for capturing its output and terminating it. This
function is mainly a stub for illustration. Many applications will duplicate
and modify it (see _[Modifying the Dispatching Functions]_).

**Parameters**

`$@-yad-arguments` -- Valid yad options passed to the popup yad instance.

**Return Value**

The yad instance's exit status.

### Modifying the Dispatching Functions

The dispatching functions presented here cover many common cases. If your case
is not covered, create your own dispatching function. Do not edit `yad-lib.sh`
directly. Instead, copy the desired function code to your script and modify it
there. Source `yad-lib.sh` _before_ the redefined function definition.
MARKDOWNDOC

yad_lib_dispatch () { # $1-target-function [[target-function-args] '--' script-args] {{{1
# Return the return value of the target function. This is most useful when
# calling `yad_lib_dispatch yad_lib_at_restart_app option... -- script-args`
# to consume `option... --` with `shift $?`.
  case $1 in
    yad_lib_at_* ) "$@" ;;
  esac
}

yad_lib_at_restart_app () { # [options] ['--' $@-args] {{{1
# Return 123 on invalid options otherwise return the number of
# parsed options. No return if option --exit was given. Invocation:
#   in a yad -=button option:
#     sh -c "'$0' yad_lib_at_restart_app ...; shift $?"
#   in a script
#     yad_lib_at_restart_app ... ; shift $?
  local opt_exit opt_get_cmdline opt_no_capture opt_signal opt_terminate_then_restart opt_yad_pid ret=$#
  while [ $# -gt 0 ]; do
    case $1 in
      --exit ) opt_exit=exit ;;
      --exit=?* ) opt_exit=${1#*=} ;;
      --get-cmdline=?* ) opt_get_cmdline=${1#*=} ;;
      --no-capture ) opt_no_capture=no_capture ;;
      --signal=?* ) opt_signal=${1#*} ;; # UNDOCUMENTED
      --terminate-then-restart ) opt_terminate_then_restart="0.5" ;;
      --terminate-then-restart=?* ) opt_terminate_then_restart="${1#*=}" ;;
      --yad-pid=?* ) opt_yad_pid=${1#*=} ;; # required iff not in --button
      -- ) shift; break ;;
      * ) return 123 ;;
    esac
    shift
  done
  [ "$opt_no_capture" ] && opt_signal=USR2
  yad_lib_internal_restart_app ${opt_signal:-USR1} "$opt_get_cmdline" "$opt_yad_pid" "$opt_terminate_then_restart" "$@"
  # this exits the previous instance of the script
  # not the one that was just restarted
  case "$opt_exit" in
    [0-9]* ) exit $opt_exit ;;
    exit ) exit ;;
  esac
  return $(( $ret > 0 ? $ret - $# : 0 ))
}

yad_lib_internal_restart_app () { # $1-signal $2-script-pid $3-yad-pid $4-terminate-then-restart [$@5-args] {{{1 UNDOCUMENTED
# Return 0.
  local signal="$1" script_pid="$2" yad_pid="${3:-$YAD_PID}" terminate_then_restart="$4"; shift 4
  # Export current dialog geometry.
  yad_lib_set_YAD_GEOMETRY '' '' && export YAD_GEOMETRY YAD_GEOMETRY_POPUP

  # Close the target dialog (also further down).
  if [ "$terminate_then_restart" ]; then
    kill -$signal $yad_pid 2> /dev/null
    wait $yad_pid 2> /dev/null
    sleep $terminate_then_restart
  fi

  # Restart the dialog-displaying script, which will pick up the exported
  # geometry after passing through yad_lib_dispatch.
  if [ $# = 0 -a "$script_pid" -a -e /proc ]; then
    xargs -0 env < /proc/$script_pid/cmdline &
  else
    "$0" "$@" &
  fi
  sleep 0.2

  # Close the target dialog.
  # If in --button context the caller of this function should exit.
  # If not in --button context the main script unblocks from yad.
  if ! [ "$terminate_then_restart" ]; then
    kill -$signal $yad_pid 2> /dev/null
    wait $yad_pid 2> /dev/null
  fi
  true
}

yad_lib_at_exec_popup_yad () { # [$@-args] {{{1
# This function does not return
# Invocation in a yad --button:
#   sh -c "'$0' yad_lib_at_exec_popup_yad"
  yad_lib_set_YAD_GEOMETRY '' '' && export YAD_GEOMETRY YAD_GEOMETRY_POPUP
  exec ${YAD_LIB_YAD:-${YAD_BIN:-yad}} $YAD_GEOMETRY_POPUP "$@"
}

: << 'MARKDOWNDOC' # {{{1 yad_lib_set_YAD_GEOMETRY

<a name="yad_lib_set_YAD_GEOMETRY"></a>

## Yad Window Position and Size

The dispatching functions presented in the previous section can keep the
position and size of the restarted yad window. They do so by means of the
functions presented in this section.

Let's consider a hypothetical wizard-style application, which consists of
several yad dialogs chained together. The user moves through the dialogs one
at a time by pressing a button labeled "Next"; the current dialog window
closes itself and starts a new dialog for the next wizard step. With vanilla
yad, the user will see the new window appear in a position selected by the
Window Manager, likely an unexpected position. Moreover, if the current window
was resized, the new window will not retain the same size. Is there a solution?

A commonly seen, often valid solution to this issue is to fix the dialog
position and size, typically by initially placing the dialog in the center of
the screen, and locking its initial dimensions. However, this solution can
be limiting on at least two accounts. First, choosing the right width to fix
is guesswork when the application is multilingual, and future translations
are not yet available. Second, multiple applications that run at the same
time end up contending the center of the screen and covering each other.

The solution this library provides is the `yad_lib_set_YAD_GEOMETRY`
function, which makes it possible to keep the dialog size and window
position when a yad dialog restarts itself or starts a yad popup
subdialog, as seen in the _[Restaring Yad]_ section.

### yad_lib_set_YAD_GEOMETRY

**Usage**

```sh
    yad_lib_set_YAD_GEOMETRY $1-window-xid $2-window-title $3-popup-scale $4-popup-position $5-popup-message
```

`yad_lib_set_YAD_GEOMETRY` computes the geometry of the parent yad
window or a yad window specified by the positional parameters, and sets
environment variables that can be used to easily start another yad window
with the same geometry:

**Parameters**

`$1-window-xid` -- Select the target yad window by its hexadecimal id. If `$1`
is empty, yad's exported `YAD_XID`environment variable value is used instead. If
`$YAD_XID` is also empty, `yad_lib_set_YAD_GEOMETRY` selects the target window
by title `$2`. Default `window-xid` value: empty string.

`$2-window-title` -- Select the target yad window by title. If `$2` is empty
the value of the user-defined `YAD_TITLE` variable is used. This parameter is
ignored if either `$1` or `$YAD_XID` are non-empty. Default value: empty string.

`$3-popup-scale` -- A string of numbers separated by colons:

    ScaleWidth:ScaleHeight:MaxWidth:MaxHeight:MinWidth:MinHeight

It is used to calculate size and position of a popup dialog; see the _[Usage
Notes]_ subsection. `ScaleWidth`/`Height` is expressed as a percentage
of the framing dialog width and height. `Max`/`Min` `Width`/`Height` is
expressed in pixels. Use `-1` and an empty value to leave `Scale`/`Min`/`Max`
`Width`/`Height` unconstrained. `Min` and `Max` values make sense only
in the context of `Scale`, therefore they are ignored if `Scale` is left
unconstrained. If both `Min` and `Max` are given `Min` prevails.
Default value `90:50:-1:-1:-1:-1`, which centers a 90% by 50% scaled popup
over the main dialog window.

`$4-popup-position` -- One of `top`, `right`, `bottom`, `left` (also
abbreviated) to snap the popup to the respective main window side, or empty
(default) to center the popup over the main window.

`$5-popup-message` -- Debug message. It is
ignored if [popup debugging](#yad_lib_set_YAD_GEOMETRY_debug) is disabled.

**Return Value**

Zero on success; otherwise silently `123` for invalid positional parameters,
and other non-zero for other errors.

<a name="yad_lib_set_yad_geometry_debug"></a>

#### Version Notes

Since yad-lib version 1.2, slash or comma can also be used in lieu
of colons as internal separators of the `$3-popup-scale` parameter.

Since `YAD_LIB_VERSION` 1.4.0, for GTK-3 and up, the value of the
`GDK_SCALE` environment variable is further applied to the heights
and widths of the `YAD_GEOMETRY` and `YAD_GEOMETRY_POPUP` output
variables to provide automatic HiDPI screen support.

#### Usage Notes

Call `yad_lib_set_YAD_GEOMETRY` to set `YAD_GEOMETRY`, then export it and use
it in a `yad` command-line that starts or restarts the main yad dialog.

`yad_lib_set_YAD_GEOMETRY` also sets `YAD_GEOMETRY_POPUP` according to
`$3-popup-scale`. You can optionally export `YAD_GEOMETRY_POPUP`, and use it
in a `yad` command-line that starts a yad popup subdialog, that is, a yad
window that is intended to stay over the main yad dialog window, and be
quickly dismissed.

Exporting the `YAD_GEOMETRY` and `YAD_GEOMETRY_POPUP` variables affects the
dialog geometry of all subsequent and child dialogs. It is often useful to add
your own, non-exported variable, e.g., `YAD_DEFAULT_POS` to assist setting up
the initial geometry; see the _Example_ further below.

The format of `YAD_GEOMETRY`(`_POPUP`) varies by yad version as follows:

For `YAD_LIB_YAD_VERSION` < 0.40

```
    --geometry <width>x<height>+<posx>+<posy> --width=<width>  --height=<height>
```

For `YAD_LIB_YAD_VERSION` >= 0.40

```
    --posx=<posx> --posy=<posy> --width=<width>  --height=<height>
```

#### Limitations

The library tries its best to fit the popup inside the screen. To this
end it can nudge the popup away from the center of the main window, and, in
extreme cases, reduce the popup size. However, the popup may still partially lie
outside the screen because this function does not know or control the actual
size of a popup. It just makes calculations based on the values you passed
as `Scale`, `Min` and `Max`. If `Scale` is left unconstrained, yad and GTK
determine the popup size. GTK is the ultimate ruler because yad options
`--width` and `--height` _request but do not prescribe_ the size of the window.
So, if the `Scale`, `Min` and `Max` values are too small to fit the contents,
GTK could display a larger window that lies outside the screen edges.

Long text labels can pose a similar problem. Yad displays a wider and
taller window that defies relative vertical placement over the main window.
The popup is often offset towards the bottom half of the main window.

#### Debugging keywords

`geometry_popup`  
Display an information window sized and positioned according to
`$YAD_GEOMETRY_POPUP` (size might be larger if contents do not fit)
If your application calls `yad_lib_set_gtk2_STYLEFILE` the styles will be
applied to this window. If `$5-popup-message` is set it will be shown.

`geometry_popup_bash_caller=N`  
Include N levels of bash call-stack frame information (default none).
Non-negative integer N is passed to the bash `caller` built-in command.

`geometry_popup_fontsize=<Pango Markup font size>`  
Pango Markup font size value (default "x-small"). Make it smaller ("xx-small")
or larger (see the Pango Markup documentation).

`geometry_popup_icon=<icon>`  
Set yad `--window-icon` option (fall back to `YAD_OPTIONS` or yad's icon).

**Example**

```sh
    YAD_LIB_DEBUG="geometry_popup:geometry_popup_bash_caller=2:geometry_popup_fontsize=xx-small:geometry_popup_icon=gtk-dialog-info" your_app
```

**Example**

The following example uses dispatching functions, which call `yad_lib_set_YAD_GEOMETRY`.

Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-geometry.sh).

```sh
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
```
MARKDOWNDOC

yad_lib_set_YAD_GEOMETRY () { # $1-window-xid $2-window-title $3-popup-scale $4-popup-position $5-popup-message {{{1
# Compute the geometry of window $1, if any, otherwise of the parent yad
# window.  If neither one exists, compute for window title $2, if any,
# otherwise for window title YAD_TITLE. Assign global `YAD_GEOMETRY` to the
# computed geometry formatted as a long-format option.  Assign
# `YAD_GEOMETRY_POPUP` to a scaled geometry centered in `YAD_GEOMETRY` and
# corrected to fit the whole popup window inside the screen (with caveats).
# Popup-scale $3 is a string of colon-separated numbers
# "ScaleWidth:ScaleHeight:MaxWidth:MaxHeight:MinWidth:MinHeight" where
# ScaleWidth/Height are expressed in percentage of the framing dialog width and
# height, and Max/Min Width/Height are expressed in px. Min wins over Max.
# -1 and an empty value mean unconstrained Scale/Min/Max Width/Height.
# Popup-position $4 is one of "top", "right", "bottom", "left" (can abbreviate)
# to snap to the named main window side, or "" to center over the main window.
# Popup message $5 is ignored unless `YAD_LIB_DEBUG` includes "geometry_popup".
# Since `YAD_LIB_VERSION` 1.4.0, for GTK-3 and up, the value of the `GDK_SCALE`
# environment variable is further applied to the heights and widths of the
# `YAD_GEOMETRY` and `YAD_GEOMETRY_POPUP` output variables to provide automatic
# HiDPI screen support.
# Return 0 on successful assignments, 123 on bad arguments, 1 otherwise.
  local xid="${1:-$YAD_XID}" title="${2:-$YAD_TITLE}" scale="${3:-90:50:-1:-1:-1:-1}" position="${4:-center}" popup_message="$5" t a w h x y
  local title_bar_height # auto-detected; set some pixel value to override
  local geometry_popup geometry_popup_bash_caller geometry_popup_fontsize geometry_popup_icon
  local gdk_scale
  if [ "$xid" ]; then
    t=-id a=$xid
  elif [ "$title" ]; then
    t=-name a="$title"
  else
    return 123
  fi
  case :$YAD_LIB_DEBUG: in *:geometry_popup:* ) # {{{
    geometry_popup=1
    case :$YAD_LIB_DEBUG: in *:geometry_popup_bash_caller=* )
      if [ "$BASH" ]; then
        local depth="${YAD_LIB_DEBUG#*geometry_popup_bash_caller=}"; depth=${depth%%:*}
        geometry_popup_bash_caller="$(while caller $i && ((i++ <= $depth)); do :; done)"
      fi
    esac
    case :$YAD_LIB_DEBUG: in *:geometry_popup_fontsize=* )
      geometry_popup_fontsize=${YAD_LIB_DEBUG#*geometry_popup_fontsize=}
      geometry_popup_fontsize=${geometry_popup_fontsize%%:*}
    esac
    case :$YAD_LIB_DEBUG: in *:geometry_popup_icon=* )
      geometry_popup_icon=${YAD_LIB_DEBUG#*geometry_popup_icon=}
      geometry_popup_icon=${geometry_popup_icon%%:*}
    esac
  esac
  #}}}

  [ "${YAD_VER_CAP#*gtk2}" = "$YAD_VER_CAP" ] && gdk_scale=${GDK_SCALE:-1} || gdk_scale=1

  # convert scale separators comma and slash to colon
  local sep=":" ; case $scale in */* ) sep=/ ;; *,* ) sep=, ;; esac
  local IFS="$sep"
  set -- $scale
  unset IFS
  scale="$1:$2:$3:$4:$5:$6"

  set -- $(xwininfo $t "$a" | awk -F: -v P="$scale" \
    -v TITLE_BAR_HEIGHT="$title_bar_height" \
    -v WS=${YAD_LIB_SCREEN_WIDTH:-0} \
    -v HS=${YAD_LIB_SCREEN_HEIGHT:-0} \
    -v VERSION="${YAD_LIB_YAD_VERSION:-0}" \
    -v POSITION="$position" \
    -v GDK_SCALE=$gdk_scale \
    \
    -v DEBUG_POPUP="$geometry_popup" \
    -v DEBUG_POPUP_BASH_CALLER="$geometry_popup_bash_caller" \
    -v DEBUG_POPUP_FONTSIZE="${geometry_popup_fontsize:-x-small}" \
    -v DEBUG_POPUP_ICON="$geometry_popup_icon" \
    -v DEBUG_POPUP_MESSAGE="$popup_message" \
    \
    -v DEBUG_STYLEFILE="$STYLEFILE" \
    -v DEBUG_LOGFILE="/dev/stderr" \
'#{{{awk
/Absolute upper-left X/ {x  = $2 + 0; next}
/Absolute upper-left Y/ {y  = $2 + 0; next}
/Relative upper-left X/ {wt = $2 + 0; next}
/Relative upper-left Y/ {ht = $2 + 0; next}
/Width/  {w = $2 + 0; next}
/Height/ {h = $2 + 0; exit}

END {
  if(!(x y w h)) exit(-1)
  if ("" != TITLE_BAR_HEIGHT) { ht = TITLE_BAR_HEIGHT + 0 }
  x -= wt; y -= ht
  if(x < 1) { x = 0 }; if(y < 1) { y = 0 }

  if (GDK_SCALE > 1) {
    x  = int (x  / GDK_SCALE)
    y  = int (y  / GDK_SCALE)
    w  = int (w  / GDK_SCALE)
    h  = int (h  / GDK_SCALE)
  }

  for(i = split(P, Scale); i > 0; i--) {
    Scale[i] = ("" == Scale[i]) ? -1 : (Scale[i] + 0)
  }

  # scale popup width
  wp = w * Scale[1] / 100
  if(Scale[1] > 0) {
    if(Scale[5] > 0 && wp < Scale[5]) { wp = Scale[5] } # max
    if(Scale[3] > 0 && wp > Scale[3]) { wp = Scale[3] } # min wins
  }
  if(wp <= 0) { wp = 1 }

  # scale popup height
  hp = h * Scale[2] / 100
  if(Scale[2] > 0) {
    if(Scale[6] > 0 && hp < Scale[6]) { hp = Scale[6] } # max
    if(Scale[4] > 0 && hp > Scale[4]) { hp = Scale[4] } # min wins
  }
  if(hp <= 0) { hp = 1 }

  # set popup origin
  if(at_top()) {
    xp = x + w / 2 - wp / 2; yp = y - ht - hp - wt
  } else if(at_right()) {
    xp = x + w + 2 * wt; yp = y + h / 2 - hp / 2
  } else if(at_bottom()) {
    xp = x + w / 2 - wp / 2; yp = y + ht + h + wt
  } else if(at_left()) {
    xp = x - wp - 2 * wt; yp = y + h / 2 - hp / 2
  } else {
    # relative to window center
    xp = x + w / 2 - wp / 2; yp = y + h / 2 - hp / 2;
    POSITION = "center"
  }

  # pull popup inside the screen
  if(xp < 1) { xp = 0 }; if(yp < 1) { yp = 0 }
  if(WS && HS) { # fit whole popup inside the screen
    if(xp + wp > WS) { xp = WS - wp - 2 * wt }
    if(yp + hp > HS) { yp = HS - hp - 1 - ht }
    # since yad doesn`t allow negative coordinates, fix origin and clip size
    if(xp < 0) { wp += xp; xp = 0 }
    if(yp < 0) { hp += yp; yp = 0 }
  }

  # if width/height unconstrained then offset popup origin +ht+ht relative to
  # the framing window because the actual popup width/height can`t be known
  if(Scale[1] <= 0) { xp = x + ht }; if(Scale[2] <= 0) { yp = y + ht }

  # output eight words regarless of yad version
  split(VERSION, Version, ".")
  if ((0+Version[1]) > 0 || (0+Version[1]) == 0 && (0+Version[2]) >= 40) { # 0.42+
    printf "%s", result = sprintf("--posx=%d --posy=%d --width=%d --height=%d --posx=%d --posy=%d --width=%d --height=%d", x, y, w, h, xp, yp, wp, hp)
  } else { # legacy
    # seemingly redundant --width and --height added to work around issue
    # github.com/v1cont/yad/issues/#12
    printf "%s", result = sprintf("--geometry %dx%d%+d%+d --width=%d --height=%d --geometry %dx%d%+d%+d --width=%d --height=%d", w, h, x, y, w, h, wp, hp, xp, yp, wp, hp)
  }

  if(DEBUG_POPUP) { debug_popup(result) }
}

function debug_popup(result,   A, argm, args, btn, c, dlg, fld, flds, geo1, geo2, geo3, icoq, icop, klaq, klmq, mou, nbtn, noio, prey, q, eq, eeq, res1, res2, spc, sp0, speq, spa2, styq, text, tl1q, tl2q, yad) { #{{{2
# in scope: Scale[], x,y,w,h,wt,ht, xp,yp,wp,hp

  # naming convention: names ending with e*q indicate the level of embedded escaped quotes.
  eeq = esc(eq = esc(q = "\""))

  args = sprintf("%d:%d:%d:%d:%d:%d %s", Scale[1], Scale[2], Scale[3], Scale[4], Scale[5], Scale[6], POSITION)
  argm = (DEBUG_POPUP_MESSAGE != "" ? ( esc("\\r" DEBUG_POPUP_MESSAGE)) : "")
  geo3 = sprintf("%dx%d+%d+%d", wp, hp, xp, yp)
  geo2 = sprintf(" --posx=%d --posy=%d --width=%d --height=%d", xp, yp, wp, hp)
  geo1 = substr(result, 1, length(result) - length(geo2) - 1)
  posy = sprintf(" --posy=%d", yp + hp + (at_bottom() ? hp : 0)) # where buttons place dialogs
  res1 = sprintf("%s=%d %s=%d %s=%d %s=%d", "x",x,"y",y,"w",w,"h",h)
  res2 = sprintf("%s=%d %s=%d %s=%d %s=%d", "xp",xp,"yp",yp,"wp",wp,"hp",hp)

  btn  = " --button="
  fld  = " --field="
  icop = " --window-icon=gtk-paste" # no quotes
  icoq = DEBUG_POPUP_ICON ? (" --window-icon="q DEBUG_POPUP_ICON q) : ""
  nbtn = " --no-buttons"
  flds = 0
  noio = "exec <&- >/dev/null 2>&1"
  spc  = " "
  sp0  = "</span>"
  speq = "<span size=" (eq DEBUG_POPUP_FONTSIZE eq) ">"
  styq = DEBUG_STYLEFILE ? (" --gtkrc="q DEBUG_STYLEFILE q) : ""
  text = " --selectable-labels --text="
  tl2q = " --title="q "yad-lib debug" q
  tl1q = " --title="q (DEBUG_POPUP_MESSAGE != "" ? DEBUG_POPUP_MESSAGE : args) q

  srand()
  prey = nbtn "=" substr(rand() + .1, 3)
  yad  = ENVIRON["YAD_LIB_YAD"]
  if (yad == "") yad = ENVIRON["YAD_BIN"]
  yad  = (yad == "" ? "yad" : yad)" --borders=000" # "=000" to exclude non-debug yads
  klmq = "pkill -f " (q "^" yad prey spc q) # kill mine
  klaq = "pkill -f " (q "^" yad      spc q) # kill all
  dlg  = esc(icoq) nbtn

  ### buttons

  # without getcurpos: {{{
  # mou  = "  --mouse"
  # A["="] = (q (yad prey (mou esc(tl2q) icop nbtn text (eq DEBUG_POPUP_BASH_CALLER eq))) q)
  # A["#"] = (q (yad prey (mou esc(tl2q) icop nbtn text (eq dlg geo1 "\\r" dlg geo2 eq))) q)
  # A["i"] = (q (yad prey (mou esc(tl2q) icop nbtn text (eq res1 "\\r" args argm "\\r" res2 eq))) q)
  # }}}

  # with getcurpos:
  mou  = esc(" $(set -- $(getcurpos); [ $1 ] && echo --posx=$1 --posy=$(($2 +20)) || echo --mouse)")
  A["="] = (q "sh -c "esc(q noio " " yad prey (mou esc(tl2q) icop nbtn text (eq DEBUG_POPUP_BASH_CALLER eq)) q) q)
  A["#"] = (q "sh -c "esc(q noio " " yad prey (mou esc(tl2q) icop nbtn text (eq dlg geo1 "\\r" dlg geo2 eq)) q) q)
  A["i"] = (q "sh -c "esc(q noio " " yad prey (mou esc(tl2q) icop nbtn text (eq res1 "\\r" args argm "\\r" res2 eq)) q) q)

  A["p"] = (q (yad prey dlg geo2 (text (eq esc(speq) geo3 sp0 eq))) q)
  A["k"] = (q esc(klmq) q)
  A["z"] = (q esc(klaq) q)

  ### Debug dialog proper

  c = noio ";" yad tl1q icoq nbtn geo2 styq text (q (speq args sp0) q)
  if(DEBUG_POPUP_BASH_CALLER) { # bash only
  c = c fld (q "_=!!call stack:FBTN" q)       spc A["="]; ++flds
  }
  c = c fld (q "_#!!commands:FBTN" q)         spc A["#"]; ++flds
  c = c fld (q "<b>_i</b>!!summary:FBTN" q)   spc A["i"]; ++flds
  c = c fld (q "<b>_p</b>!!run popup:FBTN" q) spc A["p"]; ++flds
  c = c fld (q "_k!!kill mine:FBTN" q)        spc A["k"]; ++flds
  c = c fld (q "_z!!kill all:FBTN" q)         spc A["z"]; ++flds
  c = c " --expander --form --columns=" flds

  system(c "&")
}

function at_top()    { return 1 == index("top", POSITION) }    # {{{2
function at_right()  { return 1 == index("right", POSITION) }  # {{{2
function at_bottom() { return 1 == index("bottom", POSITION) } # {{{2
function at_left()   { return 1 == index("left", POSITION) }   # {{{2
function esc(s) { #{{{2
  # https://www.gnu.org/software/gawk/manual/gawk.html#table_002dsub_002dproposed ok {busybox,m,g}awk
  gsub(/[\\]/, "\\\\", s)
  gsub(/[$"]/, "\\\\&", s)
  return s
}

#awk}}} {{{2}}} ')
  [ $# = 0 ] && return 1
  YAD_GEOMETRY="$1 $2 $3 $4" YAD_GEOMETRY_POPUP="$5 $6 $7 $8"
  return 0
}

: << 'MARKDOWNDOC' # {{{1 Blocking and Polling

## Blocking and Polling

### Blocking

Function `yad_lib_at_restart_app` also works outside the context of yad buttons,
provided it knows the running yad PID. This facilitates implementing *blocking*
scenarios, where the main loop blocks waiting for yad to *output a message*,
then takes action based on the message content.

Consider the following example, which outputs to the terminal window.
Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-messaging.sh).

```sh
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
```

Your script can add more buttons carrying different messages and
process them in the `case` statement to trigger complex actions.
A single button click could even output multiple messages.

### Polling

Not all scripts can afford blocking to wait for yad if they must pull online
data or attend other chores while the user interacts with the GUI. In these
cases, you can still use `yad_lib_at_restart_app` but *poll* while running in
the main loop.

Consider the following example, which outputs to the terminal window.
Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-polling.sh).

```sh
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
```

The script basically sleeps all the time waking up every `$POLLING` seconds to
check if yad is still running. If it is, the script restarts yad and displays
its output. Note the `if` block requires an explicit `exit` command, similar to
the `--exit` option for button dispatching.

MARKDOWNDOC

: << 'MARKDOWNDOC' # {{{1 Yad Version Tests

## Yad Version Tests

### yad_lib_require_yad

**Usage**

```sh
    yad_lib_require_yad $1-x $2-y $3-z
```

Set the `YAD_VER_CAP` global variable to the concatenation of:

* `x y z` -- The version major, minor, and revision numbers of the yad binary.
* `:gtk`(`2`|`3`) -- The GTK toolkit version of the running file.
* (`:`_capability_)* -- Other version-dependent capabilities of the yad binary:
  `text-lang`, `selectable-labels`.

If the major version is `0`, set the `YAD_STOCK_BTN` global variable to "gtk",
otherwise to "yad". This string can be used to set yad stock buttons portably;
for example: `yad --yad-button="$YAD_STOCK_BTN-ok"`.

**Parameters**

`$1-x` required major  
`$2-y` required minor  
`$3-z` required revision  

**Return Value**

Zero if the yad binary version is at least x.y.z; otherwise non-zero.
MARKDOWNDOC

yad_lib_require_yad () { # $1-x $2-y $3-z {{{1 => $YAD_VER_CAP = 'x y z'':gtk'('2'|'3')':'() / $YAD_STOCK_BTN = ('gtk'|'yad')
  local x="${1:?}" y="${2:?}" z="${3:?}" IFS info
  unset YAD_VER_CAP YAD_STOCK_BTN
  info="$(${YAD_LIB_YAD:-${YAD_BIN:-yad}} --version)"
  [ -n "$info" ] || return 1

  # yad --version sample output (one line):
  # line 1: "0.42.43 (GTK+ 3.24.31)"
  set -- $info
  IFS="."; set -- $1 # version x.y.z
  YAD_VER_CAP="$1 $2 ${3:-0}"

  case "$info" in
    *'GTK+ 2'* ) YAD_VER_CAP="$YAD_VER_CAP:gtk2" ;;
    *'GTK+ 3'* ) YAD_VER_CAP="$YAD_VER_CAP:gtk3" ;;
  esac

  ### frequently-used :capa:bili:ties that can be tricky to assess
  [ \( $1 -eq 0 -a $2 -eq 42 -a ${3:-0} -ge 16 \) -o \( $1 -eq 0 -a $2 -gt 42 \) -o $1 -gt 0 ] &&
    YAD_VER_CAP="$YAD_VER_CAP:text-lang"
  [ \( $1 -eq 0 -a $2 -eq 42 -a ${3:-0} -ge 25 \) -o \( $1 -eq 0 -a $2 -gt 42 \) -o $1 -gt 0 ] &&
    YAD_VER_CAP="$YAD_VER_CAP:selectable-labels" # is present but broken in earlier versions

  # Yad versions 0.y.z understand `--button=gtk-ok`. Other versions require
  # `--button=yad-ok`, and provide fewer stock button choices (CAVEAT).
  [ "$1" = '0' ] && YAD_STOCK_BTN='gtk' || YAD_STOCK_BTN='yad'

  [ \( $1 -eq $x -a $2 -eq $y -a ${3:-0} -ge $z \) -o \( $1 -eq $x -a $2 -gt $y \) -o $1 -gt $x ]
}

: << 'MARKDOWNDOC' # {{{1 Miscellaneous Functions

## Miscellaneous Functions

**Theming**

### yad_lib_set_gtk2_STYLEFILE

**Usage**

```sh
    [SN=<script name>] yad_lib_set_gtk2_STYLEFILE [options] $1-style-content-keyword
```

Set the `STYLEFILE` global variable to the absolute path of a temporary,
prefilled GTK-2 style file.

The file name concatenates ".", the user name, and the calling script
name taken from the `SN` environment variable, falling back to `$0`.

**Parameters**

`$1-style-content-keyword` - Predefined style. Specify one of:

* `compact` -- Zero-padding, minimalistic baseline style for compact dialogs,
  best used in conjunction with the `--pid-name` option.

**Options**

`--pid-name` -- Append the calling PID to the temporary file name,
creating a new file. With this option, a unique file is created;
otherwise, the file name is fixed and other function calls
will overwrite the file. Typically, you would use this option to
create the baseline style, edit it (with `sed` or other editor)
adding your own styles, then pass `--gtkrc=$STYLEFILE` to yad.

**Return Value**

Zero on success; otherwise silently `123` for unknown options; other non-zero values
for other errors.

**Notes**

The caller is responsible for removing the temporary `$STYLEFILE` file on exit.

**Example**

Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-stylefile.sh).

```sh
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
```
MARKDOWNDOC

yad_lib_set_gtk2_STYLEFILE () { # $1-style-content-keyword(compact) {{{1
  local a0="${0##*/}"
  local opt_pid_name
  while [ $# -gt 0 ]; do
    case $1 in
      --pid-name ) opt_pid_name=pid_name ;;
      --* ) return 123 ;;
      * ) break ;;
    esac
    shift
  done
  case $opt_pid_name in
    pid_name )
      STYLEFILE="${TMPDIR:-/tmp}/.$USER-${SN:-$a0}"-gtkrc.$$
      rm -f "$STYLEFILE"
      ;;
    * )
      STYLEFILE="${TMPDIR:-/tmp}/.$USER-${SN:-$a0}"-gtkrc
      [ -e "$STYLEFILE" ] && return # allow manual edits
      ;;
  esac
  case $1 in
    compact ) > "$STYLEFILE" cat <<-'EOSTYLEDEF'

style "gtkcompact" {
  GtkButton::default_border={0,0,0,0}
  GtkButton::default_outside_border={0,0,0,0}
  GtkButton::relief=GTK_RELIEF_NONE
  GtkButtonBox::child_min_width=0
  GtkButtonBox::child_min_heigth=0
  GtkButtonBox::child_internal_pad_x=0
  GtkButtonBox::child_internal_pad_y=0
  GtkMenu::vertical-padding=1
  GtkMenuBar::internal_padding=0
  GtkMenuItem::horizontal_padding=4
  GtkToolbar::internal-padding=0
  GtkToolbar::space-size=0
  GtkOptionMenu::indicator_size=0
  GtkOptionMenu::indicator_spacing=0
  GtkPaned::handle_size=4
  GtkRange::trough_border=0
  GtkRange::stepper_spacing=0
  GtkScale::value_spacing=0
  GtkScrolledWindow::scrollbar_spacing=0
  GtkTreeView::vertical-separator=0
  GtkTreeView::horizontal-separator=0
  GtkTreeView::fixed-height-mode=TRUE
  GtkWidget::focus_padding=0
}

class "GtkWidget" style "gtkcompact"
EOSTYLEDEF
    ;;
  * )
    return 1
    ;;
  esac
}

: << 'MARKDOWNDOC' # {{{1 Documentation

## Documentation

Library documentation is embedded in the source file.

### yad_lib_doc

    yad_lib_doc [--strip] [$1-full-path-of-yad-lib-file]

Output the embedded markdown documentation.

**Options**

`--strip` -- Output the non-documentation lines, that is, "Just give me the source code".

**Parameters**

`$1-full-path-of-yad-lib-file` -- Specify the full path of the file containing
the embedded documentation. This parameter is required if the library is
installed in a non-standard location not included in your `PATH` variable.

**Return Value**

Zero on success; otherwise non-zero.

**Examples**

The following command extracts and displays Markdown text with the
[mdview](https://github.com/step-/mdview) viewer installed in Fatdog64 Linux.

```sh
    ( . yad-lib.sh && yad_lib_doc > /tmp/yad-lib.md && mdview /tmp/yad-lib.md ) &
```

If pandoc is installed, you can convert the Markdown document to a man page as follows:

```sh
    pandoc -s -fmarkdown -tman /tmp/yad-lib.md > /tmp/yad-lib.1
```

To strip off markdown text obtaining a smaller library file:

```sh
    (. yad-lib.sh && yad_lib_doc --strip > /tmp/yad-lib.sh)
```
MARKDOWNDOC

yad_lib_doc () { # [--strip] $1-fullpath-of-yad-lib-file {{{1
  local strip this
  if [ "$1" = '--strip' ]; then strip=1; shift; fi
  this=$1
  if ! [ -s "$this" ]; then
    ls "$this" # print generic error message
    echo "Trying standard path..." >&2
    this=$(command -v yad-lib.sh | tee /dev/stderr)
  fi
  awk -v STRIP=$strip -v DATE=$(date +%Y-%m-%d) '#{{{awk
  BEGIN { STRIP = STRIP + 0 }
  /^# Version=/ { Version = substr($0, 11) }
  /[M]ARKDOWNDOC/ { md = index($0, "<<"); next }
   md  && /@VERSION@/ { gsub(/@VERSION@/, Version) }
   md  && /@DATE@/    { gsub(/@DATE@/, DATE) }
   md  && !STRIP { print; next } # doc
  !md  &&  STRIP { print; next } # code
  #awk}}}' "$this"
}

# Initialize the library {{{1
if [ -1 != "$YAD_LIB_INIT" ]; then
  yad_lib_init
fi

