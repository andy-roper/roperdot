#
# Description: Decodes an encoded URL and write the output to stdout; accepts an argument, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
urldecode: decode an encoded URL
Usage: urldecode [--writeclip] [string]

Options:
--writeclip  Write output to the clipboard (default is to write to stdout)

urldecode will decode an encoded URL and write the formatted URL to stdout, or
to the clipboard if the --writeclip option is used. The script will also accept
piped input. If neither a string nor a file argument nor piped input are
provided, the script will read data from the clipboard.
EOT
#'
	exit 0
fi

if [[ "$1" = "--writeclip" ]]; then
	writeclip=1
	shift
fi
. "${ROPERDOT_DIR}/source-scripts/get-input"

if command -v python3 >/dev/null 2>&1; then
	decoded=$(python3 -c "import sys; from urllib.parse import unquote_plus; print(unquote_plus(sys.argv[1]))" "$str")
else
	url_encoded="${str//+/ }"
	decoded=$(printf '%b' "${url_encoded//%/\\x}")
fi
if [[ -n "$writeclip" ]]; then
	echo "$decoded" | clipcopy
else
	echo "$decoded"
fi