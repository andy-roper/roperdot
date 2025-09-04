#
# Description: Extracts a compressed archive file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0  || "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
x: extract files from archives
Usage: x [-p <password>] [--verbose] <archive_file ...> [output_dir]

Options:
-p <password>  Specify the password to use when extracting the files
--verbose      Display the command used to extract the file

x will extract the files contained in one or more archives by calling
extract-archive. The decompression application used will be determined by what's
installed and the extension of the archives.

If the final argument is a directory, then the archive(s) will be extracted to
that directory.
EOT
#'
	exit 0
fi

declare -a args
while [[ $# -gt 0 ]]; do
	if [[ $# -eq 1 && -d "$1" ]]; then
		destdir=$1
	elif [[ "$1" = "-p" ]]; then
		shift
		[[ $# -eq 0 ]] && help
		password=$1
	elif [[ "$1" = "--verbose" ]]; then
		verbose=true
	else
		args+=( "$1" )
	fi
	shift
done

export destdir password verbose
extract-archive "${args[@]}"