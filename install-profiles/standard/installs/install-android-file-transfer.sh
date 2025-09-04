#
# Description: Install script for Android File Transfer
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

. "${ROPERDOT_DIR}/source-scripts/install-script-functions"
. "${ROPERDOT_DIR}/source-scripts/re-match"

if [[ ! -d "~/extra-apps/android-file-transfer" ]]; then
    git_url="https://github.com/whoozle/android-file-transfer-linux"
    project="android-file-transfer-linux"
    sudo apt-get install build-essential cmake libqt4-dev libfuse-dev libreadline-dev -y
	re="\"Recent Commits to [^\"]+:([^\"]+)\""
#	if [[ ! "$(print-web-file $git_url)" =~ $re ]]; then
	if ! re_match "$(print-web-file $git_url)" "$re"; then
		echo Unable to download zip of Git project from $git_url
        exit
    fi
#	branch="${BASH_REMATCH[1]}"
	branch="${re_match[1]}"
	temp_dir="$(mktemp -d)"
	pushd "$temp_dir" >/dev/null || return 1
	get-web-file "$git_url/archive/$branch.zip" "$branch.zip"
	if [[ -f "$branch.zip" ]]; then
		unpack "$branch.zip"
		cd "$project-$branch" || return 1
		mkdir build
        cd build || return 1
        cmake ..
        make
    	mv -f qt/android-file-transfer "${LOCALUSR}/bin"
       	[[ -d "$HOME/.local/share/icons" ]] || mkdir -p "$HOME/.local/share/icons"
		cp ../qt/android-file-transfer.png "$HOME/.local/share/icons"
        [[ -d "$HOME/.local/share/applications" ]] || mkdir -p "$HOME/.local/share/applications"
		cat << EOT > "$HOME/.local/share/applications/android-file-transfer.desktop"
[Desktop Entry]
Encoding=UTF-8
Version=
Name=Android File Transfer
Type=Application
Exec=${LOCALUSR}/bin/android-file-transfer
Icon=android-file-transfer.png
Terminal=false
Categories=Application
EOT
	fi
	popd >/dev/null || return 1
	rm -rf "$temp_dir"
fi
