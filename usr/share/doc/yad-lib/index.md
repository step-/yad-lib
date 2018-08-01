_document revision: 1.0.0_

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

The library source file embeds its own English documentation formatted as a
markdown document. The following command sequence displays the full
documentation using the
[mdview](http://chiselapp.com/user/jamesbond/repository/mdview3/timeline)
viewer, which is pre-installed in
[Fatdog64 Linux](http://distro.ibiblio.org/fatdog/web/):

```sh
    ( . yad-lib.sh && yad_lib_doc > /tmp/yad-lib.md && mdview /tmp/yad-lib.md ) &
```

## Compatibility and Requirements

This library is compatible with `sh`, `bash`, `dash`, and `ash` (busybox). It
is intented for and tested with GTK2. It should work with versions of yad as
early as 0.36.3. However, you are encouraged to updated yad to the latest
version.

This library requires `xwininfo`, `awk`, the proc file system.

## Functions

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

**Dispatching a yad button**

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

Button `Capture Output` terminates yad and makes it output its contents for
your script to further process with a shell pipe or output redirection. Note
that you need to explicitly tell the button to `--exit` otherwise your script
will end up with two new running yad dialogs instead of one.

Section _Keeping yad Position and Size_ discusses `$YAD_GEOMETRY`. There you
can also find a more elaborate button dispatching sample script.

If you can guarantee that `$0`, the path to your script, contains no spaces, a
simpler button alternative can gain marginal performance improvements:

```sh
    --button="_Capture Output:$0 yad_lib_at_restart_app --exit --get-cmdline=$$"
```

All examples in this document will stick to the more general syntax involving
`sh -c`.

Now let's explore what else your script can do from a yad button.

A button could restart the dialog without capturing its input:

```sh
    yad \
      --button="No Capture:sh -c \"exec '$0' yad_lib_at_restart_app --no-capture --exit --get-cmdline=$$\""
```

A button could start _another_ dialog conceptually similar to a popup window,
such as a simple OK/Cancel prompt:

```sh
    yad \
      --button="Popup:sh -c \"exec '$0' yad_lib_at_exec_popup_yad --text='Is it OK?'\""
```

Button `Popup` doesn't terminate yad. It opens a new instance, figuratively
called a "popup" dialog, while the current yad dialog keeps running. Although
you could think of the the popup as a sub-window of the existing dialog, make
no mistake; it's a new, full process. Your script needs to handle its entire
life cycle.

**Dispatching the main script**

Function `yad_lib_at_restart_app` can be used directly from the main script,
instead of from within a yad button.  Section _Polling and Messaging_ will show
us how.  Before that topic we need to establish the dispatching function
syntax, and to learn how to preserve yad position and size.

**Full dispatching function syntax**

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

When `yad_lib_at_restart_app` is called, the calling yad instance
terminates and outputs its data. Your script can handle the data with a shell
pipe or with an output redirection to a file. The latter is recommended if you
want for the new script instance to reload the output data.

**Positional parameters**

`$@-script-arguments` - Pass these arguments to the restarting script (`$0`).
The new process will be assigned a new process id.  This function will
terminate the calling yad instance.

`--exit[=<integer>]` - Exit the current process after terminating the calling
yad instance. The process exits with status `<integer>`, if given, otherwise
with an internal status value (non-zero for error).

`--get-cmdline=<integer>` - If `$@-script-arguments` is empty restart the
script with the command-line that started process id `<integer>`.  This option
requires the proc file system (available by default in Linux).  In most cases
you should pass the value of `$$` as the process id. Typical usage:

```sh
    yad --button="label:sh -c \"exec '$0' --get-cmdline=$$\""
```

```sh
    # Faster, if you can guarantee that $0 contains no spaces.
    yad --button="label:$0 --get-cmdline=$$"
```

`--no-capture` - Discard output of the terminating yad dialog.

**Return value**

`123` silently for an invalid option otherwise this function doesn't return if
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
yad_lib_set_YAD_GEOMETRY directly. So if your script just calls the dispatching
functions --as it should do in most cases-- you can skip the next few
paragraphs, and try the example script at the end of this section. Come back
here for a second reading when you can.

```sh
    yad_lib_set_YAD_GEOMETRY() $1-window-xid $2-window-title $3-popup-scaling
```

Function `yad_lib_set_YAD_GEOMETRY` computes the geometry of the parent yad
window, or of a yad window specified by the positional parameters, and sets
environment variables that can be used to easily start another yad window
having the same geometry.

**Positional Parameters**

`$1-window-xid` - Select the target yad window by its hexadecimal id. If null,
it is replaced by the value of `$YAD_XID`, which yad automatically sets for
_children_ dialog windows. If still null, `yad_lib_set_YAD_GEOMETRY` selects
the target window with `$2`.  Default value: null string.

`$2-window-title` - Select the target yad window by its title. If null, it is
replaced by the value of `$YAD_TITLE`, which is a user-defined
variable, if any. Ignored if either `$1` or `$YAD_XID` is non-null.  Default
value: null string.

`$3-popup-scaling` - A string of colon-separated numbers
"ScaleWidth:ScaleHeight:MaxWidth:MaxHeight:MinWidth:MinHeight" used to
calculate size and position of a popup dialog. See section _Calling
discipline_.  ScaleWidth/Height are expressed in percentage of the framing
dialog width and height, and Max/Min Width/Height are expressed in px.  `"-1"`
and omitted values mean unconstrained Scale/Min/Max Width/Height.  Default
string `"90:50:-1:-1:-1:-1"`, which positions a 90% by 50% scaled popup in the
center of the main dialog window.

**Calling discipline**

Two exported variables, `YAD_GEOMETRY` and `YAD_GEOMETRY_POPUP`, affect the
dialog geometry.  An optional, non-exported variable, `YAD_DEFAULT_POS` (or
another variable name of your own choosing) can assist in setting up the
initial geometry, see section _Example_.

Call `yad_lib_set_YAD_GEOMETRY` to set `YAD_GEOMETRY`, then export it and use
it in a `yad` command-line that starts or re-starts the main yad dialog.

`yad_lib_set_YAD_GEOMETRY` also sets `YAD_GEOMETRY_POPUP` according to
`$3-popup-scaling`. You can optionally export `YAD_GEOMETRY_POPUP`, and use it
in a `yad` command-line that starts a yad popup sub-dialog, that is, a yad
window that is intended to show over the main yad dialog window, and be
quickly dismissed.

**Return value**

Zero on success otherwise `123` silently for invalid positional parameters,
other non-zero for other errors.

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

[dndmate](https://github.com/step-/scripts-to-go/blob/master/dndmate/usr/bin/dndmate)
is a complete script that calls `yad_lib_set_YAD_GEOMETRY` directly.

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

[fatdog-wireless-antenna](https://github.com/step-/scripts-to-go/blob/master/fatdog-wireless-antenna/usr/sbin/fatdog-wireless-antenna.sh)
is a complete script that uses polling.

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

Zero on success otherwise `123` silently for unknown options or other non-zero
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

    yad_lib_doc [$1-full-path-of-yad-lib-file]

Output the embedded markdown documentation. See also section _Usage and
Documentation_.

**Positional parameters**

`$1-full-path-of-yad-lib-file` - Specify the full path of the file containing
the embedded documentation.  Required if the library is installed in a
non-standard location not included in your `PATH` variable.

**Return value**

Zero on success, non-zero on error.
