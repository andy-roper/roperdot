#
# Description: (Gnome) Configures application launchers for Docky
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# Note: paths for gconftool are relative to ~/.gconf
# http://www.go-docky.com/index_title_GConf_Settings.html

# First item in launcher list:
# $LOCALUSR/share/applications/spacer.desktop

# Also see if I can move the "start bar" panel to the top with a command

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
configure-docky: 
Usage: configure-docky

configure-docky sets some basic settings for Docky, adds launchers for several
applications and for clock and trash, and sets up Docky to start when the
desktop initializes.
EOT
	exit 0
fi

add_to_list () {
	for app; do
		if [[ -e /usr/share/applications/$app.desktop ]]; then
			if [[ -n "$launcher_list" ]]; then
				launcher_list="${launcher_list},file:///usr/share/applications/$app.desktop"
			else
				launcher_list="[file:///usr/share/applications/$app.desktop"
			fi
			return
		fi
	done
}

[[ ! -d ~/.gconf ]] && mkdir ~/.gconf
[[ ! -d ~/.gconf/apps ]] && mkdir ~/.gconf/apps
docky >/dev/null 2>&1 &
while true; do
	docky_path=$(find ~/.gconf/apps -maxdepth 1 -type d -name "docky*")
	[[ -n "$docky_path" && -e "$docky_path/Docky/Interface/DockPreferences/Dock1/%gconf.xml" ]] && break
	sleep 1
done
killall docky >/dev/null 2>&1

[[ ! -d "${LOCALUSR}/share/applications" ]] && mkdir "${LOCALUSR}/share/applications"
[[ ! -d "${LOCALUSR}/share/icons" ]] && mkdir "${LOCALUSR}/share/icons"

# Create spacer item
echo << EOT > "${LOCALUSR}/share/applications/spacer.desktop"
[Desktop Entry]
Name=_
Type=Application
Exec=echo >/dev/null
Icon=transparent-32x32.png
Terminal=false
EOT

# Copy transparent png to .local
cp "${ROPERDOT_DIR}/resources/transparent-32x32.png" "${LOCALUSR}/share/icons"

echo configuring docky
gconftool-2 -s /apps/docky-2/Docky/Items/DockyItem/ShowDockyItem -t bool false
gconftool-2 -s /apps/docky-2/Docky/Interface/DockPreferences/Dock1/Position -t string "Left"
gconftool-2 -s /apps/docky-2/Docky/Interface/DockPreferences/Dock1/PanelMode -t bool true
gconftool-2 -s /apps/docky-2/Docky/Interface/DockPreferences/Dock1/Autohide -t string "None"
gconftool-2 -s /apps/docky-2/Clock/ClockDockItem/ShowDigital -t "bool" true

add_to_list google-chrome firefox
add_to_list gnome-terminal
add_to_list spacefm nemo
add_to_list sublime_text notepadqq atom xed

if [[ -n "$launcher_list" ]]; then
	gconftool-2 -s /apps/docky-2/Docky/Interface/DockPreferences/Dock1/Launchers -t list --list-type string "${launcher_list}]"
fi

gconftool-2 -s /apps/docky-2/Docky/Interface/DockPreferences/Dock1/Plugins -t list --list-type string "[Clock,Trash]"

#if command -v xdotool >/dev/null 2>&1; then
#	gconftool-2 -s /apps/docky-2/Docky/Items/DockyItem/DockyItemCommand -t string "xdotool key -clearmodifiers alt+F1"
#fi

echo catting file before starting docky
cat ~/.gconf/apps/docky-2/Docky/Interface/DockPreferences/Dock1/%gconf.xml
echo starting docky
docky >/dev/null 2>&1 &
echo catting file after starting docky
cat ~/.gconf/apps/docky-2/Docky/Interface/DockPreferences/Dock1/%gconf.xml

cp /usr/share/applications/docky.desktop ~/.config/autostart