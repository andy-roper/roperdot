#
# Description: Generates a SHA1 checksum for binary data
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
sha1bin: generate a sha1sum for binary data
Usage: sha1bin [--writeclip] [string|filespec]

Options:
--writeclip   Write output to the clipboard (default is to write to stdout)

sha1bin will generate a SHA1 checksum for data and write the checksum to
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
		sha1sum -b "$input_file" | clipcopy
	else
		sha1sum -b "$input_file"
	fi
else
	if [[ -n "$str" ]]; then
		if [[ -n "$write_to_clipboard" ]]; then
			echo "$str" | sha1sum -b | clipcopy
		else
			echo "$str" | sha1sum -b
		fi
	else
		echo "No data provided from which to generate a checksum."
	fi
fi