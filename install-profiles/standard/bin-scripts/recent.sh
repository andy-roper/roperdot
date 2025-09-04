#
# Description: Lists recently modified files
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-?" ]]; then
	cat <<EOT
recent: list files changed recently
Usage: recent [-d <days> | -h <hours> | -m <minutes> | -t <timestamp>] [directory]

If a time range isn't specified, the default is to show files modified within
the last day.

If a directory isn't specified, the current directory will be searched.
EOT
	#'
	exit 0
fi

if [[ "$1" = "--" ]]; then
	shift
else
	case "$1" in
		-d)
			shift
			switch="-mtime"
			value="-$1"
			shift
			;;
		-h)
			shift
			switch="-mmin"
			value=$(($1 * -60))
			shift
			;;
		-m)
			shift
			switch="--mmin"
			value="-$1"
			shift
			;;
		-t)
			shift
			switch="-mmin"
			now=$(date -d "now" +%s)
			d=$(date -d "$1" +%s)
			value=$(( -1 * (now - d) / 60 ))
			shift
			;;
	esac
fi
if [[ -z "$switch" ]]; then
	switch="-mtime"
	value=-1
fi
[[ -n "$1" ]] && dir="$1" || dir="."
if [[ "$ROPERDOT_OS_ENV" = "darwin" && "$(command -v find)" = "/usr/bin/find" ]]; then
	find "$dir" "$switch" "$value" -ls
else
	find "$dir" "$switch" "$value" -printf "%M %12s %TY-%Tm-%Td %TH:%TM %p\n"
fi