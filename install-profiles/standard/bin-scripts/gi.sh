#
# Description: Git Information: interactive git information viewer
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
gi: Git Information: interactive git information viewer
Usage: gi

Git Information allows you to select an action to display information about a git repository.
EOT
	exit 0
fi

if ! command -v gum >/dev/null 2>&1 && ! command -v fzf >/dev/null 2>&1; then
    echo "Error: either gum or fzf is required to use this script" >&2
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

local current_branch=$(git rev-parse --abbrev-ref HEAD)

local menu_items=(
    "Status (git status)"
    "Diff (git diff)"
    "Log (git log --oneline --graph --decorate --all)"
    "Branches (git branch -a)"
)

local action
if command -v gum &>/dev/null; then
    local height=$(( LINES * 4 / 10 ))
    action=$(gum choose --header="Git Information (on: $current_branch)" --height=$height "${menu_items[@]}")
else
    action=$(printf '%s\n' "${menu_items[@]}" | fzf --prompt="Git Information (on: $current_branch) > " --height=40% --reverse)
fi
    
case "$action" in
    "Status"*)
        git status
        ;;
    "Diff"*)
        git diff
        ;;
    "Log"*)
        git log --oneline --graph --decorate --all
        ;;
    "Branches"*)
        git branch -a
        ;;
    *)
        echo "No action selected" >&2
        ;;
esac
