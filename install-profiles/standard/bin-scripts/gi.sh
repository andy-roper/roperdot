#!/usr/bin/env zsh
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

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is required but not installed" >&2
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

local current_branch=$(git rev-parse --abbrev-ref HEAD)

# Menu options
local action=$(cat <<EOF | fzf --prompt="Git Information (on: $current_branch) > " --height=40% --reverse
Status (git status)
Diff (git diff)
Log (git log --oneline --graph --decorate --all)
Branches (git branch -a)
EOF
)
    
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
