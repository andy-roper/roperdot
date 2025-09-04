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
	clip_app=xclip
fi
# if [[ ("$ROPERDOT_CURRENT_SHELL" = "bash" || "$ROPERDOT_OS_ENV" = darwin) && "$input" = "-" ]]; then
if [[ "$input" = "-" ]]; then
	$clip_app < /dev/stdin
else
	$clip_app < $input
fi