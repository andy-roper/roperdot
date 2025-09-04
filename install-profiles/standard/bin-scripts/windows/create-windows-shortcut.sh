#
# Description: (Windows) Creates a Windows desktop shortcut
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
. "${ROPERDOT_DIR}/source-scripts/win-env-functions"

# Complex example of creating shortcuts with VB:
# https://social.msdn.microsoft.com/Forums/vstudio/en-US/fe6d9e65-61f8-4aca-88af-54c289c7677f/create-a-shortcut-using-vb?forum=vbgeneral

help () {
	cat <<EOT
create-windows-shortcut: Create a Windows shortcut
Usage: create-windows-shortcut <shortcut name> <target> [options]

This script will create a shortcut in %USERPROFILE%\Desktop. The shortcut name
parameter will define the shortcut's name and the target parameter is what the
shortcut will invoke.

Options:
--public               Create shortcut in C:\Users\Public\Desktop
--icon-source <path>   Icon source file (defaults to target)
--icon-index <index>   Index of icon in source file
--desc <desc>          Description
--args <args>          Shortcut arguments
--working-dir <path>   Working directory
EOT
	exit 0
}

special_folder=Desktop
[[ $# -lt 2 ]] && help
shortcut="$1"
target="$2"
[[ "$target" =~ "/" ]] && target="$(wslpath -w "$target")"
shift
shift
while [[ $# -gt 0 ]]; do
	case "$1" in
		--public)
			special_folder=AllUsersDesktop
		;;
		--icon-source)
			[[ $# -ge 1 ]] && shift || help
			icon_source="$1"
		;;
		--icon-index)
			[[ $# -ge 1 ]] && shift || help
			icon_index="$1"
		;;
		--desc)
			[[ $# -ge 1 ]] && shift || help
			desc="$1"
		;;
		--args)
			[[ $# -ge 1 ]] && shift || help
			args="$1"
		;;
		--working-dir)
			[[ $# -ge 1 ]] && shift || help
			working_dir="$1"
		;;
	esac
	shift
done
def_win_env_paths TEMP
script_file="create-shortcut.vbs"
script_path="${temp_linux}/${script_file}"
cat << EOT > "$script_path"
Dim wshShell, desktop, newShortcut
Set wshShell = WScript.CreateObject("WScript.Shell")
desktop = wshShell.SpecialFolders("$special_folder")
Set newShortcut = wshShell.CreateShortcut(desktop + "\\${shortcut}.lnk")
newShortcut.TargetPath = "$target"
EOT
if [[ -n "$icon_source" && -n "$icon_index" ]]; then
	echo "newShortcut.IconLocation = \"${icon_source},${icon_index}\"" >> "$script_path"
elif [[ -n "$icon_source" ]]; then
	echo "newShortcut.IconLocation = \"${icon_source}\"" >> "$script_path"
elif [[ -n "$icon_index" ]]; then
	echo "newShortcut.IconLocation = \"${target},${icon_index}\"" >> "$script_path"
fi
[[ -n "$desc" ]] && echo "newShortcut.Description = \"$desc\"" >> "$script_path"
[[ -n "$args" ]] && echo "newShortcut.Arguments = \"$args\"" >> "$script_path"
[[ -n "$working_dir" ]] && echo "newShortcut.WorkingDirectory = \"$working_dir\"" >> "$script_path"
echo "newShortcut.Save" >> "$script_path"
cat "$script_path"
cd /mnt/c/Windows
cmd.exe /c wscript.exe "${temp_win}\\${script_file}"