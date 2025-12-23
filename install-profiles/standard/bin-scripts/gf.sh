#
# Description: Git Fetch file: fetch a file from origin/main branch
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
gf: Git Fetch file: fetch a file from origin/main branch
Usage: gf [--backup|--stash] <filename>

Options:
  --backup  Create timestamped backup before overwriting
  --stash   Stash the file before overwriting
EOT
	exit 0
fi

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

# Stash a specific file
stash_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        if git diff --quiet "$file" && git diff --cached --quiet "$file"; then
            echo "No changes to stash in $file"
        else
            git stash push -m "gf: stashing $file before fetch" "$file"
            echo "Stashed changes for: $file"
        fi
    fi
}

# Fetch file from remote branch
fetch_file_from_remote() {
    local file="$1"
    local main_branch="$2"
    
    # Check if file exists in remote
    if ! git cat-file -e "origin/${main_branch}:${file}" 2>/dev/null; then
        echo "Error: File '$file' does not exist in origin/$main_branch" >&2
        return 1
    fi
    
    # Fetch the file
    git show "origin/${main_branch}:${file}" > "$file"
    echo "Fetched $file from origin/$main_branch"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup) backup_mode=true ;;
        --stash)  stash_mode=true ;;
        -*)       echo "Error: Unknown option: $1" >&2 && exit 1 ;;
        *)
            if [[ -z "$filename" ]]; then
                filename="$1"
            else
                echo "Error: Multiple filenames specified" >&2
                exit 1
            fi
            ;;
    esac
    shift
done

# Validate filename
if [[ -z "$filename" ]]; then
    echo "Error: No filename specified" >&2
    exit 1
fi

# Get main branch
main_branch=$(get_main_branch)

# Fetch latest from remote
echo "Fetching from origin..."
git fetch origin

[[ -n "$backup_mode" ]] && cp "$filename" "${filename}.bak"
[[ -n "$stash_mode" ]] && stash_file "$filename"

# Fetch the file
fetch_file_from_remote "$filename" "$main_branch"
