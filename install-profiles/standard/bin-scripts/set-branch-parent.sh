#
# Description: Sets the parent for git branches
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: not in a git-managed directory" >&2
    exit 1
fi

META_FILE="$(git rev-parse --git-dir)/branch-meta"

help() {
	cat <<EOT
set-branch-parent: set parent for git branches
Usage: set-branch-parent <parent-branch>
       set-branch-parent <parent-branch> <branch-or-pattern> [...]

If a single parameter is provided, the parent of the current branch will be
set to the specified branch.

If additional parameters are provided, each will be treated either as a
branch name or a simple glob pattern (asterisk matches any number of
characters). The parent branch will be set for matching branches.

The branch parentage is stored in the .git/branch-meta file.

Examples:
  set-branch-parent master            # set parent of current branch
  set-branch-parent master XYZ-1234   # set parent of a specific branch
  set-branch-parent master "XYZ-*"    # set parent of all XYZ- branches
EOT
	exit 0
}

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" || "$1" == "-?" ]]; then
	help
fi

set_parent() {
    local parent=$1
    local child=$2

    if grep -q "^${child}=" "$META_FILE" 2>/dev/null; then
        local old_parent=$(grep "^${child}=" "$META_FILE" | cut -d= -f2)
        local tmp=$(mktemp)
        sed "s|^${child}=.*|${child}=${parent}|" "$META_FILE" > "$tmp" && mv "$tmp" "$META_FILE"
        echo "Parent of ${child} changed from ${old_parent} to ${parent}"
    else
        echo "${child}=${parent}" >> "$META_FILE"
        echo "Parent of ${child} set to ${parent}"
    fi
}

parent=$1
shift

# Validate parent branch exists
if ! git show-ref --verify --quiet "refs/heads/${parent}"; then
    echo "Error: parent branch '${parent}' does not exist" >&2
    exit 1
fi

# No further args: set parent for current branch
if [[ $# -eq 0 ]]; then
    current=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current" == "main" || "$current" == "master" ]]; then
        echo "Warning: current branch is ${current}, skipping" >&2
        exit 1
    fi
    set_parent "$parent" "$current"
    exit 0
fi

# Process each child argument
for arg in "$@"; do
    if [[ "$arg" == *"*"* ]]; then
        # Pattern: match against all local branches
        matched=0
		while IFS= read -r branch; do
		    # Convert glob to regex: escape dots, replace * with .*
		    regex="^$(echo "$arg" | sed 's/\./\\./g; s/\*/.*/g')$"
		    if echo "$branch" | grep -qE "$regex"; then
		        set_parent "$parent" "$branch"
		        matched=$((matched + 1))
		    fi
		done < <(git branch --format='%(refname:short)')
        if [[ $matched -eq 0 ]]; then
            echo "Warning: pattern '${arg}' matched no branches" >&2
        fi
    else
        # Explicit branch name
        if ! git show-ref --verify --quiet "refs/heads/${arg}"; then
            echo "Error: branch '${arg}' does not exist" >&2
            continue
        fi
        set_parent "$parent" "$arg"
    fi
done