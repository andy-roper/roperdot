#
# Description: Called by v to list the contents of a compressed archive file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# https://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script

if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
list-archive: list the contents of a compressed archive file
Usage: list-archive <file>

list-archive will list the contents of an archive file. The decompression
application used will be determined by what applications are installed and the
extension of the archive.

The script's normal usage is to be called by v. It accepts several environment
variables that will affect its operation:

If the disable7z environment variable is defined, usage of 7z to list the
content of archives will be suppressed. Otherwise, it will use the command
referenced in the sevenz alias (if it's defined).
EOT
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

# Enable extended globbing and disable case-sensitive matching
[[ $current_shell = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

. "${ROPERDOT_DIR}/source-scripts/sevenz"

please_install () {
	echo "Please install $1 to view this archive."
	exit 1
}

temp_file=$(mktemp XXXXXX.txt)
re1="\.(tar\.Z|tar\.gz|tgz|taz|tz)$"
re2="\.(tar\.bz2|tbz|tb2|tbz2|tar\.xz|txz|tar.lzma|tlz)$"
if [[ "$1" =~ $re1 ]]; then
	! command -v compress >/dev/null 2>&1 && ! command -v gzip >/dev/null 2>&1 && please_install "compress or gzip"
	tar ztvf "$1" > "$temp_file"
elif [[ "$1" =~ $re2 ]]; then
	case "$ext" in
		tar.gz | tgz )
			! command -v gzip >/dev/null 2>&1 && please_install gzip
			;;
		tar.bz2 | tbz | tbz2 | tb2 )
			! command -v bzip2 >/dev/null 2>&1 && please_install bzip2
			;;
		tar.xz | txz )
			! command -v xz >/dev/null 2>&1 && please_install xz
			;;
		tar.lzma | tlz )
			! command -v xz >/dev/null 2>&1 && ! command -v lzma >/dev/null 2>&1 && please_install "xz or lzma"
			;;
	esac
	tar tvf "$1" > "$temp_file"
elif command -v sevenz >/dev/null 2>&1; then
	sevenz l "$1" > "$temp_file"
else
	case "$1" in
		*.@(zip|cbz|jar|war|ear) )
			! command -v unzip >/dev/null 2>&1 && please_install unzip
			unzip -l "$1" > "$temp_file"
			;;
		*.@(tar|cbt) )
			tar tvf "$1" > "$temp_file"
			;;
		*.@(rar|cbr|r00) )
			! command -v unrar >/dev/null 2>&1 && please_install unrar
			unrar l "$1" > "$temp_file"
			;;
		*.lha )
			if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
				! command -v lha >/dev/null 2>&1 && please_install lha
				lha v "$1" > "$temp_file"
			else
				! command -v lharc >/dev/null 2>&1 && please_install lharc
				lharc v "$1" > "$temp_file"
			fi
			;;
		* )
			echo The list-archive script doesn't have a command defined for this extension.
			#'
			exit 1
			;;
	esac
fi
show-file "$temp_file"
rm "$temp_file"