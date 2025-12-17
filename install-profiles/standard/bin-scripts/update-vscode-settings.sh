#
# Description: Updates Visual Studio Code settings.json
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
update-vscode-settings: updates Visual Studio Code settings.json
Usage: update-vscode-settings

The settings.json file in roperdot/config/color-schemes/source/<scheme>/VSCode
will be used to update values in settings.json for Visual Studio Code such as
* terminal.integrated.fontFamily
* terminal.integrated.fontSize
* terminal.integrated.shell.linux or terminal.integrated.shell.osx
* workbench.colorCustomizations

The scheme used is based on the value of ROPERDOT_COMMON_COLOR_SCHEME, or of
ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME if ROPERDOT_COMMON_COLOR_SCHEME is not set.

For Windows, the Windows environment will be updated if the windows_install env
var is set. The WSL environment will be updated if the standard_install env var
is set.
EOT
	exit 0
fi

update_setting () {
	$python_bin "$ROPERDOT_DIR/bin/set-values-in-json" "$vs_code_settings_path/settings.json" "$@"
}

update_settings () {
	local vs_code_settings_path="$1"
	if [[ ! -d "$vs_code_settings_path" ]] && ! mkdir -p "$vs_code_settings_path"; then
		echo "Error creating directory $vs_code_settings_path"
		exit 1
	fi

	if [[ -f "$vs_code_settings_path/settings.json" ]]; then
		echo "Backing up $vs_code_settings_path/settings.json"
		mv "$vs_code_settings_path/settings.json" "$vs_code_settings_path/settings.json.bak"
	fi

	. "${ROPERDOT_DIR}/source-scripts/find-pip"

	echo "Updating $vs_code_settings_path/settings.json"
	update_setting @"$ROPERDOT_DIR/config/color-schemes/source/$color_scheme/VSCode/settings.json"

	update_setting "copyOnSelect" true
	update_setting "workbench.colorTheme" "Default Dark+"
	update_setting "terminal.integrated.scrollback" 10000

	if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
		if [[ -n "$PROCESSING_ZSH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.osx" '"zsh":{"path":"/usr/local/bin/zsh"}'
		fi
		if [[ -n "$PROCESSING_BASH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.osx" '"bash":{"path":"/usr/local/bin/bash"}'
		fi
		# if [[ -n "$PROCESSING_ZSH" ]]; then
		# 	update_setting "terminal.integrated.defaultProfile.osx" "zsh"
		# else
		# 	update_setting "terminal.integrated.defaultProfile.osx" "bash"
		# fi
		update_setting "terminal.integrated.defaultProfile.osx" "$ROPERDOT_CURRENT_SHELL"
	elif [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
		if [[ -n "$PROCESSING_ZSH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.windows" '"WSL zsh":{"path":"${env:windir}\\System32\\wsl.exe","args":["zsh"],"icon":"terminal-ubuntu-wsl"}'
		fi
		if [[ -n "$PROCESSING_BASH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.windows" '"WSL bash":{"path":"${env:windir}\\System32\\wsl.exe","icon":"terminal-ubuntu-wsl"}'
		fi
		# if [[ "$PROCESSING_ZSH" = zsh ]]; then
		# 	update_setting "terminal.integrated.defaultProfile.windows" "WSL zsh"
		# else
		# 	update_setting "terminal.integrated.defaultProfile.windows" "WSL bash"
		# fi
		update_setting "terminal.integrated.defaultProfile.windows" "WSL $ROPERDOT_CURRENT_SHELL"
	else
		if [[ -n "$PROCESSING_ZSH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.linux" '"zsh":{"path":"/bin/zsh"}'
		fi
		if [[ -n "$PROCESSING_BASH" ]]; then
			update_setting --add-to-hashtable "terminal.integrated.profiles.linux" '"bash":{"path":"/bin/bash"}'
		fi
		# if [[ "$PROCESSING_ZSH" = zsh ]]; then
		# 	update_setting "terminal.integrated.defaultProfile.linux" "zsh"
		# else
		# 	update_setting "terminal.integrated.defaultProfile.linux" "bash"
		# fi
		update_setting "terminal.integrated.defaultProfile.linux" "$ROPERDOT_CURRENT_SHELL"
	fi

	if [[ ",$install_groups," == *,java-dev,* ]]; then
		update_setting "java.import.gradle.home" "$HOME/.sdkman/candidates/gradle/current"
	    update_setting "java.import.gradle.java.home" "$HOME/.sdkman/candidates/java/current"
	    update_setting "java.jdt.ls.vmargs" "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx4G -Xms100m -Xlog:disable"
	    update_setting "java.import.gradle.wrapper.enabled" false
	    update_setting --add-to-hashtable "java.test.config" '"name":"TestConfigWithVmArgs"'
	    update_setting --add-to-hashtable "java.test.config" '"vmArgs":["--add-opens=java.base/java.lang=ALL-UNNAMED","--add-opens=java.base/java.math=ALL-UNNAMED"]'
	fi
}

if [[ -z "$color_scheme" ]]; then
	color_scheme="$ROPERDOT_COMMON_COLOR_SCHEME"
	[[ "$color_scheme" = default ]] && color_scheme="$ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME"
fi
if [[ "$ROPERDOT_CURRENT_SHELL" = zsh ]]; then
	shell_path="$(which zsh)"
else
	shell_path="$(which bash)"
fi
if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	update_settings "/Users/${USER}/Library/Application Support/Code/User"
elif [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	. "${ROPERDOT_DIR}/source-scripts/win-env-functions"
	[[ -n "$windows_install" ]] && update_settings "$(win_env_linux_path APPDATA)/Code/User"
	[[ -n "$standard_install" ]] && update_settings "$(win_env_linux_path USERPROFILE)/.vscode"
else
	update_settings ~/.config/Code/User
fi
exit 0