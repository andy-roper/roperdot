#
# Description: Gets a web file using wget, curl or lynx
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
get-web-file: download a file
Usage: get-web-file <url> [filename]

get-web-file will download a file from a url. If filename is provided, the file
will be downloaded with that name; otherwise the filename will be derived from
the url.

get-web-file will use one of these applications to download the file depending
on what is installed: wget, curl or lynx.
EOT
	exit 0
fi

url=$1
file=$2
[[ -z "$file" ]] && file=${url##*/}

user_agent="Mozilla/5.0 (compatible; wget/curl)"

if command -v wget >/dev/null 2>&1; then
	wget -q --no-check-certificate --max-redirect=10 --user-agent="$user_agent" -O "$file" "$url"
elif command -v curl >/dev/null 2>&1; then
	curl -fsSL --insecure -A "$user_agent" "$url" -o "$file"
elif command -v lynx >/dev/null 2>&1; then
	lynx -source -nosslcertcheck -useragent="$user_agent" "$url" > "$file"
else
	echo "No applications found for retrieving web files"
	exit 1
fi