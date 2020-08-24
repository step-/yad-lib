title: YAD-LIB  
date: 1.2.1  
homepage: <https://github.com/step-/yad-lib>  

# yad-lib.sh - A Shell Library for yad

## Do You Need This Library?

[Yad](https://github.com/v1cont/yad) is a GTK dialog program that is much
simpler to use than Gtkdialog.  However, there are some common windowing
actions that are somewhat hard to do with yad until one has discovered the
right tricks. This shell library, _yad-lib.sh_, distills some of those tricks
into functions that you can use in your own scripts.

The main goal of this library is easily restarting a yad dialog in a way that
makes the dialog position and size predictable and repeatable, thus
contributing to a better user experience.

Section _Dispatching yad_ describes how to structure scripts that can control
yad dialog position and size.

Section _Keeping yad Window Position and Size_, describes
`yad_lib_set_YAD_GEOMETRY`, the function that achieves the main goal.

The remaining sections describe other functions that can be useful when dealing
with yad, such as theming GTK2 yad, etc.

Do you need this library? If your yad script just shows some static data, and
accepts (OK) or rejects (Cancel) the data, never restarting yad, or it just
shows and processes an input form then terminates, then it's unlikely that you
need this library. Since your script runs yad without restarting it, keeping
dialog position and size isn't a question for you. Yet, you may still find some
of the other functions in this library useful.

But if your shell script needs to restart the dialog several times, for
instance to refresh some dynamic data while the script keeps running, then you
know by experience that yad isn't designed to restart the dialog where it was
before, and you wish that you could do that as easily as other multi-window GUI
applications can do. Then you probably need this library.

## Usage and Documentation

Source code and documentation are hosted on
[github](https://github.com/step-/yad-lib) where you can also open support
tickets (issues) and contribute your Pull Requests (PR).

To use the library source its file from your shell script.

```sh
    . yad-lib.sh
```

assuming that the file is installed in one of the standard locations in your
`PATH`, otherwise specify the full installation path.

The library source file embeds its own documentation formatted as a
markdown document. The following command sequence extracts the markdown text
and displays it with the
[mdview](http://chiselapp.com/user/jamesbond/repository/mdview3/timeline)
viewer, which comes pre-installed in
[Fatdog64 Linux](http://distro.ibiblio.org/fatdog/web/):

```sh
( . yad-lib.sh && yad_lib_doc [> /tmp/yad-lib.md && mdview /tmp/yad-lib.md ) &
```

Conversely, to strip off markdown text and produce a smaller library file:

```sh
( . yad-lib.sh && yad_lib_doc > /tmp/yad-lib.md && mdview /tmp/yad-lib.md ) &
```

## Compatibility and Requirements

This library is compatible with `sh`, `bash`, `dash`, and `ash` (busybox). It
is intented for and tested with GTK2. It should work with yad versions as
early as 0.36.3. However, you are encouraged to updated yad to version 0.42.

This library requires `xwininfo`, `awk`, the proc file system.

## Functions

### Initialing the Library

By default library initialization occurs automatically upon sourcing the
library file.  Initialization benefits some but not all library functions.
If your application does not call those functions it can disable automatic
initialization for a faster start.  Use:

```sh
YAD_LIB_INIT="-1" . yad-lib.sh
```

to source the library without automatic initialization. Then use:

```sh
yad_lib_init [yad-version]
```

to explicitly perform initialization. If `yad-version` is empty, `yad_lib_init`
will fill it by running `yad --version` and taking the first output word.
`yad_lib_init` sets the following global variables:

```
Name                     Flags    Benefits

YAD_LIB_SCREEN_HEIGTH    e        yad_lib_set_YAD_GEOMETRY
YAD_LIB_SCREEN_WIDTH     e        yad_lib_set_YAD_GEOMETRY
YAD_LIB_YAD_VERSION      e        yad_lib_set_YAD_GEOMETRY
```

e = export


### Debugging

You can enable library debugging tools.  Set environment variable
`YAD_LIB_DEBUG` and run your application.  `YAD_LIB_DEBUG` is a colon-separated
list of keywords. Each keyword enables a specific debugging tool. Option
values, if required, can be specified after the option keyword separate by an
equal sign `=`.

The following keywords are supported:

> `geometry_popup`
[yad\_lib\_set\_YAD\_GEOMETRY](#yad_lib_set_YAD_GEOMETRY_debug).

> `geometry_popup_caller`
[yad\_lib\_set\_YAD\_GEOMETRY](#yad_lib_set_YAD_GEOMETRY_debug).

> `geometry_popup_fontsize`
[yad\_lib\_set\_YAD\_GEOMETRY](#yad_lib_set_YAD_GEOMETRY_debug).

> `geometry_popup_icon`
[yad\_lib\_set\_YAD\_GEOMETRY](#yad_lib_set_YAD_GEOMETRY_debug).


### Dispatching yad

Reading this section may prompt you to re-think how your complex yad scripts
work, and to re-write the parts that aren't compatible with the approach
presented here.

In this document we say we "dispatch" yad when we _program a yad button_ or the
_main script_ to restart the main script and yad with it in a predictable
position and size.  This involves closing the currently displayed yad script
then restarting the main script, which restarts yad. But why should we do this?
Simply because closing yad is the only way to make it output the data that its
widgets hold. If you want to further process that data you need to terminate
yad in the first place.  Let's review the ways you can terminate yad:

1. Clicking button `OK` and pressing the Enter key outputs data.
   Clicking button `Cancel` and pressing the Escape key does not output data.

2. Closing the window from the `[x]` corner icon does not output data.

3. Orderly killing the yad process outputs data. Unorderly killing it doesn't.

Dispatching uses method #3 and picks up after it. Let's learn how.

**Dispatching from a yad button**

First, Your script should call function `yad_lib_dispatch` at the beginning of
the main body, that is after performing initialization commands, and before
argument parsing.  Then the yad command(s) within the main body should include
some `--button` option(s) to initiate dispatching.

***Caveat:*** your script must start with a shebang line that sets the intended
script interpreter, for instance, `#!/bin/sh`. Without the shebang,
`yad_lib_dispatch` will fail in a subtle way.

Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-button.sh).

```sh
    #!/bin/sh
    # initialize
    . yad-lib.sh

    yad_lib_dispatch "$@"

    # parse script arguments

    # script main body
    # wait for yad to terminate
    yad $YAD_GEOMETRY \
      --form --field=Date "$(date +%T)" \
      --button="_Capture Output:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\""

    # process output data, etc.
```

In the above example button `Capture Output` terminates yad making it output
its contents for the rest of the script to process (following perhaps a shell
pipe or output redirection). All options after `yad_lib_at_restart_app` are
optional (see full syntax description further down). Take note that an explicit
`--exit` is needed to end the calling script--otherwise you may end up with
multiple running yad dialogs.  If `$0`, the path to your script, contains no
spaces, a simpler `--button` syntax can be used:

```sh
    --button="_Capture Output:$0 yad_lib_at_restart_app --exit --get-cmdline=$$"
```

Section _Keeping yad Position and Size_ discusses `$YAD_GEOMETRY`, and features
an elaborate sample script for button dispatching.

Now let us see some kinds of actions that a yad button could take.

A button could restart the dialog without capturing its input`[1]`:

```sh
    yad \
      --button="No Capture:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\""
```

`[1]`: "Capture" is an unfortunate historical misnomer because
`yad_lib_at_restart_app` does not capture data of its own, ever.  In reality,
`--no-capture` simply inhibits yad dialog's output.

A button could start _another_ yad dialog conceptually similar to a popup
window, such as a simple OK/Cancel prompt:

```sh
    yad \
      --button="Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --text='Is it OK?'\""
```

Button `Popup` doesn't terminate yad--rather, it opens a new yad instance, the
"popup" dialog, while the current (background) yad dialog keeps running.
Although one could mistake the popup for a sub-window of the background dialog,
yad does not provide sub-windows. The popup is a whole new process, and your
script needs to handle its entire life cycle.

**Dispatching from the main script**

Function `yad_lib_at_restart_app` can be used directly from the main script,
instead of from within a yad button.  Section _Polling and Messaging_ will show
how.  Before then let's look at the full syntax of the dispatching functions,
and learn how to preserve yad position and size.

**Full syntax of the dispatching functions**

```sh
    yad_lib_dispatch [$@-arguments]
```

**Positional parameters**

_Note:_ `$@-arguments` _is a shorthand indicating one or more shell positional
parameters._

`$@-arguments` - The command-line arguments for the instance of your script
that is about to start. The first positional paramenter must be the name of one
of the following dispatching functions.  The remaining parameters are passed to
the dispatching function.

**Return value**

See the description of the dispatching function.

----

```sh
    yad_lib_at_restart_app [options] [$@-script-arguments]
```

When `yad_lib_at_restart_app` is called, a new yad instance is started, then
the old yad instance is terminated, which outputs its data. The
termination/restart order can be swapped. The script that spawned the terminating yad
instance can handle the data with a shell pipe or by redirecting output to a
file.  Optionally, data output can be inhibited.

**Positional parameters**

`$@-script-arguments` - Pass these arguments to the restarting script (`$0`).
The new process will be assigned a new process id.  This function will
terminate the calling yad instance.

`--exit[=<integer>]` - Exit the current process after terminating the calling
yad instance. The process exits with status `<integer>`, if given, otherwise
with an internal status value (non-zero for error).

`--get-cmdline=<integer>` - If `$@-script-arguments` is empty restart the
script with the command-line that started process id `<integer>`.  This option
requires the proc file system.  In most cases you should pass the value of `$$`
as the process id. Typical usage:

```sh
    yad --button="label:sh -c \"exec '$0' --get-cmdline=$$\""
```

```sh
    # Faster, when $0 contains no spaces.
    yad --button="label:$0 --get-cmdline=$$"
```

`--no-capture` - Inhibit output of the terminating yad dialog.

`--terminate-then-restart` - For esthetic reasons, by default a new yad dialog
is started before the calling yad dialog is terminated. This option swaps this
order, which can be useful when the restarting script needs to read the
terminating yad dialog's output before the new yad dialog can be started.

`--yad-pid=<integer>` - Terminate the yad dialog whose process id equals
`<integer>`. You must specify this option when `yad_lib_at_restart_app` is not
called from within a button of the terminating yad dialog.

**Return value**

Silently `123` for an invalid option otherwise this function doesn't return if
option `--exit` is given. Without `--exit` the return value is zero for success
or a non-zero internal code for errors.

----

```sh
    yad_lib_at_exec_popup_yad [$@-yad-arguments]
```

When `yad_lib_at_exec_popup_yad` is called, a new yad window (process) is
started. Your script is responsible for capturing its output and terminating
it. This function is mainly a stub for illustration purposes. It is expected
that many applications will modify this function with their own version (see
section _Modifying the Dispatching Functions_).

**Positional parameters**

`$@-yad-arguments` are valid yad options to be passed to the popup yad
instance.

**Return value**

This function returns the yad instance exit status.

### Modifying the Dispatching Functions

The dispatching functions that are presented here are general enough to cover
many common cases, but you may find that your specific case isn't covered.

To modify a function do not edit file `yad-lib.sh` directly. Instead copy the
desired function code to your script file and modify it there. Make sure to
source `yad-lib.sh` _before_ the redefined function definition.

<a name="yad_lib_set_YAD_GEOMETRY"></a>

### Keeping yad Window Position and Size

Unlike `gtkdialog`, `yad` has no notion of its window position; it relies
entirely on the window manager to set where the next yad instance window should
appear on the screen, which could appear in a different position at a different
size. Then the user experiences the unexpected effect of a yad window that
"jumps around" the screen.

For instance, consider a wizard-style application, which consists of several
yad dialogs chained together. The user moves through the dialogs one at the
time by pressing a button labelled "Next"; the current dialog window closes
itself and starts a new dialog for the next wizard step.  With vanilla yad, the
user will see the new window appear in an unexpected position. Moreover, if the
current window was resized, the new window will not retain the same size.

A commonly implemented solution to this issue is to fix the dialog position and
size, typically by placing it in the center of the screen with large-enough
width and height. This solution is problematic on at least two accounts. First,
setting the width and height becomes guess-work for applications that can be
localized because the programmer doesn't know in advance how much space will
translated strings take. Second, if several instances of the same application
need to run concurrently, their windows will cover each other in the center of
the screen.

Enter function `yad_lib_set_YAD_GEOMETRY`, which makes possible to retain the
dialog size and window position when a yad dialog restarts itself or starts a
yad popup sub-dialog.

Note: The functions presented in section _Dispatching yad_ use
`yad_lib_set_YAD_GEOMETRY` directly. So if your script just calls the
dispatching functions --as it should do in most cases-- you can skip the next
few paragraphs, and try the example script at the end of this section. Come
back here for a second reading when you can.

```sh
yad_lib_set_YAD_GEOMETRY $1-window-xid $2-window-title $3-popup-scale $4-popup-position $5-popup-message
```

Function `yad_lib_set_YAD_GEOMETRY` computes the geometry of the parent yad
window or a yad window specified by the positional parameters, and sets
environment variables that can be used to easily start another yad window
with the same geometry:

**Positional Parameters**

`$1-window-xid` - Select the target yad window by its hexadecimal id. If empty,
it is replaced by the value of `$YAD_XID`, which yad automatically exports to
_children_ dialog windows. If also empty, `yad_lib_set_YAD_GEOMETRY` selects
the target window by title `$2`.  Default value: empty string.

`$2-window-title` - Select the target yad window by its title. If empty, it is
replaced by the value of `$YAD_TITLE`, which is a user-defined
variable, if set. Ignored if either `$1` or `$YAD_XID` is non-empty.  Default
value: empty string.

`$3-popup-scale` - A string of colon- or slash- or comma-separated numbers
`ScaleWidth:ScaleHeight:MaxWidth:MaxHeight:MinWidth:MinHeight` used to
calculate size and position of a popup dialog. See section _Calling
discipline_.  ScaleWidth/Height are expressed in percentage of the framing
dialog width and height, and Max/Min Width/Height are expressed in px.  `-1`
and an empty value mean unconstrained Scale/Min/Max Width/Height.
Min and Max values make sense only in the context of Scale, therefore they
are ignored if the Scale is specified unconstrained.
If both Min and Max are given Min prevails.
Since yad-lib version 1.2 the separator can be slash or comma in lieu of colon.
Default string `90:50:-1:-1:-1:-1`, which centers a 90% by 50% scaled popup
over the main dialog window.

`$4-popup-position` - One of `top`, `right`, `bottom`, `left` (also
abbreviated) to snap the popup to the respective main window side, or empty
(default) to center the popup over the main window.

`$5-popup-message` - Debug message -
ignored if [popup debugging](#yad_lib_set_YAD_GEOMETRY_debug) is disabled.

**Limitations**

The library tries its best to fit the coming popup inside the screen. To this
end it can nudge the popup away from the center of the main window, and, in
extreme cases, reduce the popup size. However, there is no guarantee that the
popup will actually fit inside the screen. In particular, do realize that this
function can't know or control the actual size of a popup. It only makes
calculations based on the values specified for Scale, Min and Max.  If Scale is
specified unconstrained, yad and GTK --not this function-- will determine popup
size.  GTK is the ultimate ruler because yad options `--width` and `--height`
_request but do not prescribe_ the size of the window. So, if Scale, Min and
Max values are too small to fit the content in a way that GTK finds agreable,
GTK will display a larger window, which could possibly fall outside the screen
boundaries. Similarly, when yad displays a larger (typically taller) window,
its relative vertical placement over the main window will be off-centered
(typically offset towards the bottom half of the main window).

**Calling discipline**

Two exported variables, `YAD_GEOMETRY` and `YAD_GEOMETRY_POPUP`, affect the
dialog geometry.  An optional, non-exported variable, `YAD_DEFAULT_POS` (or
another variable name of your own choosing) can assist in setting up the
initial geometry, see section _Example_.

Call `yad_lib_set_YAD_GEOMETRY` to set `YAD_GEOMETRY`, then export it and use
it in a `yad` command-line that starts or re-starts the main yad dialog.

`yad_lib_set_YAD_GEOMETRY` also sets `YAD_GEOMETRY_POPUP` according to
`$3-popup-scale`. You can optionally export `YAD_GEOMETRY_POPUP`, and use it
in a `yad` command-line that starts a yad popup sub-dialog, that is, a yad
window that is intended to show over the main yad dialog window, and be
quickly dismissed.

The format of `YAD_GEOMETRY`(`_POPUP`) varies by yad version as follows:

> For `YAD_LIB_YAD_VERSION` < 0.40
```
--geometry <width>x<height>+<posx>+<posy> --width=<width>  --height=<height>
```

> For `YAD_LIB_YAD_VERSION` >= 0.40
```
--posx=<posx> --posy=<posy> --width=<width>  --height=<height>
```

**Return value**

Zero on success otherwise silently `123` for invalid positional parameters,
and other non-zero for other errors.

<a name="yad_lib_set_YAD_GEOMETRY_debug"></a>

**Debugging keywords**

> `geometry_popup`  
Display an information window sized and positioned according to
`$YAD_GEOMETRY_POPUP`, although size might be larger if contents do not fit.
If your application calls `yad_lib_set_gtk2_STYLEFILE` the styles will be
applied to this window. If `$5-popup-message` is set it will be shown.

> `geometry_popup_caller=<n>`  
Include <n> levels of bash call-stack frame information (default none).
Non-negative integer `<n>` is passed to the bash `caller` built-in command.

> `geometry_popup_fontsize=<Pango font size>`  
Pango font size value (default "x-small"). Make it smaller ("xx-small")
or larger (see the Pango documentation).

> `geometry_popup_icon=<icon>`  
Set yad `--window-icon` option (fall back to `YAD_OPTIONS` or yad's icon).

```sh
YAD_LIB_DEBUG="geometry_popup:geometry_popup_caller=2:geometry_popup_fontsize=xx-small:geometry_popup_icon=gtk-dialog-info" your_app
```

**Example**

The following example uses _dispatching_ functions, which call
`yad_lib_set_YAD_GEOMETRY`.

Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-geometry.sh).

```sh
    #!/bin/sh
    # Initialize: Optional: set the initial position/size of the first yad window.
    YAD_DEFAULT_POS="--mouse" # or --center, --width and other yad position/size arguments
    # Initialize: the yad window title
    YAD_TITLE="Main Window Title"

    # Main
    . yad-lib.sh
    yad_lib_dispatch "$@"

        yad ${YAD_GEOMETRY:-$YAD_DEFAULT_POS} \
          --title="$YAD_TITLE" \
            --form --field="Script pid" $$ \
            --text="$(date +%T) Try resizing and moving this window then click a button..." \
            --button="_Capture Restart:sh -c \"exec '$0' yad_lib_at_restart_app --exit --get-cmdline=$$\"" \
            --button="_No Capture:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\"" \
            --button="_Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --window-icon=gtk-dialog-info --title=Popup --text='Parent ID $$'\"" \
            --button=gtk-quit \
        |
        awk \
          -v YAD="yad --window-icon=gtk-save --no-focus --text \"Output by pid $$...\" --text-info" \
          '{print | YAD} END {close(YAD)}'
```

**More examples**

[dndmate](https://github.com/step-/scripts-to-go/blob/master/README.md#dndmate)
manages a yad paned dialog and several popup subdialogs with the help of
`yad_lib_set_YAD_GEOMETRY`.  This is a full -- and complex -- example.

### Blocking and Polling

Dispatching with function `yad_lib_at_restart_app` also works outside the
context of a yad button, as long as it's given the process id of a running yad
dialog.  This can be useful in a _blocking_ scenario, in which the main loop
blocks waiting for _message output_ from yad then takes actions based on
message content.

Consider the following example, which outputs to the terminal window.
Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-messaging.sh).

```sh
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
```

You can add more buttons with different types of messages, and process the
messages in the `case` statement. Note that the button can execute any complex
command or script, not just `echo`. A single button click can even output
multiple messages.

----

Some scripts can't block the main loop waiting for output from yad. Such is the
case for scripts that need to do other things while the user interacts with
yad, like fetching more data from online sources or attending to other yad
windows. You can still use `yad_lib_at_restart_app` in those cases, and _poll_
in the main loop.

Consider the following example, which outputs to the terminal window.
Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-dispatch-polling.sh).

```sh
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
```

When you press button `OK` yad exits in the else-block. If you don't press a
button, after the polling period expires yad is restarted in the if-block. Note
that the if-block needs an `exit` statement akin to the `--exit` option for the
button dispatching case.

**More examples**

[fatdog-wireless-antenna](https://github.com/step-/scripts-to-go/blob/master/README.md#fatdog-wireless-antenna)
manages its window with a polling scheme.

### Theming yad With a GTK2 Style File

```sh
    [SN=<script name>] yad_lib_set_gtk2_STYLEFILE [options] $1-style-content-keyword
```

Set global variable `STYLEFILE` to the absolute path of a temporary GTK2 style
file.

The file name is composed of the user name and the calling script file name
specified through environment variable `SN`, if set, otherwise from `$0`.  See
also option `--pid-name` below.

**Positional parameters**

`$1-style-content-keyword` - Select pre-defined style definitions. One of

* `"compact"` - Zero paddings and other style parameters to make the dialog as
  compact as possible.

**Options**

`--pid-name` - Append the calling PID to the temporary file name, and create a
new file.  Without this option, the file name is fixed - given the calling
script - and it doesn't overwrite an existing file by the same name. This
allows for editing the file outside this library.

**Return Value**

Zero on success otherwise silently `123` for unknown options, and other non-zero
for other errors.

**Notes**

The calling script should remove temporary file `$STYLEFILE` on exit.

**Example**

Save and execute the following code as an executable shell script.
[>download the file](https://github.com/step-/yad-lib/blob/master/usr/share/yad-lib/test-stylefile.sh).

```sh
    #!/bin/sh
    . yad-lib.sh >/dev/null
    trap 'rm -f $STYLEFILE' INT 0 # remove style file on Ctrl+C and exit
    if ! yad_lib_set_gtk2_STYLEFILE "compact"; then
      echo "Handle some error" >&2
    fi &&
    yad --title="With style file" --gtkrc="$STYLEFILE" &
    yad --title="Without style file" &
```

### Sundry

    yad_lib_doc [--strip] [$1-full-path-of-yad-lib-file]

Output the embedded markdown documentation. See also section _Usage and
Documentation_.

**Options**

`--strip` - Output non-documentation lines, that is, just the source code.

**Positional parameters**

`$1-full-path-of-yad-lib-file` - Specify the full path of the file containing
the embedded documentation.  Required if the library is installed in a
non-standard location not included in your `PATH` variable.

**Return value**

Zero on success, non-zero on error.
