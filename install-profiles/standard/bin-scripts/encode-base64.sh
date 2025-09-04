#
# Description: Encodes a string into Base64 and writes the output to stdout; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
encode-base64: encode text into Base64
Usage: encode-base64 [--writeclip] [string|filespec]

Options:
--writeclip   Write output to the clipboard (default is to write to stdout)

encode-base64 will encode text into Base64 string and write the encoded string
to stdout, or to the clipboard if the --writeclip option is used. This script
will read data from a file if it's supplied as an argument. It will also accept
piped input. If neither a string nor a file argument nor piped input are
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

if [[ -n "$str" ]]; then
	if [[ -n "$write_to_clipboard" ]]; then
		echo "$str" | base64 | tr -d '\n' | clipcopy
	else
		echo "$str" | base64 | tr -d '\n'
	fi
else
	echo "No data provided to encode to Base64"
fi