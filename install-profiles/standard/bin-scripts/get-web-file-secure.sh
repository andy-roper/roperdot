#
# Description: Gets a web file using wget or curl with proper SSL certificate verification
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
get-web-file-secure: download a file with proper SSL certificate verification
Usage: get-web-file-secure <url> [filename]

get-web-file-secure will download a file from a url using proper SSL certificate
verification. If filename is provided, the file will be downloaded with that name;
otherwise the filename will be derived from the url.

get-web-file-secure will use one of these applications to download the file depending
on what is installed: wget or curl.
EOT
	exit 0
fi

url=$1
file=$2
[[ -z "$file" ]] && file=${url##*/}

# Set up certificate environment variables if ca-certificates exists
if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
	export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
	export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
	export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
fi

# Try curl first (better TLS support), then wget as fallback
if command -v curl >/dev/null 2>&1; then
	# -L follows redirects
	if ! curl -fsSL "$url" -o "$file" 2>&1; then
		echo "curl failed to download $url"
		exit 1
	fi
elif command -v wget >/dev/null 2>&1; then
	# Force TLS 1.2 or higher, follow redirects
	if ! wget --secure-protocol=TLSv1_2 --max-redirect=5 -O "$file" "$url" 2>&1; then
		echo "wget failed to download $url"
		exit 1
	fi
else
	echo "No applications found for retrieving web files (need wget or curl)"
	exit 1
fi
