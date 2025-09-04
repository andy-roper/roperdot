#
# Description: Encodes URL and write the output to stdout; accepts an argument, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
urlencode: encode a URL
Usage: urlencode [--writeclip] [string]

Options:
--writeclip  Write output to the clipboard (default is to write to stdout)

urlencode will encode a URL and write the formatted URL to stdout, or to the
clipboard if the --writeclip option is used. The script will also accept piped
input. If neither an argument nor piped input are provided, the script will
read data from the clipboard.
EOT
#'
	exit 0
fi

if [[ "$1" = "--writeclip" ]]; then
	writeclip=1
	shift
fi
. "${ROPERDOT_DIR}/source-scripts/get-input"

if command -v python >/dev/null 2>&1; then
	encoded=$(python3 -c "import sys; from urllib.parse import quote_plus; print(quote_plus(sys.argv[1]))" "$str")
else
	strlen=${#str}
	encoded=""
	for (( pos = 0; pos < strlen; pos++ )); do
		c=${str:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9] )
				o="${c}"
				;;
			* )
				printf -v o '%%%02x' "'$c"
				;;
		esac
		encoded+="${o}"
	done
fi
if [[ -n "$writeclip" ]]; then
	echo "$encoded" | clipcopy
else
	echo "$encoded"
fi