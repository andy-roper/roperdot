#
# Description: Interactive app installer/upgrader
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is not found and is required for running this script. Exiting..."
	exit 1
fi

. "${ROPERDOT_DIR}/source-scripts/install-functions"
. "${ROPERDOT_DIR}/source-scripts/input-functions"
. "${ROPERDOT_DIR}/source-scripts/find-pip"
[[ "$ROPERDOT_OS_FAMILY" = debian && "$ROPERDOT_DESKTOP_ENV" = windows ]] && . "${ROPERDOT_DIR}/source-scripts/win-env-functions"

# Declare global associative arrays for storing app state (bash 4+ and zsh)
if [[ $ROPERDOT_CURRENT_SHELL = bash ]]; then
	declare -A app_states
	declare -A app_indexes
	declare -A app_descriptions
else
	typeset -A app_states
	typeset -A app_indexes
	typeset -A app_descriptions
fi

# Function to check if app is present (for shell apps)
app_is_present() {
	local app="$1" binary="$2" package="$3" installer="$4" presence_command="$5"
	if [[ -n "$presence_command" ]]; then
		eval "$presence_command" && return 0
		return 1
	fi
	# if binary contains a slash, check for the presence of the file/directory
	if [[ "$binary" =~ "/" ]]; then
		[[ -e "$binary" ]] && return 0 || return 1
	fi
	if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
		[[ -z "$binary" ]] && binary="$app"
		if [[ "$binary" = "java" ]]; then
			local result="$(/usr/libexec/java_home 2>&1)"
			[[ "$result" =~ null ]] && return 1 || return 0
		elif [[ "$binary" = "git" ]]; then
			xcode-select -p >/dev/null 2>&1 && return 0 || return 1
		fi
	fi
	[[ -z "$binary" ]] && return 1
	if [[ "$binary" = ruby || "$binary" = perl || "$binary" = python || "$binary" = python3 ]]; then
		which "$binary" >/dev/null 2>&1
	elif [[ "$ROPERDOT_OS_FAMILY" = debian && "$binary" = brew ]]; then
		command brew --version >/dev/null 2>&1 || return 1
	else
		command -v "$binary" >/dev/null 2>&1
	fi
}

# Build the app list with states
build_app_list() {
	local json_file="$1" app_type="$2"
	local base_profile="standard"
	local app_count
	
	app_count=$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$json_file" count "$base_profile")
	
	local install_vars=(app app_dir app_name binary bundle_name desc disabled disable_null_stdin full_app_path include_condition install_command install_prerequisite install_script install_options list_prerequisite package package_manager personal presence_command shortcut_name shortcut_path skip sudo_not_required)
	
	for ((i=0; i<app_count; i++)); do
		# Clear previous variables
		for var in "${install_vars[@]}"; do
			unset "$var"
		done
		
		eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$json_file" "$i" "$base_profile")"
		
		# Skip if no app name
		[[ -z "$app" ]] && continue
		
		# Skip if include_condition fails
		if [[ -z "$skip" && -n "$include_condition" ]]; then
			eval "$include_condition" || skip=true
		fi
		[[ -n "$skip" ]] && continue
		
		# Determine if app is installed and upgrade type
		local is_installed=false
		local upgrade_type=""
		
		if [[ "$app_type" = "shell" ]]; then
			[[ -z "$binary" ]] && binary="$app"
			if app_is_present "$app" "$binary" "$package" "$list_prerequisite" "$presence_command"; then
				is_installed=true
			fi
		else
			# GUI app
			echo "Checking gui_app_is_present for $app"
			if gui_app_is_present "$app" "$bundle_name" "$app_dir" "$full_app_path" "$binary" "$package" "$package_manager"; then
				echo "$app is installed"
				is_installed=true
			fi
		fi
		
		# Determine upgrade type if installed
		if [[ "$is_installed" = true ]]; then
			if [[ "$install_command" =~ install-python-package ]]; then
				upgrade_type="standard"
			elif [[ -n "$install_script" || -n "$install_command" ]]; then
				upgrade_type="manual"
			else
				upgrade_type="standard"
			fi
		fi
		
		# Store app state
		app_indexes[$app]=$i
		app_descriptions[$app]="$desc"
		
		if [[ "$is_installed" = false ]]; then
			app_states[$app]="not_installed"
		elif [[ "$upgrade_type" = "manual" ]]; then
			app_states[$app]="manual_upgrade"
		else
			app_states[$app]="can_upgrade"
		fi
	done
}

# Show app menu with fzf
show_app_menu() {
	local menu_items=()
	local app
	
	# Build menu items sorted alphabetically
	if [[ $ROPERDOT_CURRENT_SHELL = bash ]]; then
		# bash: iterate through keys
		for app in "${!app_states[@]}"; do
			local state="${app_states[$app]}"
			local desc="${app_descriptions[$app]}"
			local display_line=""
			
			[[ -n "$desc" ]] && desc=": $desc"
			case "$state" in
				not_installed)  display_line="${app}${desc}" ;;
				manual_upgrade) display_line="${app} [manual upgrade]${desc}" ;;
				can_upgrade)    display_line="${app} [upgrade]${desc}" ;;
			esac
			
			menu_items+=("$display_line")
		done
	else
		# zsh: iterate through keys
		for app in "${(@k)app_states}"; do
			local state="${app_states[$app]}"
			local desc="${app_descriptions[$app]}"
			local display_line=""
			
			[[ -n "$desc" ]] && desc=": $desc"
			case "$state" in
				not_installed)  display_line="${app}${desc}" ;;
				manual_upgrade) display_line="${app} [manual upgrade]${desc}" ;;
				can_upgrade)    display_line="${app} [upgrade]${desc}" ;;
			esac
			
			menu_items+=("$display_line")
		done
	fi
	
	# Sort menu items alphabetically
	if [[ $ROPERDOT_CURRENT_SHELL = bash ]]; then
		IFS=$'\n' menu_items=($(sort <<<"${menu_items[*]}"))
		unset IFS
	else
		# zsh
		menu_items=(${(f)"$(printf '%s\n' "${menu_items[@]}" | sort)"})
	fi
	
	# Show fzf menu
	local selected=$(printf '%s\n' "${menu_items[@]}" | fzf --height=40% --reverse --prompt="Select app: ")
	
	# Extract app name from selection (before colon or bracket)
	if [[ -n "$selected" ]]; then
		# Extract app name (everything before : or [)
		local app_name=$(echo "$selected" | sed -E 's/^([^:[:space:]]+(\[[^]]+\])?)[[:space:]]*:.*/\1/' | sed -E 's/[[:space:]]*\[.*//')
		echo "$app_name"
	fi
}

# Install an app using install-apps methodology
install_app_function() {
	local json_file="$1" app_index="$2" app_type="$3"
	local base_profile="standard"
	local install_vars=(app app_dir app_name binary bundle_name desc disabled disable_null_stdin full_app_path include_condition install_command install_prerequisite install_script install_options list_prerequisite package package_manager personal presence_command shortcut_name shortcut_path skip sudo_not_required)
	
	# Clear variables and reload app data
	for var in "${install_vars[@]}"; do
		unset "$var"
	done
	
	eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$json_file" "$app_index" "$base_profile")"
	
	# Set defaults
	[[ -z "$binary" ]] && binary="$app"
	[[ -z "$package" ]] && package="$binary"
	
	echo
	echo "Installing $app..."
	echo
	
	# Define install function based on app configuration
	if [[ -n "$install_script" ]]; then
		if [[ -n "$install_options" ]]; then
			eval "install_func() { $ROPERDOT_CURRENT_SHELL \"${ROPERDOT_DIR}/install-profiles/$profile/installs/$install_script\" $install_options; }"
		else
			eval "install_func() { $ROPERDOT_CURRENT_SHELL \"${ROPERDOT_DIR}/install-profiles/$profile/installs/$install_script\"; }"
		fi
	elif [[ -n "$install_command" ]]; then
		local re=";\$"
		[[ "$install_command" =~ $re ]] || install_command="$install_command;"
		eval "install_func() { $install_command }"
	else
		# Standard package manager install
		if [[ "$app_type" = "gui" && "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
			# WSL GUI app
			install_func() { choco.exe install -y --ignore-pending-reboot "$package"; }
		elif [[ -n "$list_prerequisite" ]]; then
			# Use specified package manager
			case "$list_prerequisite" in
				brew)
					install_func() { brew install "$package"; }
					;;
				apt-get|apt)
					install_func() { sudo apt-get -y install "$package"; }
					;;
				pip3)
					install_func() { pip3 install "$package"; }
					;;
				choco)
					install_func() { choco.exe install -y --ignore-pending-reboot "$package"; }
					;;
				*)
					echo "Error: Unknown package manager: $list_prerequisite"
					return 1
					;;
			esac
		else
			# Use default package manager for OS
			case "$ROPERDOT_OS_ENV" in
				darwin)
					install_func() { brew install "$package"; }
					;;
				ubuntu|debian|mint)
					install_func() { sudo apt-get -y install "$package"; }
					;;
			esac
		fi
	fi
	
	# Execute install with retry logic
	while : ; do
		if install_func; then
			echo "Install of $app complete."
			exit 0
		fi
		if [[ $? = 194 ]]; then  # Chocolatey reboot pending
			echo "Install of $app complete."
			exit 0
		fi
		
		echo -n "Install of $app failed with return code $?. (R)etry, (a)bort installing this app or (c)ancel? "
		read REPLY
		echo
		[[ "$REPLY" =~ ^[aA]$ ]] && return 0
		[[ "$REPLY" =~ ^[cC]$ ]] && return 1
		[[ ! "$REPLY" =~ ^[rR]$ ]] && echo "Invalid choice. Please enter R, A, or C."
	done
}

# Upgrade an app using package manager
upgrade_app_function() {
	local json_file="$1" app_index="$2" app_type="$3"
	local base_profile="standard"
	local install_vars=(app app_dir app_name binary bundle_name desc disabled disable_null_stdin full_app_path include_condition install_command install_prerequisite install_script install_options list_prerequisite package package_manager personal presence_command shortcut_name shortcut_path skip sudo_not_required)
	
	# Clear variables and reload app data
	for var in "${install_vars[@]}"; do
		unset "$var"
	done
	
	eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$json_file" "$app_index" "$base_profile")"
	
	# Set defaults
	[[ -z "$package" ]] && package="$binary"
	[[ -z "$package" ]] && package="$app"
	
	echo -n "\nUpgrading $app...\n"
	
	# Determine which package manager to use
	local upgrade_cmd=""
	
	if [[ "$install_command" =~ install-python-package ]]; then
		local python_package=$(echo "$install_command" | sed -E 's/.*install-python-package[[:space:]]+([^[:space:];]+).*/\1/')
		upgrade_cmd="$pip_bin install --upgrade $python_package"
	elif [[ -n "$list_prerequisite" ]]; then
		# Use specified package manager
		case "$list_prerequisite" in
			brew)
				upgrade_cmd="brew upgrade $package"
				;;
			apt-get|apt)
				upgrade_cmd="sudo apt-get -y --only-upgrade install $package"
				;;
			choco)
				upgrade_cmd="choco.exe upgrade -y $package"
				;;
			*)
				echo "Error: Unknown package manager: $list_prerequisite"
				return 1
				;;
		esac
	else
		# Use default package manager for OS
		if [[ "$app_type" = "gui" && "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
			# WSL GUI app
			upgrade_cmd="choco.exe upgrade -y $package"
		else
			case "$ROPERDOT_OS_ENV" in
				darwin)
					upgrade_cmd="brew upgrade $package"
					;;
				ubuntu|debian|mint)
					upgrade_cmd="sudo apt-get -y --only-upgrade install $package"
					;;
			esac
		fi
	fi
	
	if [[ -z "$upgrade_cmd" ]]; then
		echo "Error: Could not determine upgrade command"
		return 1
	fi
	
	# Execute upgrade
	eval "$upgrade_cmd"
	local return_code=$?
	
	echo
	if [[ $return_code -eq 0 ]]; then
		echo "Upgrade completed successfully."
	else
		echo "Upgrade failed with return code $return_code."
	fi
	
	return $return_code
}

# Detect OS if not already done
[[ -z "$ROPERDOT_OS_ENV" ]] && . "${ROPERDOT_DIR}/source-scripts/detect-os"
[[ "$is_admin" == "True" ]] && export HAS_ADMIN_RIGHTS=true

# Set profile
export profile=${profile:-standard}

# Check for fzf
if ! command -v fzf >/dev/null 2>&1; then
	echo "Error: fzf is required but not installed."
	echo "Please install fzf first."
	exit 1
fi

# Check for python3
if ! command -v python3 >/dev/null 2>&1; then
	echo "Error: python3 is required but not installed."
	echo "Please install python3 first."
	exit 1
fi

# Ask user: shell or GUI app
echo "What type of application do you want to manage?"
echo "1) Shell application"
echo "2) GUI application"
echo
echo -n "Enter choice [1-2]: "
read app_type_choice
echo

case "$app_type_choice" in
	1) app_type="shell"	;;
	2) app_type="gui" ;;
	*)
		echo "Invalid choice. Exiting."
		exit 1
		;;
esac

# Determine JSON file based on OS and app type
case "$ROPERDOT_OS_ENV" in
	darwin)
		if [[ "$app_type" = "shell" ]]; then
			json_file="macOS-shell-apps.json"
		else
			json_file="macOS-gui-apps.json"
		fi
		;;
	ubuntu|debian)
		if [[ "$app_type" = "shell" ]]; then
			json_file="ubuntu-shell-apps.json"
		else
			if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
				if [[ "$ROPERDOT_DESKTOP_ENV" = windows ]]; then
					if ! command -v choco.exe >/dev/null 2>&1; then
						echo "Chocolatey must be installed to install GUI apps on Windows. Exiting..."
						exit 1
					fi
				fi
				if [[ -z "$HAS_ADMIN_RIGHTS" ]]; then
					echo "You must start your shell as an administrator to install GUI applications on Windows. Exiting..."
					exit 1
				fi
				json_file="windows-gui-apps.json"
			else
				json_file="ubuntu-gui-apps.json"
			fi
		fi
		;;
	mint)
		if [[ "$app_type" = "shell" ]]; then
			json_file="mint-shell-apps.json"
		else
			json_file="mint-gui-apps.json"
		fi
		;;
	*)
		echo "Unsupported OS: $ROPERDOT_OS_ENV"
		exit 1
		;;
esac

echo "Loading applications from $json_file..."

# Build app list with states
build_app_list "$json_file" "$app_type"

# Check if any apps were found
if [[ $ROPERDOT_CURRENT_SHELL = bash ]]; then
	if [[ ${#app_states[@]} -eq 0 ]]; then
		echo "No applications found in $json_file"
		exit 0
	fi
else
	if [[ ${#app_states} -eq 0 ]]; then
		echo "No applications found in $json_file"
		exit 0
	fi
fi

while : ; do
	# Show selection menu
	selected_app=$(show_app_menu)

	if [[ -z "$selected_app" ]]; then
		echo "No application selected. Exiting."
		exit 0
	fi

	# Get app state and index
	app_state="${app_states[$selected_app]}"
	app_index="${app_indexes[$selected_app]}"

	# Perform action based on state
	case "$app_state" in
		not_installed)
			install_app_function "$json_file" "$app_index" "$app_type"
			;;
		can_upgrade)
			upgrade_app_function "$json_file" "$app_index" "$app_type"
			;;
		manual_upgrade)
			cat <<EOT
This app uses a custom install script or command and cannot be automatically upgraded.

To upgrade $selected_app, please:
1. Check the $json_file JSON file
2. Review the install_script or install_command field
3. Look at the install script in installs if relevant
4. Upgrade the application accordingly

Note: Install scripts are not idempotent and cannot be re-run to upgrade.
EOT
			;;
		*)
			echo "Error: Unknown app state: $app_state"
			exit 1
			;;
	esac

	ask_yn_n "Install another application" || break
done