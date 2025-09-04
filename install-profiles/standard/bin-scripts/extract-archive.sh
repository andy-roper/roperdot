#
# Description: Called by the x, xd and xdd scripts to extract files from archives
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
extract-archive: extract a compressed archive file
Usage: extract-archive <file> [...]

extract-archive will extract the files contained in one or more archives. The
decompression application used will be determined by what's installed and the
extension of the archives.

The script's normal usage is to be called by x, xd or xdd. It accepts several
environment variables that will affect its operation:

destdir    If defined, files will be extracted to the specified directory.
disable7z  If defined, usage of 7z to extract files will be suppressed.
password   If defined, the password it contains will be used when extracting
           the archives.
verbose    If defined, the command used to extract the files will be printed.
EOT
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

# Enable extended globbing and disable case-sensitive matching
[[ $current_shell = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

. "${ROPERDOT_DIR}/source-scripts/abs-path"
. "${ROPERDOT_DIR}/source-scripts/filename-base"
. "${ROPERDOT_DIR}/source-scripts/sevenz"

please_install () {
	echo "Please install $1 to extract this archive."
	exit 1
}

# disable7z=1

verbose=1

re="\.(rar|cbr)$"
[[ -z "$disable7z" ]] && command -v sevenz >/dev/null 2>&1 && [[ -e "/usr/lib/p7zip/Codecs/Rar.so" ]] && sevenz_rar_support=true
if command -v gtar >/dev/null 2>&1; then
	tarcmd=gtar
	tarcmd2=xaf
else
	tarcmd=tar
	tarcmd2=-xf
fi
for f; do
	if [[ "$f" =~ $re && -z "$sevenz_rar_support" ]]; then
		unset pass_sw
		if command -v rar >/dev/null 2>&1; then
			arcbin=rar
			command=e
		elif command -v unrar >/dev/null 2>&1; then
			arcbin=unrar
			command=x
		else
			please_install unrar
		fi
		[[ -n "$password" ]] && pass_sw=-p$password
		if [[ -z "$destdir" ]]; then
			[[ -n "$verbose" ]] && echo $arcbin $command $pass_sw "\"$f\""
			$arcbin $command "$pass_sw" "$f"
		else
			realpath=$(abs-path "$f")
			[[ -n "$verbose" ]] && echo pushd "$destdir"
			pushd "$destdir" >&/dev/null || exit
			[[ -n "$verbose" ]] && echo $arcbin $command "$pass_sw" "\"$realpath\""
			$arcbin $command "$pass_sw" "$realpath"
			[[ -n "$verbose" ]] && echo popd
			popd >&/dev/null || exit
		fi
	elif [[ -z "$disable7z" ]] && command -v sevenz >/dev/null 2>&1; then
		sevenz_bin=$(command -v sevenz)
		case "$f" in
			*.tar)
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo tar xaf "\"$f\""
					$tarcmd $tarcmd2 "$f"
				else
					[[ -n "$verbose" ]] && echo tar xaf "\"$f\"" -C "\"$destdir\""
					$tarcmd $tarcmd2 "$f" -C "$destdir"
				fi			
				;;
			*.@(tgz|tlz|txz|tb2|tbz|tbz2|taz|tar|tar.+([a-z0-9])|deb) )
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo "$sevenz_bin" x -p"$password" -so "\"$f\"" "|" tar xf -
					sevenz x -p"$password" -so "$f" | tar xf -
				else
					[[ -n "$verbose" ]] && echo "$sevenz_bin" x -p"$password" -so "\"$f\"" "|" tar xf - -C "\"$destdir\""
					sevenz x -p"$password" -so "$f" | tar xf - -C "$destdir"
				fi
				;;
			*.@(tar|zip|rar|gz|7z|Z|bz2|xz|cbz|cb7|cbt|jar|ear|war|lha|lzma) )
				good_archive=true
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo "$sevenz_bin" x -p"$password" "\"$f\""
					sevenz x -p"$password" "$f"
				else
					[[ -n "$verbose" ]] && echo "$sevenz_bin" x -p"$password" -o"\"$destdir\"" "\"$f\""
					sevenz x -p"$password" -o"$destdir" "$f"
				fi
				# Had to add continue because the step was inexplicably falling through to the default
				continue
				;;
			*)
				echo "$f is not a recognized archive type"
				;;
		esac
	else
		case "$f" in
			*.@(zip|cbz|jar|war|ear) )
				! command -v unzip >/dev/null 2>&1 && please_install unzip
				[[ -n "$password" ]] && pass_sw=-P$password
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo unzip "$pass_sw" "\"$f\""
					unzip "$pass_sw" "$f"
				else
					[[ -n "$verbose" ]] && echo unzip "$pass_sw" "\"$f\"" -d "\"$destdir\""
					unzip "$pass_sw" "$f" -d "$destdir"
				fi
				;;
			*.@(tar|tar.+([A-Za-z0-9])|tbz|tb2|tbz2|tgz|txz|tlz|taz|tz|cbt) )
				case "$ext" in
					tar.Z | taz | tz )
						! command -v uncompress >/dev/null 2>&1 && help please_install compress
						;;
					tar.gz | tgz )
						! command -v gzip >/dev/null 2>&1 && help please_install gzip
						;;
					tar.bz2 | tbz | tbz2 )
						! command -v bzip2 >/dev/null 2>&1 && help please_install bzip2
						;;
					tar.xz | txz )
						! command -v xz >/dev/null 2>&1 && help please_install xz
						;;
					tar.lzma | tlz )
						! command -v xz >/dev/null 2>&1 && ! command -v lzma >/dev/null 2>&1 && please_install "xz or lzma"
						;;
				esac
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo $tarcmd "\"$f\""
					$tarcmd $tarcmd2 "$f"
				else
					[[ -n "$verbose" ]] && echo $tarcmd "\"$f\"" -C "\"$destdir\""
					$tarcmd $tarcmd2 "$f" -C "$destdir"
				fi
				;;
			*.lha )
				if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
					! command -v lha >/dev/null 2>&1 && please_install lha
					lha_app=lha
				else
					! command -v lharc >/dev/null 2>&1 && please_install lharc
					lha_app=lharc
				fi
				if [[ -z "$destdir" ]]; then
					$lha_app x "$f"
				else
					$lha_app x -w "$destdir" "$f"
				fi
				;;
			*.@(gz|Z|bz2) )
				filebase=$(filename_base "$f")
				if [[ -z "$destdir" ]]; then
					[[ -n "$verbose" ]] && echo gzcat "\"$f\"" ">" "\"$filebase\""
					gzcat "$f" > "$filebase"
				else
					[[ -n "$verbose" ]] && echo gzcat "\"$f\"" ">" "\"$destdir/$filebase\""
					gzcat "$f" > "$destdir/$filebase"
				fi
				;;
			*.deb )
				! command -v dpkg >/dev/null 2>&1 && please_install dpkg
				if [[ -z "$destdir" ]]; then
					dpkg -x "$f" "$destdir"
				else
					dpkg -x "$f" .
				fi
				;;
			*)
				echo "$f is not a recognized archive type"
				;;
		esac
	fi
done