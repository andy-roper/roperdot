#
# Description: Creates a symlink in your home directory to a file in the roperdot directory
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
fix-link: create a symlink in your home directory to a file in the roperdot directory
Usage: fix-link <filespec> [true]
EOT
	exit 0
fi
link_file=$1
link_file_full="$HOME/$link_file"
admin_required=$2
if [[ -L "$link_file_full" && ! -e "$link_file_full" ]]; then
	filename="$(readlink -m "$link_file_full")"
	# Leave the file alone if it links to a file outside the roperdot directory
	if [[ "$filename" =~ "roperdot" ]]; then
		filename="${filename##*roperdot/}"
		echo "Fixing link for $link_file"
		ln -sf "${ROPERDOT_DIR}/${filename}" "$link_file_full"
	fi
fi