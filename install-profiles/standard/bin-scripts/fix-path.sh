#
# Description: Echoes the absolute path for a path, including conversion to a Windows directory if running on Windows
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
fix-path: echo the absolute path for a path, including conversion to a Windows directory if running on Windows
Usage: fix-path [path]

fix-path will echo the absolute path for a path. On Windows, the path will be
resolved to a standard Windows filesystem path.
EOT
	exit 0
fi

source "${ROPERDOT_DIR}/source-scripts/abs-path"

f="$1"
if [[ -z "$f" ]]; then
	f="$(pwd)"
else
	f="$(abs-path "$f")"
fi
if [[ ! -e "$f" ]]; then
	echo "$1"
elif [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	if [[ "$ROPERDOT_OS_ENV" = "ubuntu" ]]; then
		source "${ROPERDOT_DIR}/source-scripts/win-env-functions"
		echo -E "$(wslwinpath "$f")"
	else
		echo -E "$(cygpath -w "$f")"
	fi
else
	echo "$f"
fi