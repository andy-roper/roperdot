#
# Description: Views a file. The application used to view it is based on the file's extension and the applications you have installed.
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
v: view a file
Usage: v [-bt] [file ...]

Options:
-b  Force viewing as binary
-t  Force viewing as text

This script will call the appropriate application to view a file. The viewer
is determined by the file's extension and the viewers defined in
~/.bashrc-this-os-functions.

If fzf is installed and no file arguments are provided, fzf will be used to
allow the user to select a file in the current directory. If the argument is
a directory, fzf will be used for selecting a file in that directory.

If roperdot/edit-and-view-override is defined it will be sourced. Define
view_override function to override processing of arbitrary extensions. See
roperdot/edit-and-view-override-example.
EOT
	exit 0
}

[[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]] && help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

if [[ ! -f "$1" && "$1" =~ ^(http|www) ]]; then
	web-browser-app "$1"
	exit 0
fi

[[ -f "$ROPERDOT_DIR/edit-and-view-override" ]] && source "$ROPERDOT_DIR/edit-and-view-override"

# Enable extended globbing and disable case-sensitive matching
[[ $current_shell = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

call_override () {
	if command -v view_override >/dev/null 2>&1; then
		local f="$1" app
		app="$(view_override "$f")"
		if [[ -n "$app" ]]; then
			if command -v "$app" >/dev/null 2>&1; then
				[[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]] && f="$(fix-path "$f")"
				( "$app" "$f" >& /dev/null & )
			else
				echo Application $app not found
			fi
			return 0
		fi
	fi
	return 1
}

if [[ "$1" = "-b" ]]; then
	shift
	view_mode=binary
elif [[ "$1" = "-t" ]]; then
	shift
	view_mode=terminal
fi
files=()
if [[ $# -eq 0 ]]; then
	if [[ $(clippaste | grep "^\(http\|www\)") ]]; then
		web-browser-app "$(clippaste)"
	else
		command -v fzf >/dev/null 2>&1 || help
		f="$(find . -maxdepth 1 -type f -printf '%f\n' | sort | fzf --no-sort -0 --height 33% --layout=reverse)"
		[[ -n "$f" ]] && files+=("$f") || exit 0
	fi
elif [[ -d "$1" ]]; then
	command -v fzf >/dev/null 2>&1 || help
	f="$(find "$1" -maxdepth 1 -type f | sort | fzf --no-sort -0 --height 33% --layout=reverse)"
	[[ -n "$f" ]] && files+=("$f") || exit 0
else
	for f; do
		files+=("$f")
	done
fi
if [[ $view_mode = binary ]]; then
	[[ $current_shell = bash ]] && f="${files[0]}" || f="${files[1]}"
	show-file -b "$f"
	exit 0
fi
archive_re="\.(7z|zip|tgz|tar|tar.+([A-Za-z0-9])|taz|tz|rar|r00|jar|war|ear|iso|dmg|bz|bz2|tb2|tbz|tbz2|lha|lzma|tlz|xz|txz|gz|Z|cbr|cbz|cb7|cbt|cba)$"
for f in "${files[@]}"; do
	if [[ ! -r "$f" ]]; then
		echo "$0: file is unreadable: $f" >&2
		exit 0
	fi
	
	if [[ $view_mode = terminal ]]; then
		if [[ "$f" =~ $archive_re ]]; then
			list-archive "$f"
		else
			show-file "$f"
		fi
	else
		call_override "$f" && continue
	
		case "$f" in
			*.@(7z|zip|tgz|tar|tar.+([A-Za-z0-9])|taz|tz|rar|r00|jar|war|ear|iso|dmg|bz|bz2|tb2|tbz|tbz2|lha|lzma|tlz|xz|txz|gz|Z) )
				list-archive "$f"
				;;
			*.@(jpg|jpeg|png|gif|tif|tiff|bmp|tga))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					image-viewer-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(avi|divx|mkv|mp4|mpg|mpeg|wmv|m4v|vob|ifo|m2ts|MTS))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					video-player-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(mp3|ogg|au|wav|m4b))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					audio-player-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(htm|html|xml))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					web-browser-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.pdf)
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					pdf-viewer-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(odt|doc|docx|docm|rtf))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					word-processor-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(ods|xls|xlsx|xlsm))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					spreadsheet-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(odp|ppt|pptx|pptm))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					presentation-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(md|markdown))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					markdown-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(azw|epub|mobi))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					ebook-viewer-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.@(cbr|cbz|cb7|cbt|cba))
				if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
					comic-viewer-app "$f"
				else
					show-file -b "$f"
				fi
				;;
			*.csv)
				# csv preview source: http://stackoverflow.com/questions/1875305/command-line-csv-viewer
				sed 's/,,/, ,/g;s/,,/, ,/g' "$f" | column -s, -t | less -#2 -N -S
				;;
			*.@(bin|bup|ccd|chm|cue|djvu|dvi|fon|idx|ifo|img|isz|mdf|mds|nrg|otf|ps|sub|ttc|ttf|vob|wim))
				show-file -b "$f"
				;;
			*)
				show-file "$f"
				;;
		esac
	fi
done
