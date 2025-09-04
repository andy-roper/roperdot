#
# Description: Main install script for roperdot dotfiles
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

help () {
	cat <<EOT
install.sh  Install roperdot

Options:
--add-profile   Install using a profile in addition to the base profile; the
                argument following the switch is the name of the profile
--all-gui       Install all available GUI applications
--all-shell     Install all available shell applications
--base-profile  Install using a profile other than the standard one; the
                argument following the switch is the name of the profile
--groups        (comma-separated) For apps with groups defined, only install those
                with a matching group. For apps with exclusionGroups defined, skip
                installing if the list contains a specified group.
--no-gui        Install no GUI applications
--no-shell      Install no shell applications
--recommended   Accept the recommended answer for all prompts
--resume        Run with resume capability/resume from a previous install attempt

Environment variables that affect the install:
installs_to_pause: comma-delimited list of app names to pause before installing
EOT
	exit 0
}

[[ "$1" = "--help" || "$1" = "-h" || "$1" = "-?" ]] && help

export base_profile=standard extra_profiles

# Assume user wants to accept recommended answers if stdin isn't connected to a TTY
test -t 0 || export accept_recommended=true

# Store python3 and pip3 locations
export python3_bin=$(command -v python3 2>/dev/null || echo "")
export pip3_bin=$(command -v pip3 2>/dev/null || echo "")

while [[ $# -gt 0 ]]; do
	arg="$1"
	shift
	if [[ "$arg" = "--recommended" || "$arg" = "-r" ]]; then
		export accept_recommended=true
		echo "Accepting all recommended settings during the install"
	elif [[ "$arg" = "--resume" ]]; then
		export resuming=true
	elif [[ "$arg" = "--all-shell" ]]; then
		export force_shell_app_installs=all
	elif [[ "$arg" = "--no-shell" ]]; then
		export force_shell_app_installs=none
	elif [[ "$arg" = "--all-gui" ]]; then
		export force_gui_app_installs=all
	elif [[ "$arg" = "--no-gui" ]]; then
		export force_gui_app_installs=none
	elif [[ "$arg" = "--show-start-times" ]]; then
		export show_start_times=true
	elif [[ "$arg" = "--add-profile" ]]; then
		[[ -z "$1" ]] && help
		if [[ -n "$extra_profiles" ]]; then
			extra_profiles+=",$1"
		else
			extra_profiles="$1"
		fi
		shift
	elif [[ "$arg" = "--base-profile" ]]; then
		export base_profile="$1"
		[[ -z "$base_profile" ]] && help
		shift
	elif [[ "$arg" = "--groups" ]]; then
	    export install_groups="$1"
	    [[ -z "$install_groups" ]] && help
	    shift
	fi
done

if [[ -n "$BASH_VERSION" ]]; then
	export ROPERDOT_CURRENT_SHELL=bash
	export ROPERDOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	PROCESSING_BASH=true
elif [[ -n "$ZSH_VERSION" ]]; then
	export ROPERDOT_CURRENT_SHELL=zsh
	export ROPERDOT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
	PROCESSING_ZSH=true
else
	echo "Unsupported shell. Exiting the install."
	exit 1
fi

[[ -n "$installs_to_pause" ]] && export installs_to_pause

source "${ROPERDOT_DIR}/source-scripts/detect-os"
[[ -z "$ROPERDOT_OS_ENV" ]] && echo "Could not detect OS properly. Exiting the install." && exit 1

command -v bash >/dev/null 2>&1 && export bash_present=true
command -v zsh >/dev/null 2>&1 && export zsh_present=true

source "${ROPERDOT_DIR}/source-scripts/input-functions"

if [[ "$ROPERDOT_OS_NAME" = darwin ]]; then
	groups $USER | grep -q admin && export has_sudo=true
	if [[ -f /usr/local/bin/bash ]]; then
		export install_shell=bash
	else
		if [[ -n "$zsh_present" ]]; then
		    if [[ -n "$bash_present" ]]; then
		        ask_yn_n "This install works best with a newer version of bash. Install bash via Homebrew" y && bash_action=install
		    else
		        ask_yn_n "Install bash (required for logging output during the install)" y && bash_action=install
		    fi
		else
		    # Bash 4 or later is required by the install to support associative arrays
		    ask_yn_n "The install requires a newer version of bash. Install bash via Homebrew" y && bash_action=install
		fi
		if [[ -n "$bash_action" ]]; then
			if command -v brew >/dev/null 2>&1; then
				if ask_yn_n "Update and upgrade brew" y; then
					echo Updating brew
					brew update
					echo Upgrading brew
					brew upgrade
					export brew_updated=true
				else
					export brew_updated=false
				fi
			elif ask_yn_y "Install homebrew (needed to install bash and multiple other apps)" y; then
				if [[ -n "$has_sudo" ]]; then
					if [[ -n "$bash_present" ]]; then
						bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
					else
						zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
					fi
				else
					# Install brew just for the user
					mkdir ~/homebrew && curl -L https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C ~/homebrew
					eval "$(~/homebrew/bin/brew shellenv)"
					brew update --force --quiet
					zsh_bin="$(brew --prefix)/share/zsh"
					[[ -f "$zsh_bin" ]] && chmod -R go-w "$zsh-bin"
				fi
				if ! command -v brew >/dev/null 2>&1; then
					echo "Brew was not successfully installed. Aborting the roperdot install."
					exit 1
				fi
				export brew_newly_installed=true
			else
				echo "Brew was not installed. Aborting the roperdot install."
				exit 1
			fi
			if [[ -z "$has_sudo" ]] && ! xcode-select -p &>/dev/null; then
			    echo "Installing Command Line Tools..."
			    xcode-select --install
			    # Wait for installation to complete
			    until xcode-select -p &>/dev/null; do
			        sleep 5
			    done
			fi
			if [[ "$bash_action" = install ]]; then
				echo "Installing bash"
				brew install bash
			else
				echo "Upgrading bash"
				brew upgrade bash
			fi
		elif [[ -z "$zsh_present" ]]; then
			echo "A newer version of bash or zsh is required. Aborting the install."
			exit 1
		fi
		if [[ -f /usr/local/bin/bash ]]; then
			export install_shell=bash
			if [[ "$action" = "install" ]]; then
				export bash_newly_installed=true
			else
				export bash_updated=true
			fi
		else
			export install_shell=zsh
		fi
	fi
else
	export install_shell=bash
fi

# If we just installed bash, re-exec with the new bash before continuing
#if [[ "$install_shell" = bash && "$ROPERDOT_OS_NAME" = darwin && -n "$bash_action" ]]; then
#	echo "Re-executing with newly installed bash..."
#	exec /usr/local/bin/bash "$0" "$@"
#	exit 1
#fi

if [[ "$install_shell" = bash ]]; then
	# Initiate logging and strip out ANSI sequences from logging
	# Answers to read commands are not captured and need to be manually logged
	export ROPERDOT_LOGFILE="${HOME}/roperdot-install.log"
	
	echo "Initiating logging to $ROPERDOT_LOGFILE"
	# Duplicate output to a log file and strip out ANSI sequences
	# Commented this for now because it unexpectedly stopped working
	# exec 4<&1 5<&2 1>&2>&>(tee -a >(sed -r 's/\x1B\S*\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' > "$ROPERDOT_LOGFILE"))
	# exec 4<&1 5<&2 1>&2>&>(tee -a >(sed -E 's/'$'\033''\[[^a-zA-Z]*[mK]//g' > "$ROPERDOT_LOGFILE"))
	export ROPERDOT_CURRENT_SHELL=bash
	if [[ "$ROPERDOT_OS_NAME" = darwin ]]; then
		# Use Homebrew bash (bash 4) to run the install
		/usr/local/bin/bash "${ROPERDOT_DIR}/install-profiles/standard/install-roperdot.sh" "$@"
	else
		bash "${ROPERDOT_DIR}/install-profiles/standard/install-roperdot.sh" "$@"
	fi
else
	# Logging approach used with bash won't work with zsh
	export ROPERDOT_CURRENT_SHELL=zsh
	zsh "${ROPERDOT_DIR}/install-profiles/standard/install-roperdot.sh" "$@"
fi
