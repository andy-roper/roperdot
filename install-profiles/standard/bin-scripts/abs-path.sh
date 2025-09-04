#
# Description: Returns the absolute path for a path
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
abs-path: return the absolute path for a path
Usage: abs-path <path>

abs-path will resolve instances of triple dots in a path to ../.. and then
call realpath on the path.
EOT
	exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/re-match"
. "${ROPERDOT_DIR}/source-scripts/realpath"

str="$1"
re="\.\.\."
while [[ "$str" =~ $re ]]; do
	str="${str//.../../..}"
done
realpath "$str"