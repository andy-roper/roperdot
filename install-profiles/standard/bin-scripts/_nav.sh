#
# Description: Navigate directories interactively
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
_nav: Navigate directories interactively

Usage: _nav [directory]

The _nav script is called by the nav function.

_nav allows the user to interactively navigate directories. The user will be
prompted for which directory to select when multiple directories are available.
_nav will automatically navigate through single-child directories, both when
traversing downward and upward. When STOP HERE is selected, the currently
selected directory will be echoed.

If BROWSE HERE is selected, the file manager will be opened to the currently
selected directory.
EOT
	exit 0
fi

[[ -f ~/.config/roperdot/roperdot-os-functions ]] && source ~/.config/roperdot/roperdot-os-functions

if [[ -n "$1" ]]; then
    start_dir="$1"
    # If directory was explicitly passed, show STOP HERE on first prompt
    already_prompted=true
else
    start_dir="$PWD"
fi

# Convert to absolute path
[[ "$start_dir" != /* ]] && start_dir="$PWD/$start_dir"

# Normalize the path (remove . and ..)
start_dir=$(cd "$start_dir" && pwd)

if [[ ! -d "$start_dir" ]]; then
    echo "Error: '$start_dir' is not a valid directory" >&2
    exit 1
fi

if [[ ! -r "$start_dir" ]]; then
    echo "Error: Cannot read directory '$start_dir'" >&2
    exit 1
fi

current_dir="$start_dir"

exclude_patterns=(
    "node_modules"
)

get_directories() {
    local dir="$1"
    local dirs=()
    
    while IFS= read -r -d '' entry; do
        local basename="${entry##*/}"
        local should_exclude=false
        
        # Skip hidden directories (starting with .)
        [[ "$basename" == .* ]] && should_exclude=true
        
        # Check against exclude patterns
        if [[ "$should_exclude" == false ]]; then
            for pattern in "${exclude_patterns[@]}"; do
                if [[ "$basename" == $pattern ]]; then
                    should_exclude=true
                    break
                fi
            done
        fi
        
        [[ "$should_exclude" == false ]] && dirs+=("$entry")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -readable -print0 2>/dev/null | sort -rz)
    
    printf '%s\n' "${dirs[@]}"
}

# Auto-ascend through single-child parent directories
auto_ascend() {
    local dir="$1"
   
    # Move to parent
    local parent="${dir%/*}"
    [[ -z "$parent" ]] && parent="/"
    dir="$parent"
    
    # Now check if THIS level (dir) has multiple items - if so, stop here
    local current_dirs=()
    while IFS= read -r cdir; do
        [[ -n "$cdir" ]] && current_dirs+=("$cdir")
    done < <(get_directories "$dir")
    
    local current_total=$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    
    # If current level has multiple items, we're done
    if [[ ${#current_dirs[@]} -gt 1 || $current_total -gt 1 ]]; then
        echo "$dir"
        return
    fi
    
    # Current level only has one child, keep ascending
    while [[ "$dir" != "/" ]]; do
        parent="${dir%/*}"
        [[ -z "$parent" ]] && parent="/"
        
        # Check if parent is readable
        [[ ! -r "$parent" ]] && break
        
        # Check if parent has multiple items
        local parent_dirs=()
        while IFS= read -r pdir; do
            [[ -n "$pdir" ]] && parent_dirs+=("$pdir")
        done < <(get_directories "$parent")
        
        local parent_total=$(find "$parent" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
        
        # If parent has multiple items, stop at parent
        if [[ ${#parent_dirs[@]} -gt 1 || $parent_total -gt 1 ]]; then
            dir="$parent"
            break
        fi
        
        # Parent has only one child, keep ascending
        dir="$parent"
    done
    
    echo "$dir"
}

# If starting directory is non-interesting (single child, no files), auto-descend first
while true; do
    temp_dirs=()
    while IFS= read -r subdir; do
        [[ -n "$subdir" ]] && temp_dirs+=("$subdir")
    done < <(get_directories "$current_dir")
    
    temp_total=$(find "$current_dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    
    # If single directory and no other items, auto-descend
    if [[ ${#temp_dirs[@]} -eq 1 ]] && [[ $temp_total -eq 1 ]]; then
        for single_dir in "${temp_dirs[@]}"; do
            current_dir="$single_dir"
        done
    else
        # Found an interesting directory, stop
        break
    fi
done

at_start=true
first_output=true

# Collapse a directory down through any single-child-directory chain.
# Prints the deepest directory that has more than one item (or any non-directory item),
# expressed as a path relative to the given base directory.
collapse_dir() {
    local base="$1"
    local dir="$2"
    local cd_sub_dirs cd_sub_total

    while true; do
        cd_sub_dirs=()
        while IFS= read -r sd; do
            [[ -n "$sd" ]] && cd_sub_dirs+=("$sd")
        done < <(get_directories "$dir")

        cd_sub_total=$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
        cd_sub_total="${cd_sub_total//[[:space:]]/}"

        # If exactly one child and it is a directory (nothing else present), descend
        if [[ ${#cd_sub_dirs[@]} -eq 1 && $cd_sub_total -eq 1 ]]; then
            dir="${cd_sub_dirs[@]:0:1}"
        else
            break
        fi
    done

    # Return path relative to base
    local value="${dir#${base}/}"
	echo "${value#/}"
}

while true; do
    # Get directories in current location
    directories=()
    while IFS= read -r subdir; do
        [[ -n "$subdir" ]] && directories+=("$subdir")
    done < <(get_directories "$current_dir")
    
    # Count total items (files + directories) for single-directory check
    total_items=$(find "$current_dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)
    
    # If no directories, we're done
    # [[ ${#directories[@]} -eq 0 && -z "$at_start" ]] && break
    at_start=
    
    # If only one directory and no other items, auto-descend (unless force_prompt is set)
    if [[ ${#directories[@]} -eq 1 ]] && [[ $total_items -eq 1 ]] && [[ -z "$force_prompt" ]]; then
        for single_dir in "${directories[@]}"; do
            current_dir="$single_dir"
        done
        continue
    fi
    
    force_prompt=
    
    # Multiple directories or directories + files: prompt user
    # Echo current directory before all prompts except the very first
    if [[ -n "$already_prompted" ]]; then
        if [[ "$first_output" == true ]]; then
            # First output: just print normally
            printf "%s" "$current_dir" >&2
            first_output=false
        else
            # Subsequent outputs: clear line and overwrite
            printf "\r\033[K%s" "$current_dir" >&2
        fi
    fi
    
    # Prepare directory list for fzf (basenames only)
    dir_list=()
    for dir in "${directories[@]}"; do
        # dir_list+=("${dir##*/}")
        dir_list+=("$(collapse_dir "$current_dir" "$dir")")
    done
    
    options_list=()
    [[ -n "$already_prompted" ]] && options_list+=("── STOP HERE ──")
    if [[ -n "$ROPERDOT_DIR" ]]; then
    	[[ -n "$ROPERDOT_DESKTOP_ENV" ]] && options_list+=("── BROWSE HERE ──")
    else
    	options_list+=("── BROWSE HERE ──")
    fi
    [[ "$current_dir" != "/" ]] && options_list+=("..")
    
    already_prompted=true

    # Build the fzf input - only include options_list if it has entries
    if [[ ${#options_list[@]} -gt 0 ]]; then
		fzf_out=$(printf '%s\n' "${dir_list[@]}" | tac | { printf '%s\n' "${options_list[@]}"; cat; } | \
		    PREVIEW_DIR="$current_dir" fzf \
		        --height=40% \
		        --layout=reverse \
		        --border \
		        --exact \
		        --print-query \
		        --prompt="Navigate > " \
				--preview='
				    item={}
				    if [ "$item" = "── STOP HERE ──" ]; then
				        echo "Stop navigation here"
				    elif [ "$item" = "── BROWSE HERE ──" ]; then
				        echo "Open file manager at this location"
				    elif [ "$item" = ".." ]; then
				        parent="${PREVIEW_DIR%/*}"
				        [ -z "$parent" ] && parent="/"
				        ls -1 "$parent" 2>/dev/null || echo "Parent directory"
				    else
				        ls -1 "$PREVIEW_DIR/$item" 2>/dev/null
				    fi
				' \
		        --preview-window=right:40%:wrap)
    else
		fzf_out=$(printf '%s\n' "${dir_list[@]}" | tac | \
		    PREVIEW_DIR="$current_dir" fzf \
		        --height=40% \
		        --layout=reverse \
		        --border \
		        --exact \
		        --print-query \
		        --prompt="Navigate > " \
		        --preview='ls -1 "$PREVIEW_DIR/"{}  2>/dev/null' \
		        --preview-window=right:50%:wrap)
    fi

    fzf_query="${fzf_out%%$'\n'*}"
    selected="${fzf_out#*$'\n'}"
    [[ "$selected" == "$fzf_query" ]] && selected=""  # no match chosen

    # If nothing was selected but user typed a query, treat it as a path
    if [[ -z "$selected" && -n "$fzf_query" ]]; then
        # Handle "..." => ../.., "...." => ../../.. etc.
        if [[ "$fzf_query" =~ ^\.{2,}$ ]]; then
            dots="${#fzf_query}"
            nav_target="$current_dir"
            for ((i = 1; i < dots; i++)); do
                nav_target="${nav_target%/*}"
                [[ -z "$nav_target" ]] && nav_target="/"
            done
            current_dir="$nav_target"
            force_prompt=true
            continue
        fi
        expanded="${fzf_query/#\~/$HOME}"
        [[ -d "$expanded" ]] && current_dir=$(cd "$expanded" && pwd)
        force_prompt=true
        continue
    fi

    [[ -z "$selected" || "$selected" == "── STOP HERE ──" ]] && break
    
    if [[ "$selected" == "── BROWSE HERE ──" ]]; then
    	if command -v fm &>/dev/null; then
    		fm "$current_dir"
    	else
			if [[ "$OSTYPE" == "darwin"* ]]; then
			    open "$current_dir"
			elif grep -qi microsoft /proc/version 2>/dev/null; then
			    win_path=$(wslpath -w "$current_dir")
			    explorer.exe "$win_path"
			else
			    nautilus "$current_dir" &
			fi
    	fi
        force_prompt=true
        continue
    fi

    if [[ "$selected" == ".." ]]; then
        current_dir=$(auto_ascend "$current_dir")
        force_prompt=true
        continue
    fi
    
    # Check if selected resolves to a real subdirectory first
    if [[ "$current_dir" == "/" ]]; then
        candidate="/$selected"
    else
        candidate="$current_dir/$selected"
    fi

    # Update current directory (descending)
    current_dir="$candidate"
done

# If we displayed a path, add a newline before final output
[[ "$first_output" == false ]] && echo >&2

echo "$current_dir"
