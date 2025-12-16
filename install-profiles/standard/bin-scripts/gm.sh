#
# Description: Git Manager: interactive git workflow helper
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
gm: Git Manager: interactive git workflow helper
Usage: gm

Git Manager allows you to select an action to perform on your git repository.
EOT
	exit 0
fi

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Get default/main branch name (typically 'main' or 'master')
get_main_branch() {
    # Try to get the default branch from remote
    git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || \
    # Fallback: check common names
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        echo "main"  # default fallback
    fi
}

# Prompt for commit message
get_commit_message() {
    local branch="$1"
    echo "Enter commit message:" >&2
    read -r message
    echo "${branch}: ${message}"
}

# Execute a command with logging
execute_command() {
    local command="$1"
    echo "Executing: $command"
    eval "$command"
}

# Action: Push to branch (add, commit, push)
action_push_to_branch() {
    local branch=$(get_current_branch)
    local message=$(get_commit_message "$branch")
    echo "git add . && git commit -m \"$message\" && git push"
}

# Action: Commit and push (no add)
action_commit_and_push() {
    local branch=$(get_current_branch)
    local message=$(get_commit_message "$branch")
    echo "git commit -m \"$message\" && git push"
}

# Action: Merge from main/master branch
action_merge_from_main() {
    local main_branch=$(get_main_branch)
    echo "git fetch && git merge origin/$main_branch"
}

# Action: Merge current branch to main/master
action_merge_to_main() {
    local main_branch=$(get_main_branch)
    local current_branch=$(get_current_branch)
    
    if [[ "$current_branch" = "$main_branch" ]]; then
        echo "Error: Already on $main_branch branch" >&2
        return 1
    fi
    
    echo "git checkout $main_branch && git merge $current_branch"
}

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

current_branch=$(get_current_branch)
main_branch=$(get_main_branch)

# Menu options
action=$(cat <<EOF | fzf --prompt="Git Manager (on: $current_branch) > " --height=40% --reverse
Push to branch (add, commit, push)
Commit and push (commit, push)
Merge from $main_branch (fetch, merge origin/$main_branch)
Merge to $main_branch (checkout $main_branch, merge current)
EOF
)
    
command=""
case "$action" in
    "Push to branch"*)
        command=$(action_push_to_branch)
        ;;
    "Commit and push"*)
        command=$(action_commit_and_push)
        ;;
    "Merge from"*)
        command=$(action_merge_from_main)
        ;;
    "Merge to"*)
        command=$(action_merge_to_main)
        ;;
    *)
        echo "No action selected" >&2
        exit 0
        ;;
esac

[[ -n "$command" ]] && execute_command "$command"
