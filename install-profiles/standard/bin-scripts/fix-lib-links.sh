#
# Description: Fixes lib links in ~/.local/usr/lib64
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
fix-lib-links: fixes bad links in ~/.local/usr/lib64
Usage: fix-lib-links
EOT
	exit 0
fi
[[ -d "$HOME/.local/usr/lib64" ]] && find "$HOME/.local/usr/lib64" -xtype l -exec $ROPERDOT_CURRENT_SHELL -c 'fix-local-usr-lib64-link "$0"' {} \;
