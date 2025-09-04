#
# Description: Fixes lib link for entry in ~/.local/usr/lib64
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
fix-local-usr-lib64-link: fixes a bad link in ~/.local/usr/lib64
Usage: fix-local-usr-lib64-link

Called by fix-lib-links to fix bad links in ~/.local/usr/lib64.
EOT
	exit 0
fi
target="$(readlink -f "$1")"
target="${target##*/}"
if [[ -e "/usr/lib64/$target" ]]; then
	rm -f "$1"
	ln -s "/usr/lib64/$target" "$1"
fi
