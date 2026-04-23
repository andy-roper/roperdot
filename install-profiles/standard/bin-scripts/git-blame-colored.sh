#
# Description: Print git blame information for a file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# Inspired by git-blame-colored at:
# https://gist.github.com/mplewis/11dfac41bad93aeaa2ec
#
# Requires: pygmentize, python3
#

# --- Resolve style file directory ---
if [[ -n "$ROPERDOT_DIR" ]]; then
    STYLE_DIR="${ROPERDOT_DIR}/config"
else
    # Fallback: same directory as this script
    if [[ -n "$ZSH_VERSION" ]]; then
        STYLE_DIR="${0:A:h}"
    else
        STYLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
fi

# --- Author colors (terminal escape codes) ---
colors=(
    $'\e[31m'   # red
    $'\e[32m'   # green
    $'\e[33m'   # yellow
    $'\e[35m'   # magenta
    $'\e[36m'   # cyan
    $'\e[91m'   # bright red
    $'\e[92m'   # bright green
    $'\e[93m'   # bright yellow
    $'\e[95m'   # bright magenta
    $'\e[96m'   # bright cyan
)
reset=$'\e[0m'

declare -A author_colors
color_idx=0

if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<'EOF'
git-blame-colored: print git blame information for a file
Usage: git-blame-colored [git blame options] <filespec>

Calls "git blame" for a file and colorizes the results so that each author
corresponds to a color. Syntax highlighting is applied to the code using
Pygments with the roperdot color scheme.

Environment variables (override hex colors, without leading #):
  COLOR_GREEN_RGB, COLOR_YELLOW_RGB, COLOR_BRCYAN_RGB, COLOR_BRBLUE_RGB,
  COLOR_BRGREEN_RGB, COLOR_BRMAGENTA_RGB, COLOR_BRYELLOW_RGB
EOF
    exit 0
fi

# --- Highlight the whole file upfront ---
# Last argument is the filespec (same convention as git blame)
file="${@: -1}"

if [[ ! -f "$file" ]]; then
    echo "git-blame-colored: '$file' is not a regular file" >&2
    exit 1
fi

# Store blame output in a temp file so we only run git blame once
blame_tmp=$(mktemp)
trap 'rm -f "$blame_tmp"' EXIT
git blame --line-porcelain "$@" > "$blame_tmp"

_pygmentize_cmd() {
    python3 - "$file" <<PYEOF 2>/dev/null || cat "$file"
import sys, os
sys.path.insert(0, '$STYLE_DIR')
from roperdot_style import RoperdotStyle
from pygments import highlight
from pygments.lexers import guess_lexer_for_filename, guess_lexer
from pygments.formatters import Terminal256Formatter
filepath = sys.argv[1]
code = open(filepath).read().expandtabs(4)
try:
    lexer = guess_lexer_for_filename(filepath, code)
except Exception:
    lexer = guess_lexer(code)
print(highlight(code, lexer, Terminal256Formatter(style=RoperdotStyle)), end='')
PYEOF
}
if [ -n "$ZSH_VERSION" ]; then
    highlighted=("${(@f)$(_pygmentize_cmd)}")
else
    mapfile -t highlighted < <(_pygmentize_cmd)
fi

# --- Pre-pass: find longest author name for column alignment ---
max_author_len=0
while IFS= read -r line; do
    if [[ "$line" =~ ^author[[:space:]] ]]; then
        author="${line#author }"
        if [[ ${#author} -gt $max_author_len ]]; then
            max_author_len=${#author}
        fi
    fi
done < "$blame_tmp"

# --- Parse porcelain blame output ---
# zsh arrays are 1-based, bash arrays are 0-based
if [[ -n "$ZSH_VERSION" ]]; then
    line_idx=1
    array_base=1
else
    line_idx=0
    array_base=0
fi
current_author=''
current_time=''
current_hash=''
line_num=1

while IFS= read -r line; do
    if [[ "$line" =~ ^author[[:space:]] ]]; then
        current_author="${line#author }"
    elif [[ "$line" =~ ^author-time[[:space:]] ]]; then
        current_time="${line#author-time }"
    elif [[ "$line" =~ ^[0-9a-f]{40}[[:space:]] ]]; then
        current_hash="${line:0:7}"
    elif [[ "$line" =~ ^\	 ]]; then
        # Assign a color to this author if not seen before
        if [[ -n "$ZSH_VERSION" ]]; then
            _has_color=$(( ${+author_colors[$current_author]} ))
        else
            _has_color=$(( ${author_colors[$current_author]+1} ))
        fi
        if [[ "$_has_color" -eq 0 ]]; then
            author_colors[$current_author]="${colors[(( color_idx + array_base ))]}"
            (( color_idx = (color_idx + 1) % ${#colors[@]} ))
        fi
        unset _has_color

        c="${author_colors[$current_author]}"

        # Format timestamp (GNU date vs BSD date)
        if date --version &>/dev/null 2>&1; then
            ts=$(date -d "@$current_time" "+%Y-%m-%d %H:%M:%S")   # GNU/Linux
        else
            ts=$(date -r "$current_time" "+%Y-%m-%d %H:%M:%S")    # macOS/BSD
        fi

        code_line="${highlighted[$line_idx]}"

        grey=$'\e[37m'
        printf "%-7s  %-*s  %-19s  %s%4s%s  %s\n" \
            "${c}${current_hash}" "$max_author_len" "$current_author" "$ts" \
            "$grey" "$line_num" "$reset" \
            "$code_line"

        (( line_num++ ))
        (( line_idx++ ))
    fi
done < "$blame_tmp"
