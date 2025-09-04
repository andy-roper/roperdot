#
# Description: Generates a SHA256 checksum for text data
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
sha1: generate a sha256sum for text data
Usage: sha256 [--writeclip] [string|filespec]

Options:
--writeclip   Write output to the clipboard (default is to write to stdout)

sha256 will generate a SHA256 checksum for data and write the checksum to
stdout, or to the clipboard if the --writeclip option is used. This script will
read data from a file if it's supplied as an argument. It will also accept
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

check_for_input_file=true
. "${ROPERDOT_DIR}/source-scripts/get-input"

if [[ -n "$input_file" ]]; then
	if [[ -n "$write_to_clipboard" ]]; then
		sha256sum "$input_file" | clipcopy
	else
		sha256sum "$input_file"
	fi
else
	if [[ -n "$str" ]]; then
		if [[ -n "$write_to_clipboard" ]]; then
			echo "$str" | sha256sum | clipcopy
		else
			echo "$str" | sha256sum
		fi
	else
		echo "No data provided from which to generate a checksum."
	fi
fi