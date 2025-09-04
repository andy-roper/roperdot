#
# Description: Extracts all archives in the current directory into subdirectories with the same base filename as each archive
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
xdd: extract all archives in the current directory into directories
Usage: xdd [-p <password>] [--verbose]

Options:
-p <password>  Specify the password to use when extracting the files
--verbose      Display the command used to extract the file

xdd will extract each file in the current director by calling extract-archive.
Each archive will be extracted into a directory whose name is the base name of
that archive. The decompression application used will be determined by what's
installed and the extension of the archives.
EOT
#'
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

[[ $current_shell = bash ]] && shopt -s extglob || setopt ksh_glob

. "${ROPERDOT_DIR}/source-scripts/filename-base"

re="\.(7z|zip|Z|tar|tgz|gz|bz2|cbz|cbr|rar|jar|war|ear|txz|tbz|tb2|tbz2|xz|lzma|tlz)$"

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

for f in * ; do
	if [[ ! -d "$f" ]]; then
		if [[ "$f" =~ $re ]]; then
			destdir=$(filename_base "$f")
			if [[ -a $destdir ]]; then
				if [[ ! -d $destdir ]]; then
					echo "Error: $destdir exists and is not a directory"
					echo "Aborting"
					exit 0
				fi
			else
				mkdir "$destdir"
			fi
			export password
			export verbose
			export destdir
			extract-archive "$f"
		fi
	fi
done
