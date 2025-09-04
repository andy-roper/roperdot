#
# Description: Saves clipboard data to a file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
clip2file: paste from the clipboard to a file
Usage: clip2file <filespec>
       clip2file > <filespec>

clip2file will paste the contents of the clipboard to the designated file.
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

if [[ -t 1 ]]; then
	[[ $# -eq 0 ]] && help
	clippaste > "$1"
else
	clippaste
fi