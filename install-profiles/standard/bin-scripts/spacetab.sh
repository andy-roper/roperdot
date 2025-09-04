#
# Description: Converts between leading tabs and spaces in text; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
spacetab: convert leading spaces or tabs
Usage: spacetab [--stdout] [filespec]

Options:
--stdout   Write output to the stdout (default is to write to the clipboard)

spacetab will convert leading pairs of spaces to tabs or leading tabs to spaces
depending on the content passed to the script. The modified lines will be
written to the clipboard by default, or to stdout if the --stdout option is
used.

This script will read data from a file if it's supplied as an argument. It will
also accept piped input. If neither a file argument nor piped input are
provided, the script will read data from the clipboard.
EOT
#'
	exit 0
fi

if [[ "$1" = "--stdout" ]]; then
	write_to_stdout=true
	shift
fi

. "${ROPERDOT_DIR}/source-scripts/get-input"

if [[ -n "$str" ]]; then
	if [[ -n "$write_to_stdout" ]]; then
		echo "$str" | convert-spaces-to-tabs
	else
		echo "$str" | convert-spaces-to-tabs | clipcopy
	fi
else
	echo "No text provided to convert"
fi