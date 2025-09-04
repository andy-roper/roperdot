#
# Description: Used to wrap call to p4merge by git diff
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# diff is called by git with 7 parameters:
# path old-file old-hex old-mode new-file new-hex new-mode

#"C:\\Program Files\\Perforce\\p4merge.exe" "$2" "$5" | cat
#"/cygdrive/c/Program Files/Perforce/p4merge.exe" "$2" "$5" | cat

if [[ $# -lt 5 ]]; then
	cat <<EOT
git-diff-wrapper: wraps a call to p4merge by git diff
Usage: git-diff-wrapper <path> <old-file> <old-hex> <old-mode> <new-file>
EOT
	exit 0
fi

"${rd_program_files}/Perforce/p4merge.exe" "$2" "$5" | cat