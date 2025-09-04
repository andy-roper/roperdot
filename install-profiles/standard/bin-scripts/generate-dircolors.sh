#
# Description: Generates .dircolors from a source file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
generate-dircolors: generate .dircolors from a source file
Usage: generate-dircolors [filespec]

This script will generate .dircolors based on the color definitions for file extensions.

If no input file is specified, roperdot/dircolors_source.txt will be used.
EOT
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

. "${ROPERDOT_DIR}/source-scripts/re-match"

COLOR_BLACK=30
COLOR_RED=31
COLOR_GREEN=32
COLOR_YELLOW=33
COLOR_BLUE=34
COLOR_MAGENTA=35
COLOR_CYAN=36
COLOR_WHITE=37
COLOR_BRBLACK="1;30"
COLOR_BRRED="1;31"
COLOR_BRGREEN="1;32"
COLOR_BRYELLOW="1;33"
COLOR_BRBLUE="1;34"
COLOR_BRMAGENTA="1;35"
COLOR_BRCYAN="1;36"
COLOR_BRWHITE="1;37"

bg_color_re="^1;(.*)"

bg_color () {
	local bg=$1
	if re_match "$bg" "$bg_color_re"; then
		(( bg += 10 ))
		echo "1;$bg"
	else
		(( bg += 10 ))
		echo "$bg"
	fi
}

parse_color_string () {
	local str="$1"
	if re_match "$str" "^(.*)[[:space:]]+on[[:space:]]+(.*)$"; then
		local fg_name="${re_match[1]}" bg_name="${re_match[2]}"
		[[ $current_shell = bash ]] && local fg="${!fg_name}" || local fg="${(P)fg_name}"
		[[ -z "$fg" ]] && echo "Color $fg_name not defined" && exit 1
		[[ $current_shell = bash ]] && local bg="${!bg_name}" || local bg="${(P)bg_name}"
		[[ -z "$bg" ]] && echo "Color $bg_name not defined" && exit 1
		bg="$(bg_color "$bg")"
		echo "$fg;$bg"
	else
		if [[ "$1" =~ ^COLOR ]]; then
			[[ $current_shell = bash ]] && local fg="${!1}" || local fg="${(P)1}"
			[[ -z "$fg" ]] && echo "Color $1 not defined" && exit 1
		else
			fg="$1"
		fi
		echo "$fg"
	fi
}

uc () {
	echo "$1" | awk '{print toupper($0)}'
}

lc () {
	echo "$1" | awk '{print tolower($0)}'
}

f=${1:-${ROPERDOT_DIR}/dircolors_source.txt}
dircolors="${ROPERDOT_DIR}/.dircolors"

if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    TERM=xterm-256color
else
	TERM=xterm
fi

echo "# $TERM" > "$dircolors"
echo "# ROPERDOT" >> "$dircolors"
asis_re="^[[:space:]]*(COLOR|TERM|OPTIONS|EIGHTBIT)"
category_re="^[[:space:]]*category[[:space:]]*:[[:space:]]*([^[:space:]]+)"
color_re="^[[:space:]]*color[[:space:]]*:[[:space:]]*([^[:space:]]+)"
special_re1="^([^[:space:]]+)[[:space:]]+\"([^#]*)\""
special_re2="^([^[:space:]]+)[[:space:]]+([^#[:space:]]+)"
ext_with_inline_color_re="^([^[:space:]]+)[[:space:]]+color=\"(.*)\""
ext_re="^([^[:space:]]+)"
while IFS= read line; do
	[[ "$line" =~ ^# ]] && continue
	if [[ "$line" =~ $asis_re ]]; then
		echo "$line" >> "$dircolors"
	elif re_match "$line" $category_re; then
		category="${re_match[1]}"
	elif re_match "$line" $color_re; then
		color="${re_match[1]}"
		re_match "$color" "^\"(.+)\"$" && color="$(parse_color_string "${re_match[1]}")"
	elif re_match "$line" "$ext_with_inline_color_re"; then
		ext="${re_match[1]}"
		this_color="$(parse_color_string "${re_match[2]}")"
		echo "$ext $this_color" >> "$dircolors"
		ucext="$(uc "$ext")"
		if [[ "$ext" != "$ucext" ]]; then
			echo "$ucext $this_color" >> "$dircolors"
		fi
		lcext="$(lc "$ext")"
		if [[ "$ext" != "$lcext" ]]; then
			echo "$lcext $this_color" >> "$dircolors"
		fi
	elif re_match "$line" "$special_re1" || re_match "$line" "$special_re2"; then
		match_str="${re_match[1]}"
		this_color="$(parse_color_string "${re_match[2]}")"
		echo "$match_str $this_color" >> "$dircolors"
	elif re_match "$line" $ext_re; then
		ext="${re_match[1]}"
		echo "$ext $color" >> "$dircolors"
		ucext="$(uc "$ext")"
		if [[ "$ext" != "$ucext" ]]; then
			echo "$ucext $color" >> "$dircolors"
		fi
		lcext="$(lc "$ext")"
		if [[ "$ext" != "$lcext" ]]; then
			echo "$lcext $color" >> "$dircolors"
		fi
	fi
done < "$f"