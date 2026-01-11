#
# Description: Shows status for a git repository
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
git-status: show status for a git repository
Usage: git-status
EOT
#'
	exit 0
fi

# Get branch info
branch=$(git branch --show-current 2>/dev/null)
if [[ -z "$branch" ]]; then
    echo "Not in a git repository"
    exit 1
fi

# Get ahead/behind info
ahead=0
behind=0
if git rev-parse --verify @{upstream} >/dev/null 2>&1; then
    ahead_behind=$(git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)
    behind=${ahead_behind%	*}
    ahead=${ahead_behind#*	}
fi

# Print branch info
echo "On branch: $branch"
[[ $ahead -gt 0 ]] && echo "  Ahead by $ahead commit(s)"
[[ $behind -gt 0 ]] && echo "  Behind by $behind commit(s)"
echo

# Initialize lists as newline-separated strings (portable)
staged_modified=""
staged_added=""
staged_deleted=""
staged_renamed=""
unstaged_modified=""
unstaged_deleted=""
untracked=""
conflicted=""

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    
    index="${line%${line#?}}"
    worktree="${line%${line#??}}"
    worktree="${worktree#?}"
    file="${line#???}"
    
    # Conflicted files
    if [[ "$index" = "U" || "$worktree" = "U" ]] || \
    { [[ "$index" = "D" && "$worktree" = "D" ]]; } || \
    { [[ "$index" = "A" && "$worktree" = "A" ]]; }; then
        conflicted="${conflicted}${file}"$'\n'
        continue
    fi
    
    # Staged changes
    case "$index" in
        M) staged_modified="${staged_modified}${file}"$'\n' ;;
        A) staged_added="${staged_added}${file}"$'\n' ;;
        D) staged_deleted="${staged_deleted}${file}"$'\n' ;;
        R) staged_renamed="${staged_renamed}${file}"$'\n' ;;
    esac
    
    # Unstaged changes
    case "$worktree" in
        M) unstaged_modified="${unstaged_modified}${file}"$'\n' ;;
        D) unstaged_deleted="${unstaged_deleted}${file}"$'\n' ;;
    esac
    
    # Untracked
    [[ "$index" = "?" ]] && untracked="${untracked}${file}"$'\n'
    
done <<EOF
$(git status --porcelain)
EOF

# Print section helper
print_files() {
    local files="$1"
    [[ -n "$files" ]] && echo "$files" | sed '/^$/d' | sed 's/^/    /'
}

# Staged changes
has_staged=0
if [[ -n "$staged_modified" || -n "$staged_added" || -n "$staged_deleted" || -n "$staged_renamed" ]]; then
	has_staged=1
fi

if [[ $has_staged -eq 1 ]]; then
    echo "Staged changes:"
    if [[ -n "$staged_modified" ]]; then
        echo "  Modified:"
        print_files "$staged_modified"
    fi
    if [[ -n "$staged_added" ]]; then
        echo "  Added:"
        print_files "$staged_added"
    fi
    if [[ -n "$staged_deleted" ]]; then
        echo "  Deleted:"
        print_files "$staged_deleted"
    fi
    if [[ -n "$staged_renamed" ]]; then
        echo "  Renamed:"
        print_files "$staged_renamed"
    fi
    echo
fi

# Unstaged changes
if [[ -n "$unstaged_modified" || -n "$unstaged_deleted" ]]; then
    echo "Unstaged changes:"
    if [[ -n "$unstaged_modified" ]]; then
        echo "  Modified:"
        print_files "$unstaged_modified"
    fi
    if [[ -n "$unstaged_deleted" ]]; then
        echo "  Deleted:"
        print_files "$unstaged_deleted"
    fi
    echo
fi

# Untracked files
if [[ -n "$untracked" ]]; then
    echo "Untracked files:"
    print_files "$untracked"
    echo
fi

# Conflicted files
if [[ -n "$conflicted" ]]; then
    echo "Conflicted files:"
    print_files "$conflicted"
    echo
fi

# Check if clean
if [[ $has_staged -eq 0 && -z "$unstaged_modified" ]] && \
[[ -z "$unstaged_deleted" && -z "$untracked" && -z "$conflicted" ]]; then
    echo "Working directory clean"
fi