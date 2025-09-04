#
# Description: Converts JSON to a quoted string; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
json-to-string: convert JSON to a quoted string
Usage: json-to-string [--writeclip] [string|filespec]

Options:
--writeclip   Write output to the clipboard (default is to write to stdout)

json-to-string will convert JSON to a quoted string and write the output to
stdout, or to the clipboard if the --writeclip option is used. This script will
read data from a file if it's supplied as an argument. It will also accept
piped input. If neither a string not a file argument nor piped input are
provided, the script will read data from the clipboard. 
EOT
	#'
	exit 0
fi

if [[ "$1" = "--writeclip" ]]; then
	write_to_clipboard=true
	shift
fi

. "${ROPERDOT_DIR}/source-scripts/get-input"

# Remove tabs and linefeeds
str="$(echo $str | tr -d '\n' | tr -d '\r' | tr -d '\t')"

if [[ -n "$str" ]]; then
	if [[ -n "$write_to_clipboard" ]]; then
		echo "\"$str\"" | clipcopy
	else
		echo "\$'$str'"
	fi
else
	echo "No JSON provided to format"
fi