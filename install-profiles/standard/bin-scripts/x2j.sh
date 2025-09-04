#
# Description: Converts XML to JSON
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
x2j: convert XML to JSON
Usage: x2j [--writeclip] [string|filespec]

Options:
--writeclip   Write output to the clipboard (default is to write to stdout)

x2j will convert XML to JSON and write the output to stdout, or to the
clipboard if the --writeclip option is used. This script will read data from a
file if it's supplied as an argument. It will also accept piped input. If
neither a string nor a file argument nor piped input are provided, the script
will read data from the clipboard.
EOT
	#'
	exit 0
fi

if [[ "$1" = "--writeclip" ]]; then
	write_to_clipboard=true
	shift
fi

. "${ROPERDOT_DIR}/source-scripts/get-input"

if [[ -n "$str" ]]; then
	if [[ -n "$write_to_clipboard" ]]; then
		echo "$str" | xml2json | clipcopy
	else
		echo "$str" | xml2json
	fi
else
	echo "No XML provided to convert to JSON"
fi