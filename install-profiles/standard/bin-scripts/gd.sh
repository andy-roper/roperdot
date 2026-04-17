#
# Description: Git Diff: ????????????????????????????????
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

set -eo pipefail

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
gd: show git differences for changed files in a repository
Usage: gd

gd shows differences for changed files between your local copy and the version in your branch.

This script requires for either gum or fzf to be installed for handling user interaction.

gd requires either vim or nvim to be installed to display the differences.
EOT
#'
	exit 0
fi

die() { echo "error: $*" >&2; exit 1; }

git rev-parse --is-inside-work-tree &>/dev/null || die "Not inside a git repository; exiting"

if command -v gum &>/dev/null; then
    selector=gum
elif command -v fzf &>/dev/null; then
    selector=fzf
else
    die "Could not find gum or fzf; exiting"
fi

if command -v nvim &>/dev/null; then
	diff_viewer=nvim
elif command -v vim &>/dev/null; then
	diff_viewer=vim
else
	die "Could not find nvim or vim; exiting"
fi

select_with_gum() {
    local files=("$@")
    local selected
    local cursor_up='\033[1A'
    local erase_line='\033[2K'
    selected=$(printf '%s\n' "${files[@]}" \
        | gum choose \
            --header "Select a file to diff (Esc or Enter with no selection to quit)" \
            --height 20) || { printf "${cursor_up}${erase_line}" >/dev/tty; true; }
    printf '%s' "$selected"
}

select_with_fzf() {
    local files=("$@")
    printf '%s\n' "${files[@]}" \
        | fzf \
            --prompt "Select file (Enter=open, Esc=quit): " \
            --height 40% \
            --reverse \
            --no-multi \
            --bind "enter:accept,esc:abort" \
        || true
}

trap '[[ -n "$tmpfile" ]] && rm -f "$tmpfile"' EXIT

reporoot=$(git rev-parse --show-toplevel)

while true; do
    # Collect changed files into an array
    mapfile -t changed < <(git diff --name-only HEAD 2>/dev/null)

    if [[ ${#changed[@]} -eq 0 ]]; then
        echo "No changed files found."
        exit 0
    fi

    if [[ -z "$subsequent_pass" ]]; then
        echo "Use :qa! to exit the diff tool"
        subsequent_pass=true
    fi

    # Let the user pick a file
    case "$selector" in
        gum) chosen=$(select_with_gum "${changed[@]}") ;;
        fzf) chosen=$(select_with_fzf "${changed[@]}") ;;
    esac

    # Exit if nothing was selected
    [[ -z "$chosen" ]] && break

    # Write HEAD version to a temp file so diffsplit can open it
    tmpfile=$(mktemp)
	git show "HEAD:${chosen}" 2>/dev/null > "$tmpfile" || true

	case "$diff_viewer" in
	    nvim) nvim -d "$tmpfile" "$reporoot/$chosen" ;;
	    vim)  vim "$reporoot/$chosen" -c "vert diffsplit $tmpfile" ;;
	esac
done