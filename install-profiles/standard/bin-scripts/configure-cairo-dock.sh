#
# Description: (Ubuntu or Mint) Configures launchers for Cairo Dock
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
configure-cairo-dock: configure Cairo-Dock
Usage: configure-cairo-dock [application-name] [...]

configure-cairo-dock will configure Cairo-Dock creating several configuration
files in ~/.config/cairo-dock/current_theme including a launcher for each
application argument.

It will also create ~/.config/autostart/cairo-dock.desktop to cause Cairo Dock
to start when the desktop initializes.
EOT
	exit 0
fi

cairo-dock -o >/dev/null 2>&1 &
while true; do
	[[ -e ~/.config/cairo-dock/current_theme/cairo-dock.conf ]] && break
	sleep 1
done
sleep 1
killall cairo-dock >/dev/null 2>&1

temp_file=$(mktemp)

read -r -d '' sed_script << EOT
s/screen border=.*/screen border=3/
s/modules=.*/modules=Recent-Events;Animated icons;illusion;musicPlayer;dustbin;dnd2share;shortcuts;Remote-Control;Quick Browser;show_desktop/
EOT

sed -e "$sed_script" ~/.config/cairo-dock/current_theme/cairo-dock.conf > "$temp_file"
mv "$temp_file" ~/.config/cairo-dock/current_theme/cairo-dock.conf

if [[ ! -e ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf || ! -s ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf ]]; then
	cp "${ROPERDOT_DIR}/config/apps/cairo-dock/cairo-dock-simple.conf" ~/.config/cairo-dock/current_theme
fi
read -r -d '' sed_script << EOT
s/anim_hover=.*/anim_hover=;;/
s/anim_click=.*/anim_click=blink;;/
EOT

cat ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf

sed -e "$sed_script" ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf > "$temp_file"
mv "$temp_file" ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf

cat ~/.config/cairo-dock/current_theme/cairo-dock-simple.conf

if [[ -n "$player_name" ]]; then
	read -r -d '' sed_script << EOT
s/current-player=.*/current-player=${player_name}/
s/desktop-entry=.*/desktop-entry=${player_bin}/
EOT
	sed -e "$sed_script" ~/.config/cairo-dock/current_theme/plug-ins/musicPlayer/musicPlayer.conf > "$temp_file"
	mv "$temp_file" ~/.config/cairo-dock/current_theme/plug-ins/musicPlayer/musicPlayer.conf
fi

rm ~/.config/cairo-dock/current_theme/launchers/01thunderbird.desktop >/dev/null 2>&1
rm ~/.config/cairo-dock/current_theme/launchers/01ubuntu-software-center.desktop >/dev/null 2>&1

# Create launcher in ~/.config/cairo-dock/current_theme/launchers for each app
order=5.375
for app in "$@"; do
	read -r -d '' sed_script << EOT
s/Order=.*/Order=${order}/
s/Origin=.*/Origin=\/usr\/share\/applications\/${app}.desktop/
EOT
	sed -e "$sed_script" "${ROPERDOT_DIR}/config/apps/cairo-dock/launcher-template.desktop" > ~/.config/cairo-dock/current_theme/launchers/01$app.desktop
	order=$(echo $order + 0.0625 | bc)
done

[[ ! -d ~/.config/autostart ]] && mkdir ~/.config/autostart
sed -e "s/Exec=.*/Exec=cairo-dock -o/" /usr/share/applications/cairo-dock.desktop > ~/.config/autostart/cairo-dock.desktop