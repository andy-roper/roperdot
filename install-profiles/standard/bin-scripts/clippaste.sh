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
elif command -v xclip >/dev/null 2>&1; then
	xclip -o
else
	echo "xclip is not installed. Please install it."
fi