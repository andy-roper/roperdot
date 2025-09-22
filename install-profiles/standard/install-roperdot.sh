export INSTALLING_ROPERDOT=true

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

# Have to use \x1B instead of \e for out-of-the-box Mac bash compatibility
export warning_text=$(echo -e '\x1B[0;91m')
export normal_text=$(echo -e '\x1B[0m')

[[ "$ROPERDOT_CURRENT_SHELL" = zsh ]] && setopt ksh_glob || shopt -s extglob

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	. "${ROPERDOT_DIR}/source-scripts/win-env-functions"
	. "${ROPERDOT_DIR}/source-scripts/win-reg-functions"
	def_win_env_linux_path LOCALAPPDATA app_local_path
	def_win_env_linux_path PROGRAMFILES program_files_path
	def_win_env_linux_path "PROGRAMFILES(X86)" program_files_86_path
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

choose_number () {
	local text="$1" max_num="$2" recommended="$3" default="$4" answer
	if [[ -n "$accept_recommended" && -n "$recommended" ]]; then
		echo "${text} [default is $default]: ${recommended}"
		return "$recommended"
	else
		echo
		while [[ -z "$answer" || "$answer" -gt "$max_num" ]]; do
			read_input "${text} [default is $default]:"
			answer="$REPLY"
			[[ -z "$answer" ]] && answer="$default"
		done
		return "$answer"
	fi
}

ask_number_or_text () {
	local text="$1" max_num="$2" recommended="$3" default="$4"
	if [[ -n "$accept_recommended" && -n "$recommended" ]]; then
		echo "${text} [default is $default]: ${recommended}"
		answer="$recommended"
	else
		echo
		while [[ -z "$answer" || "$answer" -gt "$max_num" ]]; do
			echo -n "${text} [default is $default]: "
			read answer
			# echo "$answer" >> "$logfile"
			[[ -z "$answer" ]] && answer="$default"
		done
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
			selection="$(select_from_list "Choose your installation option" 1 "Upgrade zsh and install roperdot for bash and zsh" "Upgrade zsh and install roperdot for it" "Install roperdot for zsh" "Install roperdot for bash")"
			if [[ "$selection" =~ "bash and zsh" ]]; then
				upgrade_zsh=true
				PROCESSING_BASH=true
				PROCESSING_ZSH=true
			elif [[ "$selection" =~ "Upgrade zsh" ]]; then
				upgrade_zsh=true
				PROCESSING_ZSH=true
			elif [[ "$selection" =~ zsh ]]; then
				PROCESSING_ZSH=true
			elif [[ "$selection" =~ bash ]]; then
				PROCESSING_BASH=true
			fi
		else
			selection="$(select_from_list "Choose your installation option" 1 "Upgrade zsh and install roperdot for it" "Install roperdot for zsh")"
			if [[ "$selection" =~ Upgrade ]]; then
				upgrade_zsh=true
				PROCESSING_ZSH=true
			elif [[ "$selection" =~ Install ]]; then
				PROCESSING_ZSH=true
			fi
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
${warning_text}Chocolatey (https://chocolatey.org/) is used by the installer to install git,
several shell applications and GUI applications. It's strongly advised that
you install Chocolatey before continuing this install.${normal_text}

EOT
	fi
fi

[[ -d "${ROPERDOT_DIR}/extra-bin" ]] || mkdir "${ROPERDOT_DIR}/extra-bin"
#	[[ -d "${ROPERDOT_DIR}/extra-source" ]] || mkdir "${ROPERDOT_DIR}/extra-source"
[[ "$PATH" =~ extra-bin ]] || export PATH="$PATH:${ROPERDOT_DIR}/extra-bin"
[[ -d "${LOCALUSR}/bin" && ! "$PATH" =~ local-usr ]] && export PATH="$PATH:${LOCALUSR}/bin"

if [[ -d /home/linuxbrew/.linuxbrew/bin && ! "$PATH" =~ linuxbrew ]]; then
	export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
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
#		sudo -l | tee /dev/tty | grep "ALL) ALL" >/dev/null && export has_sudo=true
	sudo -l | grep "ALL) ALL" >/dev/null && export has_sudo=true
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

	if [[ ( -z "$resume_step" || "$resume_step" -le 4) && -n "$PROCESSING_BASH" ]]; then
		if ask_yn_n "Override the default bash prompt" y "$ROPERDOT_OVERRIDE_PROMPT"; then
			ROPERDOT_OVERRIDE_PROMPT=true
			[[ -z "$ROPERDOT_PROMPT_LINES" ]] && ROPERDOT_PROMPT_LINES=1
			ask_number "Do you want to have 1 or 2 lines in your bash prompt" 2 1 "$ROPERDOT_PROMPT_LINES"
		else
			ROPERDOT_OVERRIDE_PROMPT=false
			unset ROPERDOT_PROMPT_LINES ROPERDOT_SHOW_GIT_PROMPT_INFO
		fi
	fi

	unset nvim
	if command -v nvim >/dev/null 2>&1; then
		nvim=nvim
	elif command -v nvim.appimage >/dev/null 2>&1; then
		nvim=nvim.appimage
	fi
	if [[ -n "$nvim" ]]; then
		editor_prompt="Enter the number for your default shell text editor: 1. $nvim, 2. vi"
		declare -a editor_options=("" "$nvim" "vi")
		editor_count=2
		if [[ "$EDITOR" = "$nvim" ]]; then
			default_editor=1
		elif [[ "$EDITOR" = "vi" ]]; then
			default_editor=2
		fi
	else
		editor_prompt="Enter the number for your default text editor: 1. vi"
		declare -a editor_options=("" "vi")
		editor_count=1
		[[ "$EDITOR" = "vi" ]] && default_editor=1
	fi

	if command -v nano >/dev/null 2>&1; then
	    editor_options+=("nano")
	    (( ++editor_count ))
	    editor_prompt+=", $editor_count. nano"
	    [[ -z "$default_editor" && "$EDITOR" = "nano" ]] && default_editor=$editor_count
	fi
	if command -v pico >/dev/null 2>&1; then
	    editor_options+=("pico")
	    (( ++editor_count ))
	    editor_prompt+=", $editor_count. pico"
	    [[ -z "$default_editor" && "$EDITOR" = "pico" ]] && default_editor=$editor_count
	fi
	editor_prompt+=", or enter the name of an editor"
	[[ -z "$default_editor" ]] && default_editor=1

	ask_number_or_text "$editor_prompt" $editor_count 1 $default_editor
	editor="$answer"
    if [[ -n "${editor_options[$editor]}" ]]; then
        EDITOR="${editor_options[$editor]}"
    elif command -v "$editor" >/dev/null 2>&1; then
        EDITOR="$editor"
    fi

	case "$ROPERDOT_ARC_TYPE" in
		tgz)     default=1 ;;
		zip)     default=2 ;;
		7z)      default=3 ;;
		tar.bz2) default=4 ;;
		rar)     default=5 ;;
		*)       default=1 ;;
	esac
	ROPERDOT_ARC_TYPE=
	while [[ -z "$ROPERDOT_ARC_TYPE" ]]; do
		choose_number "Choose your default archive type when creating new archives: 1. tgz, 2. zip, 3. 7z, 4. tar.bz2, 5. rar" 5 1 "$default"
		case "$?" in
			1 ) ROPERDOT_ARC_TYPE=tgz ;;
			2 ) ROPERDOT_ARC_TYPE=zip ;;
			3 ) ROPERDOT_ARC_TYPE=7z ;;
			4 ) ROPERDOT_ARC_TYPE=tar.bz2 ;;
			5 ) ROPERDOT_ARC_TYPE=rar ;;
			* ) ROPERDOT_ARC_TYPE=tgz ;;
		esac
	done

	if ask_yn_n "Do you want to capture command history by individual terminal session instead of using a single history file" y "$ROPERDOT_HISTORY_BY_SESSION"; then
		ROPERDOT_HISTORY_BY_SESSION=true
	else
		unset ROPERDOT_HISTORY_BY_SESSION
	fi
	
	if command -v pygmentize >/dev/null 2>&1; then
		declare -a schemes
		schemes+=("default")
		pushd "${ROPERDOT_DIR}/config/color-schemes/source" >&/dev/null || return 1
		PS3="Default pygmentize color scheme? "
		for scheme in *; do
			[[ "$scheme" == "default" ]] || schemes+=("$scheme")
		done
		select scheme in "${schemes[@]}"; do
			break
		done
		popd >&/dev/null || return 1
		[[ -n "$scheme" ]] && ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME="$scheme"
	fi

	save_resume_point 5
	if [[ -z "$resume_step" || "$resume_step" -le 5 ]]; then
		[[ -e ~/roperdot-loader-extra ]] && rm ~/roperdot-loader-extra >/dev/null
#		export ROPERDOT_PROFILES="$base_profile"
		for profile in "${extra_profiles[@]}"; do
#			ROPERDOT_PROFILES="${ROPERDOT_PROFILES}::${profile}"
			if [[ -z "$ROPERDOT_PROFILES" ]]; then
				ROPERDOT_PROFILES="$profile"
			else
				ROPERDOT_PROFILES="${ROPERDOT_PROFILES}::${profile}"
			fi
		done
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

	debug "Font check: ROPERDOT_OS_TYPE: $ROPERDOT_OS_TYPE"
	save_resume_point 6
	if [[ -z "$resume_step" || "$resume_step" -le 6 ]]; then
		if [[ -n "$ROPERDOT_OS_TYPE" ]]; then
			# Install Hack Nerd fonts
			"${ROPERDOT_DIR}/bin/install-font-from-web" 'Hack Nerd Font' 'Hack' 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz' 'HackNerdFontMono-Regular.ttf'
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

echo
echo Processing shell and GUI apps to install...
echo

while IFS= read -r -d '' d; do
	[[ -d "$d/installs" ]] && chmod u+x "$d/installs/"*
done < <(find "${ROPERDOT_DIR}/install-profiles" -mindepth 1 -maxdepth 1 -type d -print0)

[[ -n "$installs_to_pause" ]] && export installs_to_pause

$install_shell install-apps

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

# linuxbrew must be in the path before installing vim plugins for fzf
if [[ -d /home/linuxbrew/.linuxbrew/bin && ! "$PATH" =~ linuxbrew ]]; then
	export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
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
else
	echo -e "If you're using a supported terminal emulator, you should import one or more color schemes from roperdot/config/color-schemes/mintty.\n" >> ~/roperdot-info.txt
fi
echo -e "If your color scheme of choice is light instead of dark, you should update ~/roperdot-loader and set the values of ROPERDOT_MC_SCHEME and ROPERDOT_VI_BACKGROUND to 'light'.\n" >> ~/roperdot-info.txt
cat ~/roperdot-info.txt