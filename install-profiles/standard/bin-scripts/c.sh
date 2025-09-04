#
# Description: Compresses files. The default archive extension you selected during the install will be used if you no extension is specified for the target file. Otherwise, the compression used will match the target archive extension. If no files are specified to compress, all of the files in the current directory will be stored in the archive.
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	if [[ $# -gt 0 ]]; then
		echo "$*"
		echo
	fi
	cat <<EOT
c: compress files into an archive file
Usage: c [-r] [-p <password>] [--verbose] <archive> [file ...]

Options:
-r              Recurse subdirectories
-p <password>   Specify the password to use when compressing the archive
--verbose       Display the command used to compress the file

If no file is specified, all files in the current directory will be stored in
the archive (assuming the compressor being used accepts wildcards).

If the destination archive has a recognized archive extension it will be
created as a file of that type. Otherwise the archive will be created using
the default archive type that is stored in the ROPERDOT_ARC_TYPE environment variable.

Valid values for the ROPERDOT_ARC_TYPE variable are:

zip, 7z, gz, tar.gz, tgz, rar, bz2, tar.bz2, tbz, tbz2, tar.Z, tar.7z, xz,
tar.xz, txz, lzma, tar.lzma, tlz, tar.7z, and lha.

If the ROPERDOT_ARC_TYPE is gz, bz2, Z, xz, or lzma the files will be compressed using
tar first.

Current ROPERDOT_ARC_TYPE value: $ROPERDOT_ARC_TYPE
EOT
	exit 0
}

[[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

. "${ROPERDOT_DIR}/source-scripts/re-match"
. "${ROPERDOT_DIR}/source-scripts/sevenz"

please_install () {
	help "Please install $1 to create this archive."
}

bad_switch () {
	help "Error: $1 doesn't support a $2 switch."
}

declare -a args
declare -a switches
while [[ $# -gt 0 ]]; do
	if [[ "$1" = "-p" ]]; then
		shift
		[[ $# -eq 0 ]] && help
		password="$1"
	elif [[ "$1" = "-r" ]]; then
		recursing=1
	elif [[ "$1" = "--verbose" ]]; then
		verbose=1
	elif [[ "$1" =~ ^- && ! -e "$1" ]]; then
		switches+=( "$1" )
	else
		if [[ -z "$archive" ]]; then
			archive="$1"
		else
			args+=( "$1" )
		fi
	fi
	shift
done
[[ -z "$archive" ]] && help

[[ "$current_shell" = bash ]] && shopt -s extglob || setopt ksh_glob

re_supported="\.(tar.gz|tar.bz2|tar.Z|tar.7z|tar.xz|tar.lzma|zip|cbz|tar|taz|tz|tgz|tbz|tbz2|txz|tlz|7z|rar|cbr|iso)$"
re_default="^(tar.gz|tar.bz2|tar.Z|tar.7z|tar.xz|tar.lzma|zip|tar|tgz|gz|bz2|tbz2|tbz|txz|xz|lzma|tlz|7z|rar)$"
#if [[ "$archive" =~ $re_supported ]]; then
#	ext=${BASH_REMATCH[1]}
if re_match "$archive" $re_supported; then
	ext=${re_match[1]}
else
	[[ ! "$ROPERDOT_ARC_TYPE" =~ $re_default ]] && help "Error: invalid value \"$ROPERDOT_ARC_TYPE\" in environment variable ROPERDOT_ARC_TYPE"
	re="^(gz|bz2|Z|xz|lzma)$"
	[[ "$ROPERDOT_ARC_TYPE" =~ $re ]] && ROPERDOT_ARC_TYPE="tar.$ROPERDOT_ARC_TYPE"
	ext=$ROPERDOT_ARC_TYPE
	archive="$archive.$ROPERDOT_ARC_TYPE"
fi
[[ ${#args[@]} = 0 ]] && args+=( "*" )

if [[ "$ext" = "tar.7z" ]]; then
	! command -v sevenz >/dev/null 2>&1 && please_install 7z
	[[ -n "$recursing" ]] && bad_switch tar recursion
	[[ -n "$password" ]] && switches+=( -p"$password" )
	[[ -n "$verbose" ]] && echo "tar cf - \""${args[@]}"\" | sevenz a -si ${switches[@]} \"$archive\""
	tar cf - "${args[@]}" | sevenz a -si ${switches[@]} "$archive"
else
	if [[ "$ext" = "rar" || "$ext" = "cbr" ]]; then
		! command -v rar >/dev/null 2>&1 && please_install rar
		command=rar
	elif [[ "$ext" = "zip" || "$ext" = "cbz" || "$ext" = "7z" ]]; then
		command=sevenz
	fi
	
	if [[ -n "$command" ]]; then
		[[ -n "$password" ]] && switches+=( -p"$password" )
		[[ -n "$recursing" && "$command" = "rar" ]] && switches+=( -r )
#		echo "Calling command $command"
		[[ -n "$verbose" ]] && echo "$command a ${switches[@]} \"$archive\" \""${args[@]}"\""
		$command a "${switches[@]}" "$archive" "${args[@]}"
	else
		case "$ext" in
			7z )
				please_install 7z
				;;
			zip | cbz )
				! command -v zip >/dev/null 2>&1 && please_install zip
				[[ -n "$recursing" ]] && switches+=( -r )
				[[ -n "$password" ]] && switches+=( -P ) && switches+=( "$password" )
				[[ -n "$verbose" ]] && echo "zip ${switches[@]} \"$archive\" \""${args[@]}"\""
				zip "${switches[@]}" "$archive" "${args[@]}"
				;;
			@(tar|tar.+([A-Za-z0-9])|taz|tz|tgz|tbz|tbz2|tb2|txz|tlz) )
				[[ -n "$recursing" ]] && bad_switch tar recursion
				[[ -n "$password" ]] && bad_switch tar password
				if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
					if command -v gtar >/dev/null 2>&1; then
						tarcmd=gtar
						tarcmd2=cavf
					elif tar --version | grep bsdtar >/dev/null; then
						bsdtar=true
					else
						tarcmd=tar
						tarcmd2=cavf
					fi
				else
					tarcmd=tar
					tarcmd2=cavf
				fi
				if [[ -n "$bsdtar" ]]; then
					case "$ext" in
						tar.Z | taz | tz )
							! command -v compress >/dev/null 2>&1 && please_install compress
							arccmd=compress
							;;
						tar.gz | tgz )
							! command -v gzip >/dev/null 2>&1 && please_install gzip
							arccmd=gzip
							;;
						tar.bz2 | tbz | tb2 | tbz2 )
							! command -v bzip2 >/dev/null 2>&1 && please_install bzip2
							arccmd=bzip2
							;;
						tar.xz | txz )
							! command -v xz >/dev/null 2>&1 && please_install xz
							arccmd=xz
							;;
						tar.lzma | tlz )
							if command -v xz >/dev/null 2>&1; then
								arccmd=xz
							elif command -v lzma >/dev/null 2>&1; then
								arccmd=lzma
							else
								please_install "xz or lzma"
							fi
							;;
					esac
					if [[ -n "$arccmd" ]]; then
						[[ -n "$verbose" ]] && echo "tar cf - ${args[@]} | $arccmd > \"$archive\""
						tar cf - "${args[@]}" | $arccmd > "$archive"
					else
						[[ -n "$verbose" ]] && echo "tar cf - ${args[@]} > \"$archive\""
						tar cf - "${args[@]}" > "$archive"
					fi
				else
					case "$ext" in
						tar.Z | taz | tz )
							! command -v compress >/dev/null 2>&1 && please_install compress
							;;
						tar.gz | tgz )
							! command -v gzip >/dev/null 2>&1 && please_install gzip
							;;
						tar.bz2 | tbz | tb2 | tbz2 )
							! command -v bzip2 >/dev/null 2>&1 && please_install bzip2
							;;
						tar.xz | txz )
							! command -v xz >/dev/null 2>&1 && please_install xz
							;;
						tar.lzma | tlz )
							! command -v xz >/dev/null 2>&1 && ! command -v lzma >/dev/null 2>&1 && please_install "xz or lzma"
							;;
					esac
					[[ -n "$verbose" ]] && echo "$tarcmd ${switches[@]} \"$archive\" \""${args[@]}"\""
					$tarcmd $tarcmd2 "${switches[@]}" "$archive" "${args[@]}"
				fi
				;;
			iso )
				! command -v genisoimage >/dev/null 2>&1 && please_install genisoimage
				[[ -n "$recursing" ]] && bad_switch genisoimage recursion
				[[ -n "$password" ]] && bad_switch genisoimage password
				[[ -n "$verbose" ]] && echo genisoimage ${switches[@]} -o $archive "${args[@]}"
				genisoimage "${switches[@]}" -o $archive "${args[@]}"
				;;
			* )
				help "Creation of \"$ext\" archives isn't supported by this script."
				;;
		esac
	fi
fi