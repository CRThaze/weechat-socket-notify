# socket_notify.rb

Send highlights and private message to a unix socket.

Ideal for those running WeeChat as a bouncer (as in a long-lived screen
session on a server), but can also be used for sending notifications when
running locally.

## How it Works

Whenever weechat gets a private message or a highlight this script will write a
short description and the message to the `/tmp/weechat.notify.socket` unix
socket if it exists. If the socket doesn't exist or isn't currently listening
then this script does nothing.

The message written is in the form:

    <Base64 Description> <Base64 Message>

I chose to do this since it made reading the message with bash scripts really
easy. You can read one line at a time from the socket and split on space to get
both items. Please let me know if there are any other good uses for this that
you come up with!

## Usage

### Installing in WeeChat

Place the script at `~/.weechat/ruby/socket_notify.rb` and symlink into
`~/.weechat/ruby/autoload` if you want it to load on startup.

Then load it in weechat by running:

    /script load socket_notify.rb

### Reading Notifications

OpenBSD NetCat can be used to read the notifications from this socket:

```bash
nc -k -l -U /tmp/weechat.notify.sock
```

If the version of NetCat (`nc`) you have does not support the `-U` option, you
likely have either GNU NetCat or the OG (traditional) Unix NetCat (AKA the
"Hobbit" one) and must install the OpenBSD version.

This should be installed and available on the host running WeeChat.

```bash
# Debian
apt install netcat-openbsd

# Fedora
dnf install netcat

# macOS ships with this.
```

The messages read from this socket will be Base64 encoded, and will need to
be decoded for usage. A command-line tool for this `base64` should exist in
most operating systems.

### Displaying Notifications

On **macOS** this can be accomplished with
[`terminal-notifier`](https://github.com/alloy/terminal-notifier). And on linux
you can use `libnotify`'s
[`notify-send`](https://github.com/GNOME/libnotify/blob/master/tools/notify-send.c)
utility or
[`dunstify`](https://github.com/dunst-project/dunst/blob/master/dunstify.c) if
you are using [`dunst`](https://dunst-project.org/).

```bash
# Debian
apt install libnotify-bin

# Fedora
dnf install libnotify

# Arch
pacman -Sy libnotify

# macOS
brew install terminal-notifier
```

`dunstify` will ship with the `dunst` framework.

Linux Machines will also need either `aplay` or `paplay` to play notification
sounds. `paplay` should be available on most Pulseaudio/Pipewire Linux
distributions, and has the benefit of supporting OGG and `.oga` file types
like those that are usually included in your desktop environment.

These standard notification sounds can usually be found in:
`/usr/share/sounds/`

### Handling notifications automatically when using WeeChat

The `irc-bounce-and-notify.sh` script in this repo can be used to both launch
a listener for notifications as well as WeeChat (or attach to a WeeChat
Bouncer).

It takes two arguments:
- The host target for where WeeChat will run: `(localhost | [user@]host)`
- The command to invoke WeeChat: e.g. `'screen -D -R -S weechat -- weechat'`

It also supports some additional configuration through environment
variables. Please look in the script for details on these.

It defaults to localhost and running `weechat` but it is recommended to run
weechat in a screen session on a bouncer, and then simply attach and detach
from this session. Using `screen -D -R -S weechat -- weechat` to attach and
`C-a C-d` to detach. This screen session can also be on your local machine.

You can either create a wrapper script or alias to invoke this script with
your required parameters. To create an alias add the following to your
`.bashrc`:

```bash
alias irc="LINUX_AUDIO_PLAYER=aplay irc-bounce-and-notify.sh localhost 'screen -D -R -S weechat -- weechat'"
```
