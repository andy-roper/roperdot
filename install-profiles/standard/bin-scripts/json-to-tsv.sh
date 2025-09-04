#
# Description: Converts JSON to tab-delimited data; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
json-to-tsv: convert array of JSON data to TSV
Usage: json-to-tsv [--writeclip] [filespec]

Options:
--writeclip  Write output to the clipboard (default is to write to stdout)

json-to-tsv will convert an array of JSON data to tab-delimited values. The
output will be written to stdout, or to the clipboard if the --writeclip option
is used. This script will read data from a file if it's supplied as an
argument. It will also accept piped input. If neither a file argument nor piped
input are provided, the script will read data from the clipboard.
EOT
#'
	exit 0
fi

if [[ "$1" = "--writeclip" ]]; then
	write_to_clipboard=true
	shift
fi

. "${ROPERDOT_DIR}/source-scripts/get-input"
key_list=$(echo $str | jq -r '.[0] | keys')
field_names=".$(echo ${key_list:3:-1} | tr -d '"' | sed -e 's/ / ./g')"
#'
if [[ -n "$write_to_clipboard" ]]; then
	echo "$str" | jq -r "$key_list, (.[] | [$field_names]) | @tsv" | clipcopy
else
	echo "$str" | jq -r "$key_list, (.[] | [$field_names]) | @tsv"
fi