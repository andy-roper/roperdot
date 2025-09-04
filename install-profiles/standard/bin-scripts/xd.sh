#
# Description: Extracts an archive into a subdirectory with the same base filename as the archive
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
xd: extract archive into a directory named as the base name of the archive
Usage: xd [-p <password>] [--verbose] <archive_file ...>

Options:
-p <password>  Specify the password to use when extracting the files
--verbose      Display the command used to extract the file

xd will extract the files contained in one or more archives by calling
extract-archive. Each archive will be extracted into a directory whose name is
the base name of that archive. The decompression application used will be
determined by what's installed and the extension of the archives.
EOT
#'
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

[[ $current_shell = bash ]] && shopt -s extglob || setopt ksh_glob

. "${ROPERDOT_DIR}/source-scripts/filename-base"

while [[ $# -gt 0 ]]; do
	if [[ "$1" = "-p" ]]; then
		shift
		[[ $# -eq 0 ]] && help
		password=$1
	elif [[ "$1" = "--verbose" ]]; then
		verbose=1
	else
		break
	fi
	shift
done

for arg in "$@" ; do
	destdir=$(filename_base "$arg")
	if [[ -a $destdir ]]; then
		if [[ ! -d $destdir ]]; then
			echo "Error: $destdir exists and is not a directory"
			echo "Aborting"
			exit 0
		fi
	else
		mkdir "$destdir"
	fi
	export destdir
	export password
	export verbose
	extract-archive "$arg"
done
