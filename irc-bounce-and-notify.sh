#!/bin/bash
#
# AUTHOR: Diego Fernando Carrión (CRThaze)
# Based on the work of: Christopher Giroir <kelsin@valefor.com>

# Environment Variables
MACOS_ICON_PATH=${MACOS_ICON_PATH:-"/Applications/WeeChat.app/Contents/Resources/weechat.icns"}
MACOS_TERM_EMULATOR=${MACOS_TERM_EMULATOR:-"com.apple.Terminal"}
MACOS_ACTIVATION_CMD=${MACOS_ACTIVATION_CMD:-"/usr/local/bin/tmux select-window -t 0:IRC"}
MACOS_SOUND=${MACOS_SOUND:-"default"}
LINUX_AUDIO_PLAYER=${LINUX_AUDIO_PLAYER:-"paplay"}
LINUX_SOUND=${LINUX_SOUND:-"/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"}

# Arguments
HOST=${1:-"localhost"}
WEECHAT_INVOCATION_CMD=${2:-"~/weechat.sh"}

if [ "$HOST" == "-h" ]
then
	echo "Usage: $(basename $0) <user@hostname> <weechat cmd>"
	echo
	echo -e "\tuser@hostname: The SSH connection string to the host running"
	echo -e "\t               WeeChat. If you specify localhost, SSH will not"
	echo -e "\t               be used."
	echo -e "\tweechat cmd:   The command to run WeeChat on the host."
	exit 1
fi

OS_TYPE="${OSTYPE%%+([[:digit:].])}"

case "$OS_TYPE" in
	linux-gnu)
		if ! command -v notify-send &> /dev/null
		then
			echo "notify-send is required for Linux notifications."
			exit 1
		fi
		if ! command -v "$LINUX_AUDIO_PLAYER" &> /dev/null
		then
			echo "${LINUX_AUDIO_PLAYER} is required for Linux notifications."
			exit 1
		fi
		base64decode="base64 -d"
		;;
	darwin)
		if ! command -v terminal-notifier &> /dev/null
		then
			echo "terminal-notifier is required for macOS notifications."
			exit 1
		fi
		base64decode="base64 -D -"
		;;
	*)
		echo "This script is only supported on Linux and MacOS."
		exit 1
		;;
esac

function irc-notification {
	TYPE=$1
	MSG=$2

	if [ $OS_TYPE == "darwin" ]
	then
		terminal-notifier \
			-title IRC \
			-subtitle "$TYPE" \
			-message "$MSG" \
			-appIcon "$MACOS_ICON_PATH" \
			-contentImage "$MACOS_ICON_PATH" \
			-execute "$MACOS_ACTIVATION_CMD" \
			-activate "$MACOS_TERM_EMULATOR" \
			-sound default \
			-group IRC
	elif [ $OS_TYPE == "linux-gnu" ]
	then
		notify-send \
			-t 5000 \
			-u critical \
			--category IRC \
			--app-name=IRC \
			"$TYPE" \
			"$MSG"

		if [ -f "$LINUX_SOUND" ]
		then
			"$LINUX_AUDIO_PLAYER" "$LINUX_SOUND"
		fi
	fi
}

listener_ssh_cmd="nc -k -l -U /tmp/weechat.notify.sock"

if [[ $HOST != "localhost" ]]
then
	listener_ssh_cmd="ssh $HOST -- $listener_ssh_cmd"
fi

function get-irc-notifications {
	$listener_ssh_cmd | \
		while read type message; do
			irc-notification "$(echo -n $type | $base64decode)" "$(echo -n $message | $base64decode)"
		done
}

get-irc-notifications &

trap "pkill -f '$listener_ssh_cmd'" EXIT

if [[ $HOST == "localhost" ]]
then
	$WEECHAT_INVOCATION_CMD
else
	ssh -t "$HOST" -- "$WEECHAT_INVOCATION_CMD"
fi
