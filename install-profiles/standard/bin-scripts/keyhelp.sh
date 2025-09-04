#
# Description: Shows keyboard shortcut information
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
key_help_file="${ROPERDOT_DIR}/${ROPERDOT_OS_TYPE}-shortcuts.txt"

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
keyhelp: show keyboard shortcut information
Usage: keyhelp [pattern]

Prints the contents of $key_help_file.
If a pattern is provided, only those lines that match will be shown.
EOT
    exit 0
fi

if [[ -f "$key_help_file" ]]; then
	grep -i "$1" < "$key_help_file"
else
	echo "Keyboard shortcut file $key_help_file not found."
fi