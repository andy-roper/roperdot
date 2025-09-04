#
# Description: Converts JSON to tab-delimited data and open it in a spreadsheet application; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
json-to-spreadsheet: convert a JSON array to TSV and open with spreadsheet app
Usage: json-to-spreadsheet [filespec]

json-to-spreadsheet will convert an array of JSON data to tab-delimited values
and open the result in a spreadsheet application. This script will read data
from a file if it's supplied as an argument. It will also accept piped input.
If neither a file argument nor piped input are provided, the script will read
data from the clipboard.
EOT
#'
	exit 0
fi

tsv_file=$(mktemp)
rm "$tsv_file"
tsv_file=${tsv_file}.tsv
. "${ROPERDOT_DIR}/source-scripts/get-input"
key_list=$(echo $str | jq -r '.[0] | keys')
field_names=".$(echo "${key_list:3:-1}" | tr -d '"' | sed -e 's/ / ./g')"
#'
echo "$str" | jq -r "$key_list, (.[] | [$field_names]) | @tsv" > "$tsv_file"
spreadsheet-app "$tsv_file" >/dev/null 2>&1 &
