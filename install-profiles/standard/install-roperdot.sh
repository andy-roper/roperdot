export INSTALLING_ROPERDOT=true

[[ "$ROPERDOT_CURRENT_SHELL" = zsh ]] && setopt KSH_ARRAYS

[[ -z "$CALLED_FROM_INSTALL" ]] && echo "Setting up for the install..."

. "${ROPERDOT_DIR}/source-scripts/input-functions"
. "${ROPERDOT_DIR}/source-scripts/realpath"
if [[ -z "$CALLED_FROM_INSTALL" && "$ROPERDOT_DIR" != "$(realpath ~/roperdot)" ]]; then
	echo "You are installing roperdot from a directory other than ~/roperdot."
	ask_yn_n "Are you sure you want to continue"
	echo
	[[ $REPLY =~ ^[yY]$ ]] || exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/install-script-functions"
. "${ROPERDOT_DIR}/source-scripts/install-functions"
. "${ROPERDOT_DIR}/source-scripts/nice-copy"
. "${ROPERDOT_DIR}/source-scripts/re-match"
. "${ROPERDOT_DIR}/source-scripts/backup-file"
. "${ROPERDOT_DIR}/source-scripts/update-config-files"
. "${ROPERDOT_DIR}/source-scripts/windows-terminal-functions"

# Have to use \x1B instead of \e for out-of-the-box Mac bash compatibility
export warning_text=$(echo -e '\x1B[0;91m')
export normal_text=$(echo -e '\x1B[0m')

[[ "$ROPERDOT_CURRENT_SHELL" = zsh ]] && setopt ksh_glob || shopt -s extglob

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	. "${ROPERDOT_DIR}/source-scripts/win-env-functions"
	. "${ROPERDOT_DIR}/source-scripts/win-reg-functions"
	. "${ROPERDOT_DIR}/source-scripts/windows-terminal-functions"
	def_win_env_linux_path LOCALAPPDATA app_local_path
	def_win_env_linux_path PROGRAMFILES program_files_path
	def_win_env_linux_path "PROGRAMFILES(X86)" program_files_86_path
	def_win_env_linux_path USERPROFILE user_profile

	if ! windows_terminal_settings_location; then
		read -p "It's recommended to run Windows Terminal at least once before continuing to initialize its settings.json so it can be updated during the install."
	fi
fi

export ROPERDOT_PROFILES=standard profiles=standard
. "${ROPERDOT_DIR}/source-scripts/copy-scripts"
[[ "$ROPERDOT_CURRENT_SHELL" = bash ]] && export PATH="${ROPERDOT_DIR}/bin-bash:$PATH" || export PATH="${ROPERDOT_DIR}/bin-zsh:$PATH"

#export LOCALUSR="${ROPERDOT_DIR}/local-usr"
export LOCAL=~/.local
export LOCALUSR=$LOCAL/usr
[[ -d "${LOCALUSR}/bin" ]] || mkdir -p "${LOCALUSR}/bin"

ask_number () {
	local text="$1" max_num="$2" recommended="$3" default="$4" answer
	if [[ -n "$accept_recommended" && -n "$recommended" ]]; then
		echo "${text}? ${recommended}"
		return "$recommended"
	else
		echo
		while [[ -z "$answer" || "$answer" -gt "$max_num" ]]; do
			read_input "${text} [default is $default]?"
			answer="$REPLY"
			[[ -z "$answer" ]] && answer="$default"
		done
		return "$answer"
	fi
}

# Usage: symlink <original_path> <link_path>
symlink () {
	local overwritten=""
	[[ -e "$2" || -h "$2" ]] && overwritten="(overwritten)"
	local src="$(realpath "$1")"
	local dst="$(realpath -s "$2")"
	echo "Linking $1 to $2 $overwritten"
	ln -sf "$src" "$dst"
}

# Usage: symlink_admin_only_on_win <original_path> <link_path>
symlink_admin_only_on_win () {
	if [[ "$ROPERDOT_DESKTOP_ENV" != "windows" ]]; then
		symlink "$1" "$2"
		return
	fi
	if [[ -e "$2" || -h "$2" ]]; then
		if [[ -h "$2" ]]; then
			rm -f "$2"
			local link_msg="$1 to $2 (overwritten)"
		else
			backup_file "$2"
			local link_msg="$1 to $2"
		fi
	else
		local link_msg="$1 to $2"
	fi
	if [[ -n "$HAS_ADMIN_RIGHTS" ]]; then
		if [[ "$ROPERDOT_OS_FAMILY" = debian ]]; then
			# Windows Subsystem for Linux (WSL)
			symlink "$1" "$2"
		fi
	else
		echo "Copying $link_msg"
		cp "$1" "$2"
	fi
}

execute_with_retry () {
	local message="$1"
	local executing=true
	while [[ -n "$executing" ]]; do
		execute_command && unset executing
		if [[ -n "$executing" ]]; then
			read_input "$message (R)etry or (a)bort update?"
			[[ "$REPLY" =~ ^[aA]$ ]] && unset executing
		fi
	done
}

[[ -z "$CALLED_FROM_INSTALL" && -n "$resuming" && -z "$resume_step" && -f ~/.roperdot-resume-step ]] && export resume_step="$(cat ~/.roperdot-resume-step)"

cd "$ROPERDOT_DIR" || return 1
	
export PATH="$PATH:${ROPERDOT_DIR}/bin"

[[ -d "${ROPERDOT_DIR}/install-source" ]] && export INSTALLSOURCE="${ROPERDOT_DIR}/install-source"

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	export rd_systemroot="$(win_env_linux_path SYSTEMROOT)"
	export rd_program_files="$(win_env_linux_path PROGRAMFILES)"
	export rd_program_files_x86="$(win_env_linux_path "PROGRAMFILES(X86)")"
fi

save_resume_point 1

if [[ "$ROPERDOT_OS_ENV" = darwin ]]; then
	if [[ -n "$zsh_present" ]]; then
		if command -v bash >/dev/null 2>&1; then
		    options=(
		        "Upgrade zsh and install roperdot for bash and zsh"
		        "Upgrade zsh and install roperdot for it"
		        "Install roperdot for zsh"
		        "Install roperdot for bash"
		    )
		    
		    selection=$(gum choose --header="Choose your installation option:" "${options[@]}")
		    if [[ -z "$selection" ]]; then
		    	echo "No choice was made; defaulting to upgrading zsh and installing roperdot for bash and zsh"
		    	selection="bash and zsh"
		    fi
		    
		    case "$selection" in
		        *"bash and zsh"*)
		            upgrade_zsh=true
		            PROCESSING_BASH=true
		            PROCESSING_ZSH=true
		            ;;
		        *"Upgrade zsh"*)
		            upgrade_zsh=true
		            PROCESSING_ZSH=true
		            ;;
		        *"zsh"*)
		            PROCESSING_ZSH=true
		            ;;
		        *"bash"*)
		            PROCESSING_BASH=true
		            ;;
		    esac
		else
		    options=(
		        "Upgrade zsh and install roperdot for it"
		        "Install roperdot for zsh"
		    )
		    
		    selection=$(gum choose --header="Choose your installation option:" "${options[@]}")
		    if [[ -z "$selection" ]]; then
		    	echo "No choice was made; defaulting to upgrading zsh and installing roperdot for it"
		    	selection="Upgrade"
		    fi
		    
		    case "$selection" in
		        *"Upgrade"*)
		            upgrade_zsh=true
		            PROCESSING_ZSH=true
		            ;;
		        *"Install"*)
		            PROCESSING_ZSH=true
		            ;;
		    esac
		fi
	else
		PROCESSING_BASH=true
	fi

	[[ -z "$PROCESSING_ZSH" && -z "$PROCESSING_BASH" ]] && echo "Aborting install." && exit 0
	if [[ -n "$upgrade_zsh" ]]; then
		if command -v brew >/dev/null 2>&1; then
			if [[ -z "$brew_updated" && -z "$brew_newly_installed" ]]; then
				if ask_yn_n "Update and upgrade brew" y; then
					echo Updating brew
					brew update
					echo Upgrading brew
					brew upgrade
					export brew_updated=true
				else
					brew_updated=false
				fi
			fi
		else
			if ask_yn_y "${warning_text}Install homebrew (needed to install shells and multiple other apps)${normal_text}" y; then
				[[ -n "$show_start_times" ]] && echo "Start time: $(date +"%r")"
				$install_shell -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
			fi
			if command -v brew >/dev/null 2>&1; then
				export brew_newly_installed=true
			else
				echo "Brew was not installed. Aborting the roperdot install."
				exit 0
			fi
		fi
		export PACKAGE_MANAGER=brew
		echo -e "Upgrading zsh\n"
		$install_shell "${ROPERDOT_DIR}/install-profiles/standard/installs/install-zsh" || exit 1
		export zsh_newly_installed=true
	fi
elif ! command -v brew >/dev/null 2>&1; then
	cat <<EOT
Linuxbrew is needed by multiple installs to install applications.
curl and ruby will also need to be installed if they are not present.
EOT
	if ask_yn_y "Install brew" y; then
		if ! command -v curl >/dev/null 2>&1; then
			execute_command () { sudo apt install curl; }
			execute_with_retry "Install of curl failed."
		fi
		if ! command -v ruby >/dev/null 2>&1; then
			execute_command () { sudo apt install ruby; }
			execute_with_retry "Install of ruby failed."
		fi
		execute_command () { $install_shell "${ROPERDOT_DIR}/install-profiles/standard/installs/install-linuxbrew"; }
		execute_with_retry "Install of Linuxbrew failed."
	else
		echo "Some application installs will be skipped since Linuxbrew is not installed."
	fi
fi

if [[ -d /home/linuxbrew/.linuxbrew/bin && ! "$PATH" =~ linuxbrew ]]; then
	export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
fi

if command -v python3 >/dev/null 2>&1; then
	[[ "$ROPERDOT_OS_ENV" = darwin ]] && echo -e "If you're prompted to install command line developer tools in order to use python3, please choose to install them and wait for the install to finish before continuing with the roperdot install.\n"
	export python_version=$(python3 -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))' 2>/dev/null) && export python_bin=python3
	if [[ -n $python_bin ]]; then
		if [[ -n "$PYTHONPATH" ]]; then
			export PYTHONPATH="${PYTHONPATH}:${LOCALUSR}/lib/python${python_version}"
		else
			export PYTHONPATH="${LOCALUSR}/lib/python${python_version}"
		fi
	fi
fi
if [[ -z $python_bin ]] && command -v python >/dev/null 2>&1; then
	export python_version=$(python -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))' 2>/dev/null) && export python_bin=python
	if [[ -n $python_bin ]]; then
		if [[ -n "$PYTHONPATH" ]]; then
			export PYTHONPATH="${PYTHONPATH}:${LOCALUSR}/lib/python${python_version}"
		else
			export PYTHONPATH="${LOCALUSR}/lib/python${python_version}"
		fi
	fi
fi

# Fix brew "parent directory is world writable but not sticky" error in WSL
if [[ "$ROPERDOT_OS_FAMILY" = debian && "$ROPERDOT_DESKTOP_ENV" = windows ]]; then
	umask 022
	# Need to manually create the .cache directory or else it ends up being owned by root
	[[ -d ~/.cache ]] || mkdir ~/.cache
fi

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	if [[ -z "$HAS_ADMIN_RIGHTS" ]]; then
		cat <<EOT
${warning_text}Your terminal session should be run as an administrator for this installation
if you plan to install applications with it. Please reopen your session as an
administrator and restart the install.${normal_text}

EOT
	fi
	
	if ! command -v choco >/dev/null 2>&1 && ! command -v choco.exe >/dev/null 2>&1; then
		cat <<EOT
${warning_text}Chocolatey (https://chocolatey.org/) is used by the installer to install git
and GUI applications. It's strongly advised that you install Chocolatey before continuing
this install.${normal_text}

EOT
	    if ask_yn_y "Install Chocolatey now" y; then
	        powershell.exe -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
	        export PATH="$PATH:/mnt/c/ProgramData/chocolatey/bin"
	    else
	        echo "Continuing with the install, but GUI installations will be skipped."
	    fi
	fi
fi

[[ -d "${ROPERDOT_DIR}/extra-bin" ]] || mkdir "${ROPERDOT_DIR}/extra-bin"
#	[[ -d "${ROPERDOT_DIR}/extra-source" ]] || mkdir "${ROPERDOT_DIR}/extra-source"
[[ "$PATH" =~ extra-bin ]] || export PATH="$PATH:${ROPERDOT_DIR}/extra-bin"
[[ -d "${LOCALUSR}/bin" && ! "$PATH" =~ local-usr ]] && export PATH="$PATH:${LOCALUSR}/bin"

if [[ -d /home/linuxbrew/.linuxbrew/bin && ! "$PATH" =~ linuxbrew ]]; then
	export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
fi

# Check for gum
if ! command -v gum >/dev/null 2>&1; then
	if ask_yn_y "The gum package is required for accepting user input and selections. Install it" y; then
		if command -v brew >/dev/null 2>&1; then
			brew install gum
		elif [[ "$ROPERDOT_OS_NAME" = "ubuntu" || "$ROPERDOT_OS_NAME" = "debian" ]]; then
			sudo mkdir -p /etc/apt/keyrings
			curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
			echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
			sudo apt update && sudo apt install gum
		else
			echo "Unable to install gum; exiting the install"
			exit 0
		fi
	else
		echo "Exiting the install"
		exit 0
	fi
fi

# Disregard sudo access unless the user has full access since it's almost certain if the
# user's sudo access has been limited that they won't have the ability to perform
# installs
if [[ -n "$has_sudo_debug" ]]; then
	if [[ "$has_sudo_debug" = "false" ]]; then
		unset has_sudo
	else
		has_sudo=$has_sudo_debug
	fi
	export has_sudo
elif [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	groups $USER | grep -q admin && export has_sudo=true
else
	echo Checking for sudo access...
#	sudo -l | tee /dev/tty | grep "ALL) ALL" >/dev/null && export has_sudo=true
#	sudo -l | grep "ALL) ALL" >/dev/null && export has_sudo=true
	groups $USER | grep -qE '\b(sudo|adm|admin|wheel)\b' && export has_sudo=true
fi

if [[ -n "$resume_step" && "$resume_step" -gt 6 ]]; then
	skip_to_installs=true
elif [[ -e ~/roperdot-loader ]]; then
	ask_yn_n "Skip setup and proceed directly to app installs" && skip_to_installs=true
fi

if [[ -z "$skip_to_installs" ]]; then
	[[ -d "${ROPERDOT_DIR}/extra-bin" ]] && echo "$PATH" | grep -qv "extra-bin" && export PATH="$PATH:${ROPERDOT_DIR}/extra-bin"

	save_resume_point 2
	if [[  -z "$resume_step" || "$resume_step" -le 2 ]]; then
		if [[ "$ROPERDOT_OS_ENV" = darwin ]]; then
			if command -v brew >/dev/null 2>&1; then
				if [[ -z "$brew_updated" ]]; then
					if ask_yn_n "Update and upgrade brew" y; then
						echo Updating brew
						brew update
						echo Upgrading brew
						brew upgrade
						export brew_updated=true
					else
						export brew_updated=false
					fi
				fi
			elif [[ -z "$brew_newly_installed" ]]; then
				if ask_yn_y "${warning_text}Install homebrew (needed to install multiple other apps)${normal_text}" y; then
					# ruby -e "$(print-web-file https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
					$install_shell -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
				fi
				if command -v brew >/dev/null 2>&1; then
					export brew_newly_installed=true
				else
					echo "Brew was not successfully installed. Aborting the roperdot install."
					exit 1
				fi
			fi
			if [[ -z "$has_sudo" ]] && ! xcode-select -p &>/dev/null; then
			    echo "Installing Command Line Tools..."
			    xcode-select --install
			    # Wait for installation to complete
			    until xcode-select -p &>/dev/null; do
			        sleep 5
			    done
			fi
		fi
	fi

	locale_needs_setup=
	if [[ "$ROPERDOT_OS_FAMILY" == "debian" ]]; then
		if ! dpkg -l locales &>/dev/null; then
		    locale_needs_setup=true
		elif ! locale -a 2>/dev/null | grep -q "en_US.UTF-8"; then
		    # Package exists but locale not generated
		    locale_needs_setup=true
		fi
	fi

	if [[ -n "$locale_needs_setup" ]]; then
		if [[ -n "$has_sudo" ]]; then
		    if ask_yn_y "Set up en_US.UTF-8 as the default locale" y; then
		    	echo "Installing and configuring locale..."
		        sudo apt install locales
		        sudo locale-gen en_US.UTF-8
		        sudo update-locale LANG=en_US.UTF-8
		        echo "Locale setup complete. You may need to restart your shell."
		    fi
		else
	        echo "Skipping locale setup due to lack of sudo access."
    	    echo "To set it up manually: sudo apt install locales && sudo locale-gen en_US.UTF-8"
		fi
	fi

	case $ROPERDOT_OS_FAMILY in
		darwin)
			command -v brew > /dev/null 2>&1 && export PACKAGE_MANAGER=brew ;;
		debian)
			export PACKAGE_MANAGER=apt-get ;;
		rhel)
			export PACKAGE_MANAGER=yum ;;
	esac

	if [[ "$ROPERDOT_OS_ENV" = darwin ]]; then
		if [[ -z "$PROCESSING_BASH" && -z "$PROCESSING_ZSH" ]]; then
			if [[ "$ROPERDOT_CURRENT_SHELL" = bash ]]; then
				PROCESSING_BASH=true
				if command -v zsh >/dev/null 2>&1; then
					ask_yn_n "Set up roperdot for zsh as well" y && PROCESSING_ZSH=true
				fi
			else
				PROCESSING_ZSH=true
				if command -v bash >/dev/null 2>&1; then
					ask_yn_n "Set up roperdot for bash as well" y && PROCESSING_BASH=true
				fi
			fi
		fi
	else
		if [[ "$ROPERDOT_CURRENT_SHELL" = bash ]]; then
			PROCESSING_BASH=true
			if command -v zsh >/dev/null 2>&1; then
				ask_yn_n "Set up roperdot for zsh as well" n && PROCESSING_ZSH=true
			else
				if ask_yn_n "Install zsh and set up roperdot for it" y; then
					PROCESSING_ZSH=true
					"$ROPERDOT_CURRENT_SHELL" "${ROPERDOT_DIR}/install-profiles/standard/installs/install-zsh"
					export zsh_newly_installed=true
				fi
			fi
		else
			PROCESSING_ZSH=true
			if command -v bash >/dev/null 2>&1; then
				ask_yn_n "Set up roperdot for bash as well" n && PROCESSING_BASH=true
			fi
		fi
	fi

	save_resume_point 3
	if [[ (-z "$resume_step" || "$resume_step" -le 3) && -n "$PROCESSING_ZSH" && -z "$zsh_newly_installed" ]]; then
		if [[ -e ~/.zshrc ]]; then
			if [[ -e ~/.zshrc.pre-roperdot ]]; then
				echo "Moving ~/.zshrc to ~/.zshrc.bak"
				mv ~/.zshrc ~/.zshrc.bak
			else
				echo "Moving ~/.zshrc to ~/.zshrc.pre-roperdot"
				mv ~/.zshrc ~/.zshrc.pre-roperdot
			fi
		fi
		echo "Creating ~/.zshrc"
		cat << EOT > ~/.zshrc
bindkey "\e[3~" delete-char
bindkey "^[[H"  beginning-of-line
bindkey "^[[F"  end-of-line
EOT
		add_package_sourcing .zshrc
		if ! command -v starship >/dev/null 2>&1; then
			ROPERDOT_CURRENT_SHELL=zsh zsh "${ROPERDOT_DIR}/install-profiles/standard/installs/install-starship"
		fi
	fi

	export PROCESSING_BASH PROCESSING_ZSH

	save_resume_point 4
	cat <<EOT
roperdot includes customized ls behavior in the shell to:
* Expand instances in paths of "..." to "../.."
* Show the contents of a symlink directory argument instead of the symlink itself
* Use the -d switch for non-directory arguments to suppress single-level recursion into directories
Note: ls will execute without custom behavior if data is piped to it, if its output is redirected, or it's called from another function or script.
EOT
	ask_yn_n "Use custom ls behavior" y "$ROPERDOT_CUSTOM_LS" && ROPERDOT_CUSTOM_LS=true

	cat <<EOT
roperdot includes customized cd behavior in the shell to:
* Expand instances in paths of "..." to "../.."
* Prompt the user to select a subdirectory if no argument is passed instead of changing to \$HOME.
* Prompt the user to select a subdirectory if the argument is ".".
* Prompt the user to select a directory if globbing is used for the destination directory.
* Expand a targeted archive into a temp directory and cd to it.
* mount and cd to the mount directory for a DMG file (MacOS only)
* mount an ISO file (Debian, Ubuntu and Mint only)
The prompt functionalities are only available if fzf is already installed or is selected to be installed with roperdot.
Note: cd will execute without custom behavior if data is piped to it, if its output is redirected, or it's called from another function or script.
EOT
	ask_yn_n "Use custom cd behavior" y "$ROPERDOT_CUSTOM_CD" && ROPERDOT_CUSTOM_CD=true

	cat <<EOT
roperdot includes customized cp behavior in the shell to:
* Cause * to match regular and hidden files
* Expand instances in paths of "..." to "../.."
* Copy files to the current directory if no target directory is specified.
Note: cp will execute without custom behavior if data is piped to it, if its output is redirected, or it's called from another function or script.
EOT
	ask_yn_n "Use custom cp behavior" y "$ROPERDOT_CUSTOM_CP" && ROPERDOT_CUSTOM_CP=true

	cat <<EOT
roperdot includes customized mv behavior in the shell to:
* Cause * to match regular and hidden files
* Expand instances in paths of "..." to "../.."
* Move files to the current directory if no target directory is specified.
Note: mv will execute without custom behavior if data is piped to it, if its output is redirected, or it's called from another function or script.
EOT
	ask_yn_n "Use custom mv behavior" y "$ROPERDOT_CUSTOM_MV" && ROPERDOT_CUSTOM_MV=true

	cat <<EOT
roperdot includes customized rm behavior in the shell to:
* Cause * to match regular and hidden files
* Expand instances in paths of "..." to "../.."
Note: rm will execute without custom behavior if data is piped to it, if its output is redirected, or it's called from another function or script.
EOT
	ask_yn_n "Use custom rm behavior" y "$ROPERDOT_CUSTOM_RM" && ROPERDOT_CUSTOM_RM=true

	ask_yn_n "Do you want to include the current directory (.) in the PATH" y "$ROPERDOT_DOT_IN_PATH" && ROPERDOT_DOT_IN_PATH=true

	ask_yn_n "roperdot includes an ft script to search files for matching patterns. Do you want its search to include hidden files" y "$ROPERDOT_FT_ALL" && ROPERDOT_FT_ALL=true

	# if [[ ( -z "$resume_step" || "$resume_step" -le 4) && -n "$PROCESSING_BASH" ]]; then
	# 	if ask_yn_n "Override the default bash prompt" y "$ROPERDOT_OVERRIDE_PROMPT"; then
	# 		ROPERDOT_OVERRIDE_PROMPT=true
	# 		[[ -z "$ROPERDOT_PROMPT_LINES" ]] && ROPERDOT_PROMPT_LINES=1
	# 		ask_number "Do you want to have 1 or 2 lines in your bash prompt" 2 1 "$ROPERDOT_PROMPT_LINES"
	# 	else
	# 		ROPERDOT_OVERRIDE_PROMPT=false
	# 		unset ROPERDOT_PROMPT_LINES ROPERDOT_SHOW_GIT_PROMPT_INFO
	# 	fi
	# fi

	unset nvim
	if command -v nvim >/dev/null 2>&1; then
	    nvim=nvim
	elif command -v nvim.appimage >/dev/null 2>&1; then
	    nvim=nvim.appimage
	fi

	editor_options=()
	[[ -n "$nvim" ]] && editor_options+=("$nvim")
	editor_options+=("vi")
	command -v nano >/dev/null 2>&1 && editor_options+=("nano")
	command -v pico >/dev/null 2>&1 && editor_options+=("pico")
	editor_options+=("Other (enter editor name)")

	# Build list so current $EDITOR is first if defined
	editor_list=()
	if [[ -n "$EDITOR" ]]; then
	    for opt in "${editor_options[@]}"; do
	        [[ "$opt" = "$EDITOR" ]] && editor_list+=("$opt") && break
	    done
	    for opt in "${editor_options[@]}"; do
	        [[ "$opt" != "$EDITOR" ]] && editor_list+=("$opt")
	    done
	else
	    editor_list=("${editor_options[@]}")
	fi

	choice=$(gum choose --header="Choose your default shell text editor:" "${editor_list[@]}")

	if [[ "$choice" = "Other (enter editor name)" ]]; then
	    EDITOR=$(gum input --placeholder="Enter editor command")
	    if ! command -v "$EDITOR" >/dev/null 2>&1; then
	        echo -e "Chosen editor not found in PATH; defaulting to vi\n"
	        EDITOR=vi
	    fi
	else
	    EDITOR="$choice"
	    echo -e "EDITOR set to $choice\n"
	fi

	arc_types=(tgz zip 7z tar.bz2 rar)
	if [[ -n "$ROPERDOT_ARC_TYPE" ]]; then
		arc_type_options=($ROPERDOT_ARC_TYPE)
		for arc_type in "${arc_types[@]}"; do
			[[ "$arc_type" = "$ROPERDOT_ARC_TYPE" ]] || arc_type_options+=($arc_type)
		done
	else
		arc_type_options=("${arc_types[@]}")
	fi
	arc_type=$(gum choose --header="Choose your default archive type when creating new archives:" "${arc_type_options[@]}")
	if [[ -n "arc_type" ]]; then
		ROPERDOT_ARC_TYPE=$arc_type
		echo -e "ROPERDOT_ARC_TYPE: $ROPERDOT_ARC_TYPE\n"
	elif [[ -n "$ROPERDOT_ARC_TYPE" ]]; then
		echo -e "ROPERDOT_ARC_TYPE: $ROPERDOT_ARC_TYPE\n"
	else
		ROPERDOT_ARC_TYPE=tgz
		echo -e "No choice was made; defaulting ROPERDOT_ARC_TYPE to tgz\n"
	fi

	if ask_yn_n "Do you want to capture command history by individual terminal session instead of using a single history file" y "$ROPERDOT_HISTORY_BY_SESSION"; then
		ROPERDOT_HISTORY_BY_SESSION=true
	else
		unset ROPERDOT_HISTORY_BY_SESSION
	fi
	
	if [[ -n "$accept_recommended" ]]; then
		echo "Accepting recommended defaults so setting default color scheme to hybrid"
		ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME=hybrid
	else
		declare -a schemes
		schemes+=("default (hybrid)")
		pushd "${ROPERDOT_DIR}/config/color-schemes/source" >&/dev/null
		for scheme in *; do
		    [[ "$scheme" == "default" ]] || schemes+=("$scheme")
		done
		popd >&/dev/null

		scheme=$(gum choose --height 16 --header "Default color scheme?" "${schemes[@]}")

		if [[ -n "$scheme" ]]; then
		    if [[ "$scheme" == default* ]]; then
		        ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME="hybrid"
		    else
		        ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME="$scheme"
		    fi
		    echo -e "Default color scheme: $ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME\n"
		fi
	fi

	save_resume_point 5
	if [[ -z "$resume_step" || "$resume_step" -le 5 ]]; then
		[[ -e ~/roperdot-loader-extra ]] && rm ~/roperdot-loader-extra >/dev/null
#		export ROPERDOT_PROFILES="$base_profile"

		if [[ -n "$extra_profiles" ]]; then
		    if [[ "$ROPERDOT_CURRENT_SHELL" = bash ]]; then
		        IFS=',' read -ra extra_profiles_array <<< "$extra_profiles"
		    else
		        extra_profiles_array=("${(@s|,|)extra_profiles}")
		    fi

			for profile in "${extra_profiles_array[@]}"; do
				if [[ -z "$ROPERDOT_PROFILES" ]]; then
					ROPERDOT_PROFILES="$profile"
				else
					ROPERDOT_PROFILES="${ROPERDOT_PROFILES}::${profile}"
				fi
			done
		fi

		CURRENT_VERSION=$(cat "$ROPERDOT_DIR/VERSION" 2>/dev/null | tr -d '\n\r ')
		cat << EOT > ~/roperdot-loader
# [[ -n "\$ROPERDOT_LOADED" ]] && return
export ROPERDOT_LOADED=true
export ROPERDOT_VERSION=$CURRENT_VERSION
export ROPERDOT_SUPPRESS_INFO=$ROPERDOT_SUPPRESS_INFO
export ROPERDOT_DOT_IN_PATH=$ROPERDOT_DOT_IN_PATH
export ROPERDOT_PROFILES=$ROPERDOT_PROFILES
export ROPERDOT_CUSTOM_CD=$ROPERDOT_CUSTOM_CD
export ROPERDOT_CUSTOM_CP=$ROPERDOT_CUSTOM_CP
export ROPERDOT_CUSTOM_LS=$ROPERDOT_CUSTOM_LS
export ROPERDOT_CUSTOM_MV=$ROPERDOT_CUSTOM_MV
export ROPERDOT_CUSTOM_RM=$ROPERDOT_CUSTOM_RM
export ROPERDOT_COLOR_SCHEME=${ROPERDOT_COLOR_SCHEME:-default}
export ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME=${ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME:-hybrid}
export ROPERDOT_COMMON_COLOR_SCHEME=${ROPERDOT_COMMON_COLOR_SCHEME:-default}
export ROPERDOT_OVERRIDE_PROMPT=$ROPERDOT_OVERRIDE_PROMPT
export ROPERDOT_PROMPT_LINES=$ROPERDOT_PROMPT_LINES
export ROPERDOT_SHOW_GIT_PROMPT_INFO=${ROPERDOT_SHOW_GIT_PROMPT_INFO:-true}
export EDITOR=$EDITOR
export ROPERDOT_ARC_TYPE=$ROPERDOT_ARC_TYPE
export ROPERDOT_HISTORY_BY_SESSION=$ROPERDOT_HISTORY_BY_SESSION
export ROPERDOT_MC_SCHEME=${ROPERDOT_MC_SCHEME:-dark}
# vi vars
export ROPERDOT_VI_BACKGROUND=${ROPERDOT_VI_BACKGROUND:-dark}
export ROPERDOT_VI_COLOR_SCHEME=${ROPERDOT_VI_COLOR_SCHEME:-hybrid}
export GUM_CHOOSE_CURSOR_FOREGROUND=#ab5
export GUM_CHOOSE_SELECTED_FOREGROUND=#ab5
export GUM_CHOOSE_HEADER_FOREGROUND=#d74
export GUM_CONFIRM_PROMPT_FOREGROUND=#d74
export GUM_CONFIRM_SELECTED_BACKGROUND=#ab5
export GUM_FILTER_INDICATOR_FOREGROUND=#d74
export GUM_FILTER_MATCH_FOREGROUND=#d74
export GUM_INPUT_CURSOR_FOREGROUND=#d74
EOT
		[[ -n "$ROPERDOT_COLOR_SCHEME" ]] && echo -e "export ROPERDOT_COLOR_SCHEME=$ROPERDOT_COLOR_SCHEME\n" >> ~/roperdot-loader
		if [[ "${ROPERDOT_DIR}" = "$(realpath ~/roperdot)" ]]; then
			cat << EOT >> ~/roperdot-loader
if [[ -e "${ROPERDOT_DIR}/roperdot-bootstrap" ]]; then
	. "${ROPERDOT_DIR}/roperdot-bootstrap"
else
	echo "Error: cannot locate roperdot-bootstrap"
fi
EOT
		else
			cat << EOT >> ~/roperdot-loader
if [[ -e "${ROPERDOT_DIR}/roperdot-bootstrap" ]]; then
	. "${ROPERDOT_DIR}/roperdot-bootstrap"
elif [[ -e ~/roperdot/roperdot-bootstrap ]]; then
	. ~/roperdot/roperdot-bootstrap
else
	echo "Error: cannot locate roperdot-bootstrap"
fi
EOT
		fi
	fi

	. ~/roperdot-loader

	# Copy .fdignore to home directory if necessary
	# ~/.fdignore needs to be present to prevent .gitignore from being used to exclude files/directories
	if ! cmp -s ~/.fdignore "${ROPERDOT_DIR}/.fdignore"; then
		[[ -f ~/.fdignore ]] && mv ~/.fdignore ~/.fdignore.bak >/dev/null 2>&1
		cp "${ROPERDOT_DIR}/.fdignore" ~/.fdignore >/dev/null 2>&1
	fi
	
	if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
		update_config_files
		export UPDATE_CONFIG_FILES=true
	else
		if ask_yn_n "Update shell configuration files to autoload roperdot" y; then
			update_config_files
			export UPDATE_CONFIG_FILES=true
		else
			skipped_config_update=true
		fi
	fi

	if [[ "$ROPERDOT_OS_ENV" = "darwin" && ! -f ~/.hushlogin ]]; then
		echo Creating ~/.hushlogin to prevent "Last login..." messages
		touch ~/.hushlogin
		echo
	fi

	debug "Font check: ROPERDOT_DESKTOP_ENV: $ROPERDOT_DESKTOP_ENV"
	save_resume_point 6
	if [[ -z "$resume_step" || "$resume_step" -le 6 ]]; then
		if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
			# Install Hack Nerd fonts
			"${ROPERDOT_DIR}/bin/install-font-from-web" 'Hack Nerd Font' 'Hack' 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz' 'HackNerdFontMono-Regular.ttf'

			# Install Windows fonts in WSL
			sudo apt update
			echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true" | sudo debconf-set-selections
			sudo apt install -y ttf-mscorefonts-installer
		fi
	fi

	if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
		cat <<EOT
You should import the profile in ${ROPERDOT_DIR}/config/macos-terminal into
your Terminal to set the background color, font and initial window size.

EOT
	fi

	[[ -d "$ROPERDOT_DIR/bin" ]] && chmod u+x "$ROPERDOT_DIR/bin"/*

	if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" && ! -d ~/Documents ]] && ask_yn_n "Create symlinks to commonly used directories in home directory" y; then
		homedir="$(win_env_linux_path USERPROFILE)"
		dirs=(Desktop Documents Downloads Music Pictures Videos)
		for d in "${dirs[@]}"; do
			if [[ -d "$HOME/$d" ]]; then
				ln -s "$homedir/$d" "$HOME/$d"
			else
				case $d in
					Desktop)   dir="$d" ;;
					Documents) dir="Personal" ;;
					Downloads) dir="{374DE290-123F-4565-9164-39C4925E467B}" ;;
					Music)     dir="My Music" ;;
					Pictures)  dir="My Pictures" ;;
					Videos)    dir="My Video" ;;
				esac
				dir="$(get-reg-path-value "HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/User Shell Folders" "$dir")"
				ln -s "$dir" "$HOME/$d"
			fi
		done
	fi
else
	. ~/roperdot-loader

#		echo Fixing shebangs of scripts in roperdot to use local binary paths
#		bash source-scripts/fix-bin-shebangs
fi

echo -e "\nProcessing shell and GUI apps to install...\n"

while IFS= read -r -d '' d; do
	[[ -d "$d/installs" ]] && chmod u+x "$d/installs/"*
done < <(find "${ROPERDOT_DIR}/install-profiles" -mindepth 1 -maxdepth 1 -type d -print0)

[[ -n "$installs_to_pause" ]] && export installs_to_pause

$install_shell install-apps

if [[ "$ROPERDOT_DESKTOP_ENV" == "windows" ]]; then
	# Import color schemes into Windows Terminal and set Hack Nerd Font as the font
	configure-windows-terminal
	if ask_yn_n "Set WSL as the default profile for Windows Terminal" y; then
		set-windows-terminal-default-profile
	fi

	# Do the same for Windows Console for Ubuntu
	configure-windows-console

	cat <<EOT
This install can update various Windows configurations for you:

- Disable Cortana search box on the taskbar
- Configure Windows Search to local searches only (no web results)
- Revert Explorer to Windows 10 style command bar and context menus
- Disable Windows telemetry and tracking
- Show file extensions in Explorer
- Show hidden files and folders in Explorer
- Enable dark theme for apps and system
- Disable startup delay for faster boot
- Disable automatic Windows Update restarts

Note that applying these changes will entail an automatic restart of Explorer (but not of Windows).
EOT
	if ask_yn_n "Do you want to apply these configuration changes" y; then
	    powershell.exe -ExecutionPolicy Bypass -File "${ROPERDOT_DIR}/os-bin/windows/update-windows-configuration.ps1"
	    echo "Enabling Telnet requires a reboot for it to complete taking effect."
	    echo "Some of these changes other require administrator privileges and may need a restart to take effect."
	fi
	cat <<EOT
This install can also create Startup shortcuts for apps (if they're present) so they'll run on startup including:
- Chrome
- Windows Terminal
- Sublime Text 3
- Notion
- Claude
- VNC Viewer
EOT
	if ask_yn_n "Do you want to create these startup shortcuts" y; then
		powershell.exe -ExecutionPolicy Bypass -File "${ROPERDOT_DIR}/os-bin/windows/create-startup-shortcuts.ps1"
	fi
fi

if [[ ! -d ~/.grc ]] && command -v grc >/dev/null 2>&1; then
	ln -s "${ROPERDOT_DIR}/config/color-schemes/source/default/grc" ~/.grc
fi

if [[ "$ROPERDOT_DESKTOP_ENV" = "gnome" ]]; then
	if ask_yn_n "Install Gnome Terminal profile and make it the default" y; then
		dconf load /org/gnome/terminal/legacy/profiles:/ < "${ROPERDOT_DIR}/config/color-schemes/source/default/gnome-terminal.dconf"
	fi
fi

# Run update-app-binaries even if install-apps exited with non-zero return
# There may be pre-installed apps eligible for functions
echo Updating application functions for the OS
update-app-binaries
echo

# This must be done after application installs so vim and fzf will be present
if command -v vim >/dev/null 2>&1 && vim --version | grep "+syntax" >/dev/null && ask_yn_n "Copy .vimrc and vim settings files to home directory" y; then
	# sed -i -e 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=true/' ~/roperdot-loader
	if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
		sed -i '' 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=true/' ~/roperdot-loader
	else
		sed -i 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=true/' ~/roperdot-loader
	fi
	nice_copy config/apps/vim/vimrc-base ~/.vimrc
	mkdir -p ~/.vim/colors ~/.vim/backup ~/.vim/swap ~/.vim/undo
	nice_copy "${ROPERDOT_DIR}/config/apps/vim/.vim/colors"/* ~/.vim/colors
	echo "If you encounter errors using the included vim color scheme, you should upgrade your installed vi/vim." >> ~/roperdot-info.txt
else
	# sed -i -e 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=/' ~/roperdot-loader
	if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
		sed -i '' 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=/' ~/roperdot-loader
	else
		sed -i 's/# vi vars/# vi vars\nROPERDOT_USE_VIM_SETTINGS=/' ~/roperdot-loader
	fi
fi

if command -v nvim >/dev/null 2>&1; then
	ask_yn_n "Install plugins for vim and Neovim" y && "${ROPERDOT_DIR}/install-profiles/standard/installs/install-vim-plugins"
else
	ask_yn_n "Install plugins for vim" y && "${ROPERDOT_DIR}/install-profiles/standard/installs/install-vim-plugins"
fi

#if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
#	echo
#	if [[ -e /Applications/iTerm.app ]] && ask_yn_n "Copy iTerm2 profile to dynamic profiles directory" y; then
#		[[ -d "${HOME}/Library/Application Support/iTerm2/DynamicProfiles" ]] || mkdir -p "${HOME}/Library/Application Support/iTerm2/DynamicProfiles"
#		nice_copy "${ROPERDOT_DIR}/config/apps/iTerm2"/* "${HOME}/Library/Application Support/iTerm2/DynamicProfiles"
#		echo "You should consider making the roperdot dynamic profile for iTerm2 your default profile." >> ~/roperdot-info.txt
#	fi
#fi

if [[ "$ROPERDOT_OS_ENV" = "darwin" ]] && command -v python3 >/dev/null 2>&1 && ! command -v pip3 >/dev/null 2>&1; then
	echo Re-linking python3 to put pip3 in the path
	brew unlink python3 && brew link python3
fi

# This section will have to be tweaked to set the right values in .gitconfig
# The full path is needed if it's not in PATH like "C:/Program Files/Perforce/p4merge.exe"
#
# Test like: git difftool
#
if command -v git >/dev/null 2>&1; then
	if [[ $ROPERDOT_OVERRIDE_PROMPT = true && -n $PROCESSING_BASH ]]; then
		[[ -z "$ROPERDOT_SHOW_GIT_PROMPT_INFO" ]] && ROPERDOT_SHOW_GIT_PROMPT_INFO=true
		if ask_yn_n "Show branch and status in bash prompt when in a git repository directory" y $ROPERDOT_SHOW_GIT_PROMPT_INFO; then
			ROPERDOT_SHOW_GIT_PROMPT_INFO=true
		else
			ROPERDOT_SHOW_GIT_PROMPT_INFO=false
		fi
		if sed --version >/dev/null 2>&1; then
			sed -i 's/ROPERDOT_SHOW_GIT_PROMPT_INFO=.*/ROPERDOT_SHOW_GIT_PROMPT_INFO=$ROPERDOT_SHOW_GIT_PROMPT_INFO/' ~/roperdot-loader
		else
			# bash packaged with macOS requires a parameter after sed -i
			sed -i '' 's/ROPERDOT_SHOW_GIT_PROMPT_INFO=.*/ROPERDOT_SHOW_GIT_PROMPT_INFO=$ROPERDOT_SHOW_GIT_PROMPT_INFO/' ~/roperdot-loader
		fi
	fi
	if ask_yn_n "Set up git configuration for roperdot" y; then
		nice_copy config/apps/git/.gitconfig ~/.gitconfig
		nice_copy config/apps/git/.gitignore ~/.gitignore
		[[ -f config/apps/git/.gitconfig.local ]] && nice_copy config/apps/git/.gitconfig.local ~/.gitconfig.local
		if [[ -n "$ROPERDOT_COLOR_SCHEME" ]]; then
			source "${ROPERDOT_DIR}/config/color-schemes/source/${ROPERDOT_COLOR_SCHEME}/.git-colors"
		else
			source "${ROPERDOT_DIR}/config/color-schemes/source/default/.git-colors"
		fi
	fi
	case "$ROPERDOT_OS_FAMILY" in
		darwin) app_path="$(gui_app_path p4merge p4merge p4v)" ;;
		debian) app_path="$(gui_app_path p4merge Perforce)" ;;
	esac
	if [[ -n "$app_path" ]] && ask_yn_n "Use P4Merge as the git diff and merge tool" y; then
		echo "Executing commands to update .gitconfig to use P4Merge as the diff and merge tool."
		git config --global diff.tool p4merge
		# git config --global diff.compactionHeuristic true
		git config --global merge.tool p4merge
		# git config --global merge.rename_limit 0
		git config --global --add difftool.prompt false
		case "$ROPERDOT_OS_FAMILY" in
			darwin)
				git config --global difftool.p4merge.cmd "$app_path/Contents/Resources/launchp4merge \"\$LOCAL\" \"\$REMOTE\""
				git config --global mergetool.p4merge.cmd "$app_path/Contents/Resources/launchp4merge \"\$BASE\" \"\$REMOTE\" \"\$LOCAL\" \"\$MERGED\""
				;;
			debian)
				app_path="$(wslwinpath -m "$app_path")"
				git config --global difftool.p4merge.cmd "'$app_path/p4merge.exe' \"\$LOCAL\" \"\$REMOTE\""
				git config --global mergetool.p4merge.cmd "'$app_path/p4merge.exe' \"\$BASE\" \"\$LOCAL\" \"\$REMOTE\" \"\$MERGED\""
				;;
		esac
		git config --global mergetool.p4merge.trustExitCode false
		git config --global mergetool.keepBackup false
		if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
			source_tree_path="$(gui_app_path Sourcetree Sourcetree Sourcetree)"
			if [[ -n "$source_tree_path" ]]; then
				git config --global difftool.sourcetree.cmd "opendiff \"\$LOCAL\" \"\$REMOTE\""
				git config --global mergetool.sourcetree.cmd "${source_tree_path}/Contents/Resources/opendiff-w.sh \"\$LOCAL\" \"\$REMOTE\" -ancestor \"\$BASE\" -merge \"\$MERGED\""
				git config --global mergetool.sourcetree.trustExitCode true
			fi
		fi
		command -v hexdump >/dev/null 2>&1 && git config --global diff.bin.textconv "hexdump -v -C"
	fi
fi

# Do post installs for extra profiles
if [[ -n "$extra_profiles" ]]; then
	str="$extra_profiles"
	if [[ "$ROPERDOT_CURRENT_SHELL" = bash ]]; then
		IFS=',' read -ra extra_profiles <<< "$str"
	else
		extra_profiles=("${(@s|,|)str}")
	fi
	for profile in "${extra_profiles[@]}"; do
		[[ -f "${ROPERDOT_DIR}/install-profiles/$profile/post-install.sh" ]] && $install_shell "$profile/post-install.sh"
	done
fi

if [[ -f "${ROPERDOT_DIR}/important-install-messages.txt" ]]; then
	cat "${ROPERDOT_DIR}/important-install-messages.txt"
	rm "${ROPERDOT_DIR}/important-install-messages.txt" >/dev/null 2>&1
fi

if [[ "$ROPERDOT_DESKTOP_ENV" = windows ]] && ! grep -q "^\[interop\]" /etc/wsl.conf; then
	echo "Updating wsl.conf to ensure Windows interoperability."

	if [[ ! -f /etc/wsl.conf.bak ]]; then
		echo "Backing up /etc/wsl.conf"
		sudo cp /etc/wsl.conf /etc/wsl.conf.bak 2>/dev/null || sudo touch /etc/wsl.conf.bak
	fi

	sudo tee -a /etc/wsl.conf > /dev/null << EOT
[interop]
enabled = true
appendWindowsPath = true
EOT
	
	cat << EOT
If you're on a corporate machine and encounter issues running Windows commands from within WSL,
restart WSL by doing "wsl --shutdown" in a PowerShell terminal to apply the interop changes to
wsl.conf and then open a new WSL terminal.
EOT
fi

if [[ -n "$ROPERDOT_DESKTOP_ENV" ]]; then
	cat <<EOT

Installation complete.

I've included the Hack Nerd Font in this installation. It's a great terminal font which originates here:
https://github.com/ryanoasis/nerd-fonts

You should restart your terminal application to see the changes take effect.

EOT
elif [[ -n "$skipped_config_update" ]]; then
	cat <<EOT

Installation complete.

To use roperdot in this and future terminal sessions, source ~/roperdot-loader.

EOT
else
	cat <<EOT

Installation complete.

To use roperdot in this session, source ~/roperdot-loader.

EOT
fi
if [[ "$ROPERDOT_OS_ENV" = "darwin" && -d /Applications/iTerm.app ]]; then
	echo -e "You should import the profile JSON from roperdot/config/apps/iTerm2 into iTerm2.\n" >> ~/roperdot-info.txt
elif [[ "$ROPERDOT_DESKTOP_ENV" == "windows" ]]; then
	echo -e "If this is your first time running Windows Terminal, you should run the configure-windows-terminal script to update the Windows Terminal schemes." >> ~/roperdot-info.txt
fi
echo -e "If your color scheme of choice is light instead of dark, you should update ~/roperdot-loader and set the values of ROPERDOT_MC_SCHEME and ROPERDOT_VI_BACKGROUND to 'light'.\n" >> ~/roperdot-info.txt
if [[ "$ROPERDOT_DESKTOP_ENV" == "windows" ]]; then
	cat <<EOT
Some things you should consider doing for Windows:
* Disable News and Interests on the taskbar: right-click the icon on the taskbar, expand News and Interests, and click Turn off
* Enable the Telnet client and Hyper-V features via Control Panel/Programs/Turn Windows features on or off
* Set your default browser to something other than Edge
* Configure your Start Menu by removing unwanted pinned apps and pinning commonly used apps
* Pin frequently used apps to the Taskbar
EOT
fi
cat ~/roperdot-info.txt