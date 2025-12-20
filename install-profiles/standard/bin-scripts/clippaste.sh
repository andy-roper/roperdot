#
# Description: Echoes data contained in the clipboard
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -gt 0 ]]; then
	cat <<EOT
clippaste: paste data from the clipboard
Usage: clippaste
EOT
	exit 0
fi

if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	pbpaste
elif [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	powershell.exe -command 'Get-Clipboard' | tr -d '\r'
else
	if command -v xclip &>/dev/null; then
		xclip -selection clipboard -o
	elif command -v xsel &>/dev/null; then
		xsel --clipboard --output
	elif command -v wl-copy &>/dev/null; then
		wl-paste
	else
		echo "Error: No clipboard utility found" >&2
		exit 1
	fi
fi