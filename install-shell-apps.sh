	install_shell_apps () {
		# Skip if force_shell_app_installs is "none"
		[[ "$force_shell_app_installs" = "none" ]] && return

		local app_file="$1" default_installer="$2" have_default_installer 
	    local install_list=() install_desc_list=() prereq_indices=() app_count
	    local app_names=() should_install=() preselected_items=()
	    command -v "$default_installer" >/dev/null 2>&1 && local have_default_installer=true
	    
	    # Get total number of apps from all profiles
	    app_count=$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$app_file" count "$base_profile" --optional "${extra_profiles[@]}")

	    # First pass: determine which apps to install and build prereq mappings
	    for ((i=0; i<app_count; i++)); do
	        # Clear previous variables
	        for var in "${install_vars[@]}"; do
	            unset "$var"
	        done

	        eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$app_file" "$i" "$base_profile" --optional "${extra_profiles[@]}")"

	        # Skip if no app name
	        [[ -z "$app" ]] && continue
	        
	        if [[ -z "$skip" && -n "$include_condition" ]]; then
	            eval "$include_condition" || skip=true
	        fi
	        [[ -n "$skip" ]] && continue
	        
	        should_install_app "$app" "$groups" "$exclusionGroups" "$disabledByDefault" "$install_groups" || continue

	        if [[ -z "$skip" ]]; then
	            unset sudo_ok
	            if [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then
	            	sudo_ok=true
	            else
	            	[[ -n "$has_sudo" || -n "$sudo_not_required" ]] && sudo_ok=true
	            fi
	            
	            if [[ -n "$sudo_ok" ]] && ! app_is_present "$app" "$binary" "$package" "$list_prerequisite" "$presence_command"; then
	                local prereq_met=
	                if [[ -n "$sudo_not_required" ]]; then
	                    prereq_met=true
	                else
	                    if [[ -z "$list_prerequisite" || "$list_prerequisite" = "$default_installer" ]]; then
	                        prereq_met=$have_default_installer
	                    else
	                        prereq_met=true
	                        [[ -n "$list_prerequisite" ]] && ! command -v "$list_prerequisite" >/dev/null 2>&1 && unset prereq_met
	                    fi
	                fi
	                if [[ -n "$prereq_met" ]]; then
	                    install_list+=("$i")  # Store JSON index
	                    app_names+=("$app")   # Store app name for prereq lookup
	                    
	                    # Build prereq index mapping and description text
	                    local prereq_idx_list=""
	                    local missing_prereqs=""
	                    if [[ -n "$install_prerequisite" ]]; then
	                        # Split on commas
	                        if [[ "$ROPERDOT_CURRENT_SHELL" = bash ]]; then
	                            IFS=',' read -ra prereq_apps <<< "$install_prerequisite"
	                        else
	                            IFS=',' read -rA prereq_apps <<< "$install_prerequisite"
	                        fi
	                        
	                        # Find each prereq in app_names list
	                        local prereq_app
	                        for prereq_app in "${prereq_apps[@]}"; do
	                            for ((j=0; j<${#app_names[@]}; j++)); do
	                                if [[ "${app_names[$j]}" = "$prereq_app" ]]; then
	                                    # This prereq is in the install list (not already installed)
	                                    [[ -n "$prereq_idx_list" ]] && prereq_idx_list+=","
	                                    prereq_idx_list+="$j"
	                                    [[ -n "$missing_prereqs" ]] && missing_prereqs+=", "
	                                    missing_prereqs+="$prereq_app"
	                                    break
	                                fi
	                            done
	                        done
	                    fi
	                    prereq_indices+=("$prereq_idx_list")
	                    
	                    # Build description with only missing prereqs
	                    local desc_text=""
	                    if [[ -n "$missing_prereqs" ]]; then
	                        desc_text=" (requires: ${missing_prereqs})"
	                    fi
	                    if [[ -z "$desc" ]]; then
	                        install_desc_list+=("${app}${desc_text}")
	                    else
	                        install_desc_list+=("${app}${desc_text}: $desc")
	                    fi
	                    
	                    # Check if this app should be pre-selected based on groups
	                    if [[ -n "$groups" && -n "$install_groups" ]]; then
	                        local app_groups_list="${groups//,/ }"
	                        local selected_groups_list="${install_groups//,/ }"
	                        for selected_group in $selected_groups_list; do
	                            if [[ " $app_groups_list " =~ " $selected_group " ]]; then
	                                # Get last added description
	                                local last_idx=$((${#install_desc_list[@]} - 1))
	                                preselected_items+=("${install_desc_list[$last_idx]}")
	                                break
	                            fi
	                        done
	                    fi
	                fi
	            fi
	        fi
	    done
		
		[[ "${#install_desc_list[@]}" -eq 0 ]] && return
		
		echo -e "\nSelect shell applications to install:\n"
		
		# Build gum command with pre-selections
		local gum_args=("choose" "--no-limit" "--height=20")
		for item in "${preselected_items[@]}"; do
		    gum_args+=("--selected=$item")
		done
		
		# Add all items
		for item in "${install_desc_list[@]}"; do
		    gum_args+=("$item")
		done
		
		# Get user selections
		local selected_items
		selected_items=$(gum "${gum_args[@]}")
		
		# If nothing selected, return
		[[ -z "$selected_items" ]] && return
		
		# Initialize should_install array (all false)
		for ((i=0; i<${#install_list[@]}; i++)); do
		    should_install+=(false)
		done
		
		# Process selections - mark selected items as true
		while IFS= read -r selected_item; do
		    for ((i=0; i<${#install_desc_list[@]}; i++)); do
		        if [[ "${install_desc_list[$i]}" = "$selected_item" ]]; then
		            should_install[$i]=true
		            
		            # Auto-add prereqs
		            if [[ -n "${prereq_indices[$i]}" ]]; then
		                IFS=',' read -ra prereq_idxs <<< "${prereq_indices[$i]}"
		                for prereq_idx in "${prereq_idxs[@]}"; do
		                    should_install[$prereq_idx]=true
		                done
		            fi
		            break
		        fi
		    done
		done <<< "$selected_items"

		if [[ "$ROPERDOT_OS_FAMILY" = debian && "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
			echo -e "\nThis warning can be ignored when applications are being installed by Linuxbrew:"
			echo -e "nice: cannot set niceness: Permission denied\n"
		fi

		# Keep sudo access alive in the background during the installs
	    if [[ -n "$has_sudo" && "${#install_list[@]}" -gt 0 ]]; then
	        echo "Authenticating for package installations..."
	        sudo -v
	        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	        local SUDO_KEEPALIVE_PID=$!
	    fi

		# Installation loop - process in order, only installing where should_install is true
		for ((i=0; i<${#install_list[@]}; i++)); do
			# Skip if not marked for installation
			[[ "${should_install[$i]}" != "true" ]] && continue
			
			local app_index="${install_list[$i]}"
			
			if [[ -d ~/.nvm ]] && ! command -v node >/dev/null 2>&1; then
				if [[ $(ls ~/.nvm/versions/node 2>/dev/null | wc -l) -ne 0 ]]; then
					export NVM_DIR="$HOME/.nvm"
					[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
					# Create symlinks so sudo has access to node and npm
					if [[ -n "$has_sudo" ]]; then
						export NVM_VERSION="$(nvm version)"
						[[ -e /usr/local/bin/node ]] || sudo ln -s "$NVM_DIR/versions/node/$NVM_VERSION/bin/node" /usr/local/bin/node
						[[ -e /usr/local/bin/npm ]] || sudo ln -s "$NVM_DIR/versions/node/$NVM_VERSION/bin/npm" /usr/local/bin/npm
					fi
				fi
			fi
			
			# Clear variables and reload app data
			for var in "${install_vars[@]}"; do
				unset "$var"
			done
			eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$app_file" "$app_index" "$base_profile" --optional "${extra_profiles[@]}")"
			
			# default profile to standard if not defined
			export profile=${profile:-standard}

			[[ -z "$binary" ]] && binary="$app"
			
			# Install without prompting (already selected via gum)
			if install_prereq_present "$install_prerequisite"; then
				# Reset colors in case the previous install didn't clean up after itself
				tput sgr0
				echo
				echo "Installing $app..."
				
				if [[ -n "$install_script" ]]; then
					eval "install_func() { $ROPERDOT_CURRENT_SHELL \"${ROPERDOT_DIR}/install-profiles/$profile/installs/$install_script\"; }"
				elif [[ -n "$install_command" ]]; then
					local re=";\$"
					[[ "$install_command" =~ $re ]] || install_command="$install_command;"
					eval "install_func() { $install_command }"
				else
					[[ -z "$package" ]] && package="$binary"
					if [[ "$ROPERDOT_DESKTOP_ENV" = windows && "$list_prerequisite" = choco ]]; then
						install_func() { if [[ -n "$has_sudo" ]]; then choco install -y --ignore-pending-reboot --force $package; else install_windows_binary; fi }
					elif [[ "$ROPERDOT_OS_FAMILY" = debian && "$install_prerequisite" = brew ]]; then
						install_func() { brew install $package; }
					elif [[ "$install_prerequisite" = pip3 ]]; then
						install_func() { pip3 install $package; }
					else
						install_func() { standard_install; }
					fi
				fi
				[[ -n "$show_start_times" ]] && echo "Start time: $(date +"%r")"

				install_app || return
				if [[ "$app" = "Linuxbrew" ]]; then
					export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
					hash -r
				elif [[ "$app" = "Python" && -z "$python_bin" ]]; then
					if command -v python >/dev/null 2>&1; then
						export python_bin=python
						export python_version=$(python -c 'import sys; print("{}.{}").format(sys.version_info.major, sys.version_info.minor))')
						if [[ -n "$PYTHONPATH" ]]; then
							export PYTHONPATH="${PYTHONPATH}:${LOCALUSR}/lib/python${python_version}"
						else
							export PYTHONPATH="${LOCALUSR}/lib/python${python_version}"
						fi
					fi
				elif [[ "$app" = "Python 3" && "$python_bin" != "python3" ]]; then
					if command -v python3 >/dev/null 2>&1; then
						export python_bin=python3
						export python_version=$(python3 -c 'import sys; print("{}.{}").format(sys.version_info.major, sys.version_info.minor))')
						if [[ -n "$PYTHONPATH" ]]; then
							export PYTHONPATH="${PYTHONPATH}:${LOCALUSR}/lib/python${python_version}"
						else
							export PYTHONPATH="${LOCALUSR}/lib/python${python_version}"
						fi
					fi
				elif [[ "$app" = "Node.js" ]]; then
					[[ "$ROPERDOT_DESKTOP_ENV" = "windows" && -d "${rd_program_files}/nodejs" ]] && export PATH="$PATH:${rd_program_files}/nodejs"
				fi
			fi
		done

		[[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
	}