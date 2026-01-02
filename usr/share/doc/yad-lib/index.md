---
title: YAD-LIB 1.4.0  
section: 1  
date: 2026-01-02  
version: 1.4.0
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
