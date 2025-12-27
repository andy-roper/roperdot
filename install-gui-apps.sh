	install_gui_apps () {
		# Skip if force_gui_app_installs is "none"
		[[ "$force_gui_app_installs" = "none" ]] && return

		local app_file="$1"
	    local install_list=() install_desc_list=() prereq_indices=() app_count
	    local app_names=() should_install=() preselected_items=()

	    # default profile to standard if not defined
	    export profile=${profile:-standard}

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

	        should_install_app "$app" "$groups" "$exclusionGroups" "$disabledByDefault" "$install_groups" || continue

	        if [[ -n "$always_include" ]] || ! gui_app_is_present "$app" "$app_dir" "$bundle_name" "$full_app_path" "$binary" "$package" "$package_manager"; then
	            # Check if prerequisites are met
	            local prereq_met=true
	            if [[ -n "$list_prerequisite" ]]; then
	                command -v "$list_prerequisite" >/dev/null 2>&1 || prereq_met=
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
	                [[ -n "$app_name" ]] && name="$app_name" || name="$app"
	                local desc_text=""
	                if [[ -n "$missing_prereqs" ]]; then
	                    desc_text=" (requires: ${missing_prereqs})"
	                fi
	                if [[ -z "$desc" ]]; then
	                    install_desc_list+=("${name}${desc_text}")
	                else
	                    install_desc_list+=("${name}${desc_text}: $desc")
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
	    done

		[[ "${#install_desc_list[@]}" -eq 0 ]] && return
		
		echo -e "\nSelect GUI applications to install:\n"
		
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

		# Installation loop - process in order, only installing where should_install is true
		for ((i=0; i<${#install_list[@]}; i++)); do
			# Skip if not marked for installation
			[[ "${should_install[$i]}" != "true" ]] && continue
			
			local app_index="${install_list[$i]}"

			# Clear variables and reload app data
			for var in "${install_vars[@]}"; do
				unset "$var"
			done

			eval "$(python3 "$ROPERDOT_DIR/bin/json-to-simple-vars" "$app_file" "$app_index" "$base_profile" --optional "${extra_profiles[@]}")"
			[[ -n "$app_name" ]] && name="$app_name" || name="$app"
			
			# Install without prompting (already selected via gum)
			# Reset colors in case the previous install didn't clean up after itself
			tput sgr0
			echo -e "\nInstalling $name..."
			
			# pause_specified_installations "$app"
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
				case "$ROPERDOT_OS_ENV" in
					darwin)
						if [[ -n "$has_sudo" ]]; then
							install_func() { brew install "$package"; }
						else
							install_func() { brew install "$package" --appdir=~/Applications; }
						fi
						;;
					ubuntu|mint|debian)
						if [[ "$ROPERDOT_DESKTOP_ENV" = windows ]]; then
							# WSL
							install_func() { choco.exe install -y --ignore-pending-reboot "$package"; }
						else
							if [[ "$package_manager" = apt || "$package_manager" = "apt-get" ]]; then
								install_func() { sudo apt install "$package" -y; }
							elif [[ "$package_manager" = snap ]]; then
								install_func() { sudo snap install "$package"; }
							fi
						fi
						;;
				esac
			fi
			[[ -n "$show_start_times" ]] && echo "Start time: $(date +"%r")"
			install_app || return
			if [[ -n "$shortcut_path" ]]; then
				if [[ -n "$shortcut_name" ]]; then
					[[ "$(desktop_shortcut_exists "${shortcut_name}")" ]] || create-windows-shortcut "${shortcut_name}" "${shortcut_path}"
				else
					[[ "$(desktop_shortcut_exists "${app}")" ]] || create-windows-shortcut "${app}" "${shortcut_path}"
				fi
			fi
		done
	}
