#
# Description: Prints the contents of a web file using wget, curl or lynx
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
print-web-file: print a file from a url
Usage: print-web-file <url>

print-web-file will download and print a file from a url.

print-web-file will use one of these applications to download the file
depending on what is installed: wget, curl or lynx.
EOT
	exit 0
fi

url=$1
if command -v wget >/dev/null 2>&1; then
	wget -q -O - "$url"
elif command -v curl >/dev/null 2>&1; then
	curl -fsSL "$url"
elif command -v lynx >/dev/null 2>&1; then
	lynx -source "$url"
else
	echo "No applications found for retrieving web files"
	exit 1
fi