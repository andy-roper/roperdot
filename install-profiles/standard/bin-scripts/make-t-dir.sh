#
# Description: Used by t to create a temporary directory
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
make-t-dir: create a temporary directory
Usage: make-t-dir

This script will create a directory like t, t2, etc. within the current
directory and then print the name of the directory.

It will start by trying to create "t". If that directory exists, it will next
try "t2", then "t3", etc. until either a new name is found or a t directory
is found that contains no files.
EOT
	exit 0
fi

dirname=t
i=1
while true; do
	if [[ ! -e $dirname ]]; then
		mkdir $dirname
		break
	fi
	if [[ -d $dirname ]]; then
		list=$(ls $dirname)
		[[ -z "$list" ]] && break
	fi
	(( ++i ))
	dirname="t$i"
done
echo $dirname
