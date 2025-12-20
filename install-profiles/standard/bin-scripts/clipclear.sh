#
# Description: Clear the clipboard
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help() {
	cat <<EOT
clipclear: clear the clipboard
Usage: clipclear
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	echo -n | clip.exe
elif [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	echo -n | pbcopy
else
	# Linux/X11
	if command -v xclip &>/dev/null; then
		echo -n | xclip -selection clipboard
	elif command -v xsel &>/dev/null; then
		echo -n | xsel --clipboard --clear
	elif command -v wl-copy &>/dev/null; then
		# Wayland
		wl-copy --clear
	else
		echo "Error: No clipboard utility found" >&2
		exit 1
	fi
fi