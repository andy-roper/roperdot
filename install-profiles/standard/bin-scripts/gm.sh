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

. "${ROPERDOT_DIR}/source-scripts/input-functions"

# Get clipboard command for the current platform
get_clipboard_command() {
    if command -v clip.exe &>/dev/null; then
        echo "clip.exe"
    elif command -v pbcopy &>/dev/null; then
        echo "pbcopy"
    elif command -v xclip &>/dev/null; then
        echo "xclip -selection clipboard"
    elif command -v wl-copy &>/dev/null; then
        echo "wl-copy"
    else
        echo ""  # no clipboard available
    fi
}

# Select a file with gum or fzf (sorted: files before directories, case-insensitive)
# Scoped to current directory and subdirectories
select_file() {
    local prompt="${1:-Select file > }"
    
    # git ls-files already returns paths relative to current directory
    # No need to filter - just use it directly
    local file_list=$(git ls-files | awk -F/ '{
        if (NF == 1) {
            # Top-level files: prefix with "0" for sorting first
            print "0|" tolower($0) "|" $0
        } else {
            # Files in subdirs: prefix with "1" and directory depth
            print "1|" tolower($0) "|" $0
        }
    }' | sort -t'|' -k1,1 -k2,2 | cut -d'|' -f3)
    
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        echo "$file_list" | gum filter --placeholder="$prompt" --height=$height
    else
        echo "$file_list" | fzf --exact --prompt="$prompt" --height=55% --reverse
    fi
}

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
    local message
    if command -v gum &>/dev/null; then
        if ! message=$(gum input --placeholder="Enter commit message (branch is automatically prepended)"); then
            echo "Commit cancelled" >&2
            return 1
        fi
    else
        echo "Enter commit message (branch is automatically prepended):" >&2
        if ! read -r message; then
            echo "Commit cancelled" >&2
            return 1
        fi
    fi
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

# Action: Fetch file from main branch
action_fetch_file() {
    local main_branch=$(get_main_branch)
    
    # Fetch latest from remote
    echo "Fetching from origin..."
    git fetch origin
    
    # Get list of files that differ from origin/main
    local diff_files=$(git diff --name-only origin/$main_branch)
    
    if [[ -z "$diff_files" ]]; then
        echo "No files differ from origin/$main_branch - everything is in sync" >&2
        return 1
    fi
    
    local file
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        file=$(echo "$diff_files" | gum filter --placeholder="Select file to fetch from origin/$main_branch > " --height=$height)
    else
        file=$(echo "$diff_files" | fzf --exact --prompt="Select file to fetch from origin/$main_branch > " --height=55% --reverse)
    fi
    
    if [[ -z "$file" ]]; then
        echo "No file selected" >&2
        return 1
    fi
    
    # Prompt for backup/stash/overwrite
    local choice
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        choice=$(gum choose --header="How to handle local file?" --height=$height \
            "Backup (create timestamped backup)" \
            "Stash (stash local changes)" \
            "Overwrite (replace without backup)")
    else
        choice=$(cat <<EOF | fzf --prompt="How to handle local file? > " --height=55% --reverse
Backup (create timestamped backup)
Stash (stash local changes)
Overwrite (replace without backup)
EOF
)
    fi
    
    if [[ -z "$choice" ]]; then
        echo "No option selected" >&2
        return 1
    fi
    
    # Build gf command based on choice
    case "$choice" in
        "Backup"*)    echo "gf --backup \"$file\"" ;;
        "Stash"*)     echo "gf --stash \"$file\"" ;;
        "Overwrite"*) echo "gf \"$file\"" ;;
    esac
}

# Action: Switch branches
action_switch_branch() {
    local current_branch=$(get_current_branch)
    
    # Get list of local branches, excluding current
    local branches=$(git branch --format='%(refname:short)' | grep -v "^${current_branch}$")
    
    if [[ -z "$branches" ]]; then
        echo "No other branches available" >&2
        return 1
    fi
    
    local selected_branch
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        selected_branch=$(echo "$branches" | gum filter --placeholder="Switch to branch > " --height=$height)
    else
        selected_branch=$(echo "$branches" | fzf --exact --prompt="Switch to branch > " --height=55% --reverse)
    fi
    
    if [[ -z "$selected_branch" ]]; then
        echo "No branch selected" >&2
        return 1
    fi
    
    echo "git checkout $selected_branch"
}

# Action: Amend last commit
action_amend_commit() {
    # Check if there are any commits
    if ! git rev-parse HEAD &>/dev/null; then
        echo "Error: No commits to amend" >&2
        return 1
    fi
    
    # Prompt for amend type
    local choice
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        choice=$(gum choose --header="How to amend?" --height=$height \
            "Keep message (amend without editing)" \
            "Edit message (amend and change message)")
    else
        choice=$(cat <<EOF | fzf --prompt="How to amend? > " --height=55% --reverse
Keep message (amend without editing)
Edit message (amend and change message)
EOF
)
    fi
    
    if [[ -z "$choice" ]]; then
        echo "No option selected" >&2
        return 1
    fi
    
    case "$choice" in
        "Keep message"*) 
            echo "git commit --amend --no-edit" 
            ;;
        "Edit message"*) 
            # Get current commit message and allow editing
            local current_msg=$(git log -1 --pretty=%B)
            local new_message
            
            if command -v gum &>/dev/null; then
                if ! new_message=$(gum input --value="$current_msg" --placeholder="Edit commit message"); then
                    echo "Amend cancelled" >&2
                    return 1
                fi
            elif [[ -n "$ZSH_VERSION" ]]; then
                echo "Edit commit message:" >&2
                new_message="$current_msg"
                vared new_message
            else
                echo "Edit commit message:" >&2
                read -e -i "$current_msg" -r new_message
            fi
            
            if [[ -z "$new_message" ]]; then
                echo "Error: Empty commit message" >&2
                return 1
            fi
            
            echo "git commit --amend -m \"$new_message\""
            ;;
    esac
}

# Action: Stash changes
action_stash_changes() {
    # Check if there are changes to stash (tracked or untracked)
    if git diff-index --quiet HEAD -- && [[ -z $(git ls-files --others --exclude-standard) ]]; then
        echo "Error: No changes to stash" >&2
        return 1
    fi
    
    local stash_message
    if command -v gum &>/dev/null; then
        if ! stash_message=$(gum input --placeholder="Enter stash message (optional, press Esc to skip)"); then
            echo "Stash cancelled" >&2
            return 1
        fi
    else
        echo "Enter stash message (optional, press Enter to skip):" >&2
        if ! read -r stash_message; then
            echo "Stash cancelled" >&2
            return 1
        fi
    fi
    
    if [[ -n "$stash_message" ]]; then
        echo "git stash push -u -m \"$stash_message\""
    else
        echo "git stash -u"
    fi
}

# Action: Apply or pop stash
action_apply_stash() {
    # Check if there are any stashes
    if ! git stash list &>/dev/null || [[ -z "$(git stash list)" ]]; then
        echo "Error: No stashes available" >&2
        return 1
    fi
    
    # List stashes with fzf
    local stash=$(git stash list | fzf --exact --prompt="Select stash > " --height=55% --reverse --preview="echo {} | cut -d: -f1 | xargs git stash show -p")
    
    if [[ -z "$stash" ]]; then
        echo "No stash selected" >&2
        return 1
    fi
    
    # Extract stash reference (e.g., stash@{0})
    local stash_ref=$(echo "$stash" | cut -d: -f1)
    
    # Prompt for apply or pop
    local choice
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        choice=$(gum choose --header="How to restore?" --height=$height \
            "Apply (keep stash in list)" \
            "Pop (remove from list)")
    else
        choice=$(cat <<EOF | fzf --prompt="How to restore? > " --height=55% --reverse
Apply (keep stash in list)
Pop (remove from list)
EOF
)
    fi
    
    if [[ -z "$choice" ]]; then
        echo "No option selected" >&2
        return 1
    fi
    
    case "$choice" in
        "Apply"*) echo "git stash apply $stash_ref" ;;
        "Pop"*)   echo "git stash pop $stash_ref" ;;
    esac
}

# Action: Clear stashes
action_clear_stashes() {
    # Check if there are any stashes
    if ! git stash list &>/dev/null || [[ -z "$(git stash list)" ]]; then
        echo "Error: No stashes to clear" >&2
        return 1
    fi
    
    # Prompt for clear type
    local choice
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        choice=$(gum choose --header="Clear stashes" --height=$height \
            "Drop specific stash" \
            "Clear all stashes")
    else
        choice=$(cat <<EOF | fzf --prompt="Clear stashes > " --height=55% --reverse
Drop specific stash
Clear all stashes
EOF
)
    fi
    
    if [[ -z "$choice" ]]; then
        echo "No option selected" >&2
        return 1
    fi
    
    case "$choice" in
        "Drop specific"*)
            local stash
            if command -v gum &>/dev/null; then
                local height=$(( LINES * 55 / 100 ))
                stash=$(git stash list | gum filter --placeholder="Select stash to drop > " --height=$height)
            else
                stash=$(git stash list | fzf --exact --prompt="Select stash to drop > " --height=55% --reverse)
            fi
            if [[ -z "$stash" ]]; then
                echo "No stash selected" >&2
                return 1
            fi
            local stash_ref=$(echo "$stash" | cut -d: -f1)
            echo "git stash drop $stash_ref"
            ;;
        "Clear all"*)
            echo "git stash clear"
            ;;
    esac
}

# Action: View commit history
action_view_history() {
    # Check if there are any commits
    if ! git log -n 1 &>/dev/null; then
        echo "Error: No commits in repository" >&2
        return 1
    fi
    
    local clipboard_cmd=$(get_clipboard_command)
    local copy_key_help=""
    
    if [[ -n "$clipboard_cmd" ]]; then
        copy_key_help=" | ctrl-y: copy SHA"
    fi
    
    # Build fzf command with keybindings
    local fzf_opts=(
        --ansi
        --no-sort
        --reverse
        --tiebreak=index
        --prompt="Commit History${copy_key_help} > "
        --preview="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always %"
        --preview-window=right:60%
    )
    
    # Add copy keybinding if clipboard is available
    if [[ -n "$clipboard_cmd" ]]; then
        fzf_opts+=(--bind="ctrl-y:execute-silent(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | $clipboard_cmd)+abort")
    fi
    
    # Run git log with fzf
    git log --graph --color=always --abbrev=7 --format='%C(auto)%h %an %C(blue)%s %C(yellow)%cr' | \
        fzf "${fzf_opts[@]}"
    
    # Return empty command since this is just for viewing
    echo ""
}

# Action: Show file history
action_file_history() {
    # Check if there are any commits
    if ! git log -n 1 &>/dev/null; then
        echo "Error: No commits in repository" >&2
        return 1
    fi
    
    # Select file
    local file=$(select_file "Select file to view history > ")
    
    if [[ -z "$file" ]]; then
        echo "No file selected" >&2
        return 1
    fi
    
    local clipboard_cmd=$(get_clipboard_command)
    local copy_key_help=""
    
    if [[ -n "$clipboard_cmd" ]]; then
        copy_key_help=" | ctrl-y: copy SHA"
    fi
    
    # Build fzf command with keybindings
    local fzf_opts=(
        --ansi
        --no-sort
        --reverse
        --tiebreak=index
        --prompt="History for $file${copy_key_help} > "
        --preview="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always % -- $file"
        --preview-window=right:60%
    )
    
    # Add copy keybinding if clipboard is available
    if [[ -n "$clipboard_cmd" ]]; then
        fzf_opts+=(--bind="ctrl-y:execute-silent(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | $clipboard_cmd)+abort")
    fi
    
    # Show file history with --follow to track renames
    git log --follow --color=always --abbrev=7 --format='%C(auto)%h %an %C(blue)%s %C(yellow)%cr' -- "$file" | \
        fzf "${fzf_opts[@]}"
    
    # Return empty command since this is just for viewing
    echo ""
}

# Action: Git blame
action_git_blame() {
    # Check if there are any commits
    if ! git log -n 1 &>/dev/null; then
        echo "Error: No commits in repository" >&2
        return 1
    fi
    
    # Select file
    local file=$(select_file "Select file for blame > ")
    
    if [[ -z "$file" ]]; then
        echo "No file selected" >&2
        return 1
    fi
    
    # Show git blame with color and use less for paging
    echo "git blame --color-lines --color-by-age $file | less -R"
}

# Action: Diff vs main
action_diff_vs_main() {
    local main_branch=$(get_main_branch)
    local current_branch=$(get_current_branch)
    
    if [[ "$current_branch" = "$main_branch" ]]; then
        echo "Error: Already on $main_branch branch" >&2
        return 1
    fi
    
    # Prompt for diff type
    local choice
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        choice=$(gum choose --header="Diff vs $main_branch" --height=$height \
            "Show full diff" \
            "Show file list only" \
            "Show diff stats")
    else
        choice=$(cat <<EOF | fzf --prompt="Diff vs $main_branch > " --height=55% --reverse
Show full diff
Show file list only
Show diff stats
EOF
)
    fi
    
    if [[ -z "$choice" ]]; then
        echo "No option selected" >&2
        return 1
    fi
    
    case "$choice" in
        "Show full diff")
            echo "git diff --color origin/$main_branch | less -R"
            ;;
        "Show file list only")
            echo "git diff --name-only origin/$main_branch"
            ;;
        "Show diff stats")
            echo "git diff --stat origin/$main_branch"
            ;;
    esac
}

# Action: Delete branch
action_delete_branch() {
    local current_branch=$(get_current_branch)
    local main_branch=$(get_main_branch)
    
    # Get list of branches excluding current and main
    local branches=$(git branch --format='%(refname:short)' | grep -v "^${current_branch}$" | grep -v "^${main_branch}$")
    
    if [[ -z "$branches" ]]; then
        echo "No branches available to delete" >&2
        return 1
    fi
    
    local selected_branch
    if command -v gum &>/dev/null; then
        local height=$(( LINES * 55 / 100 ))
        selected_branch=$(echo "$branches" | gum filter --placeholder="Select branch to delete > " --height=$height)
    else
        selected_branch=$(echo "$branches" | fzf --exact --prompt="Select branch to delete > " --height=55% --reverse)
    fi
    
    if [[ -z "$selected_branch" ]]; then
        echo "No branch selected" >&2
        return 1
    fi
    
    # Check if branch is merged
    local is_merged=$(git branch --merged | grep "^[* ]*${selected_branch}$")
    
    if [[ -z "$is_merged" ]]; then
        # Branch not merged - warn user
        if command -v gum &>/dev/null; then
            local height=$(( LINES * 55 / 100 ))
            local force_delete=$(gum choose --header="WARNING: Branch '$selected_branch' is not merged!" --height=$height \
                "Force delete anyway" \
                "Cancel")
        else
            local force_delete=$(cat <<EOF | fzf --prompt="WARNING: Branch '$selected_branch' is not merged! > " --height=55% --reverse
Force delete anyway
Cancel
EOF
)
        fi
        
        if [[ "$force_delete" == "Force"* ]]; then
            echo "git branch -D $selected_branch"
        else
            echo "Delete cancelled" >&2
            return 1
        fi
    else
        # Branch is merged - safe delete
        ask_yn_n "Confirm deletion of branch" || return 1
        echo "git branch -d $selected_branch"
    fi
}

# Check if gum or fzf is available
if ! command -v gum &> /dev/null && ! command -v fzf &> /dev/null; then
    echo "Error: gum or fzf is required but neither is installed" >&2
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
if command -v gum &>/dev/null; then
    local height=$(( LINES * 55 / 100 ))
    action=$(gum choose --header="Git Manager (on: $current_branch)" --height=$height \
        "Push to branch (add, commit, push)" \
        "Commit and push (commit, push)" \
        "Switch branches" \
        "Amend last commit" \
        "Stash changes" \
        "Apply/pop stash" \
        "Clear stashes" \
        "View commit history" \
        "Show file history" \
        "Git blame" \
        "Diff vs $main_branch" \
        "Merge from $main_branch (fetch, merge origin/$main_branch)" \
        "Merge to $main_branch (checkout $main_branch, merge current)" \
        "Fetch file from $main_branch" \
		"Delete branch" \
        "Squash commits" \
        "Force sync with remote")
else
    action=$(cat <<EOF | fzf --prompt="Git Manager (on: $current_branch) > " --height=55% --reverse
Push to branch (add, commit, push)
Commit and push (commit, push)
Switch branches
Amend last commit
Stash changes
Apply/pop stash
Clear stashes
View commit history
Show file history
Git blame
Diff vs $main_branch
Merge from $main_branch (fetch, merge origin/$main_branch)
Merge to $main_branch (checkout $main_branch, merge current)
Fetch file from $main_branch
Delete branch
Squash commits
Force sync with remote
EOF
)
fi
    
command=""
case "$action" in
    "Push to branch"*)
        command=$(action_push_to_branch)
        ;;
    "Commit and push"*)
        command=$(action_commit_and_push)
        ;;
    "Switch branches"*)
        command=$(action_switch_branch)
        ;;
    "Amend last commit"*)
        command=$(action_amend_commit)
        ;;
    "Stash changes"*)
        command=$(action_stash_changes)
        ;;
    "Apply/pop stash"*)
        command=$(action_apply_stash)
        ;;
    "Clear stashes"*)
        command=$(action_clear_stashes)
        ;;
    "View commit history"*)
        command=$(action_view_history)
        ;;
    "Show file history"*)
        command=$(action_file_history)
        ;;
    "Git blame"*)
        command=$(action_git_blame)
        ;;
    "Diff vs"*)
        command=$(action_diff_vs_main)
        ;;
    "Merge from"*)
        command=$(action_merge_from_main)
        ;;
    "Merge to"*)
        command=$(action_merge_to_main)
        ;;
    "Fetch file"*)
        command=$(action_fetch_file)
        ;;
    "Delete branch"*)
        command=$(action_delete_branch)
        ;;
    "Force sync with remote")
        if ask_yn_n "Discard local changes and replace with remote"; then
        	command="git fetch origin && git reset --hard origin/main"
        else
        	echo "Aborting update"
        	exit 0
        fi
        ;;
    "Squash commits")
		command="cd ~/roperdot && git add . && git commit -m \"Fix\" && git rebase -i HEAD~2 && git push --force-with-lease"
		;;
    *)
        echo "No action selected" >&2
        exit 0
        ;;
esac

[[ -n "$command" ]] && execute_command "$command"
