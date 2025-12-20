#
# Description: Copies a file to the clipboard. This script also accepts piped data.
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help() {
	cat <<EOT
clipcopy: copy data to the clipboard
Usage: clipcopy [filespec]

clipcopy copies data to the clipboard. The script also accepts piped data.
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

if [[ $# -ge 1 ]]; then
	if [[ -f "$1" ]]; then
		input="$1"
	else
		help
	fi
elif [[ -t 1 ]]; then
	input="-"
else
	help
fi

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	clip_app=clip.exe
elif [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	clip_app=pbcopy
else
	# Linux - check for available clipboard utilities
	if command -v xclip &>/dev/null; then
		clip_app="xclip -selection clipboard"
	elif command -v xsel &>/dev/null; then
		clip_app="xsel --clipboard --input"
	elif command -v wl-copy &>/dev/null; then
		clip_app="wl-copy"
	else
		echo "Error: No clipboard utility found" >&2
		exit 1
	fi
fi
# if [[ ("$ROPERDOT_CURRENT_SHELL" = "bash" || "$ROPERDOT_OS_ENV" = darwin) && "$input" = "-" ]]; then
if [[ "$input" = "-" ]]; then
	$clip_app < /dev/stdin
else
	$clip_app < $input
fi