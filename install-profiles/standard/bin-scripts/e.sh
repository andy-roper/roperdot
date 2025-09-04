#
# Description: Edits a file; the application used is based on the file's extension and the available applications
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
e: edit a file
Usage: e [file ...]

This script will call the appropriate application to edit a file. The editor
is determined by the file's extension and the editors defined in
~/.bashrc-this-os-functions.

If fzf is installed and no file arguments are provided, fzf will be used to
allow the user to select a file in the current directory. If the argument is
a directory, fzf will be used for selecting a file in that directory.

If you're working in a graphical environment and the target file doesn't exist,
a new file will be created using touch before editing it with a text editor.

If roperdot/edit-and-view-override is defined it will be sourced. Define
the edit_override function to override processing of arbitrary extensions. See
roperdot/edit-and-view-override-example.
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

# Enable extended globbing and disable case-sensitive matching
[[ $current_shell = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

[[ -f "$ROPERDOT_DIR/edit-and-view-override" ]] && source "$ROPERDOT_DIR/edit-and-view-override"

call_override () {
	if command -v edit_override >/dev/null 2>&1; then
		local f="$1" app
		app="$(edit_override "$f")"
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

files=()
if [[ $# -eq 0 ]]; then
	command -v fzf >/dev/null 2>&1 || help
	f="$(find . -maxdepth 1 -type f -printf '%f\n' | sort | fzf --no-sort -0 --height 33% --layout=reverse)"
	[[ -n "$f" ]] && files+=("$f") || exit 0
elif [[ -d "$1" ]]; then
	command -v fzf >/dev/null 2>&1 || help
	f="$(find "$1" -maxdepth 1 -type f | sort | fzf -0 --no-sort --height 33% --layout=reverse)"
	[[ -n "$f" ]] && files+=("$f") || exit 0
else
	for f; do
		files+=("$f")
	done
fi
if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
	for f in "${files[@]}"; do
		if [[ ! -f "$f" ]]; then
			re="\\.\$"
			if [[ "$f" =~ $re ]]; then
				if [[ $ROPERDOT_CURRENT_SHELL = bash ]]; then
					read -p "Create file with name ending with dot [y/N]? " -n 1
				else
					read -k 1 "?Create file with name ending with dot [y/N]? "
				fi
				[[ "$REPLY" =~ ^[yY]$ ]] || continue
			fi
			touch "$f"
			text-editor-app "$f"
			continue
		fi
		
		call_override "$f" && continue

		case $f in
			*.@(7z|zip|tgz|tar|tar.+([A-Za-z0-9])|taz|tz|rar|r00|jar|war|ear|cbr|cbz|cb7|cbt|cba|iso|dmg|bz|bz2|tb2|tbz|tbz2|lha|lzma|tlz|xz|txz|gz|Z) )
				archive-editor-app "$f"
				;;
			*.@(jpg|jpeg|png|gif|tif|tiff|bmp|tga) )
				image-editor-app "$f"
				;;
			*.@(avi|divx|mkv|mp4|mpg|mpeg|m4v|vob|ifo|mt2s|MTS) )
				video-editor-app "$f"
				;;
			*.@(mp3|ogg|au|wav|m4b) )
				audio-editor-app "$f"
				;;
			*.@(htm|html|xml) )
				text-editor-app "$f"
				;;
			*.pdf)
				pdf-editor-app "$f"
				;;
			*.@(odt|doc|docx|docm|rtf) )
				word-processor-app "$f"
				;;
			*.@(ods|xls|xlsx|xlsm) )
				spreadsheet-app "$f"
				;;
			*.@(odp|ppt|pptx|pptm) )
				presentation-app "$f"
				;;
			*.@(azw|epub|mobi) )
				ebook-viewer-app "$f"
				;;
			* )
				text-editor-app "$f"
				;;
		esac

	done
else
	[[ $current_shell = bash ]] && f="${files[0]}" || f="${files[1]}"
	call_override "$f" || "$EDITOR" "$f"
fi