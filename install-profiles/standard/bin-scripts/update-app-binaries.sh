#
# Description: Updates ~/.roperdot-os-functions and app binaries for the current OS
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
func_file=~/.roperdot-os-functions

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
update-app-binaries: update $func_file and app binaries for the current OS
Usage: update-app-binaries

This script will generate $func_file and build scripts in roperdot/app-bin-bash
and/or roperdot/app-bin-zsh based on the machine's OS and the applications that
are installed.

NOTE: The PROCESSING_BASH and PROCESSING_ZSH environment variables determine
which shells to generate scripts for. If neither is defined, the current shell
will be assumed.
EOT
    exit 0
fi

[[ -z "$ROPERDOT_DESKTOP_ENV" ]] && exit 0

. "$ROPERDOT_DIR/source-scripts/abs-path"
. "$ROPERDOT_DIR/source-scripts/re-match"
[[ $ROPERDOT_OS_ENV = ubuntu && $ROPERDOT_DESKTOP_ENV = windows ]] && . "${ROPERDOT_DIR}/source-scripts/win-env-functions"

# Strategy:
# PROCESSING_BASH or PROCESSING_ZSH is true
# * In an install.sh install
# * If either is untrue, remove the app-bin directory for that shell
# PROCESSING_BASH and PROCESSING_ZSH are both untrue
# * Set PROCESSING_BASH or PROCESSING_ZSH based on the current_shell
# * If the other app-bin directory exists, process it too

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

if [[ $current_shell = zsh && ! -o NULL_GLOB ]]; then
    need_to_unset_null_glob=true
    setopt NULL_GLOB
fi

echo Creating $func_file and app binaries

if [[ -n $PROCESSING_BASH || -n $PROCESSING_ZSH ]]; then
    if [[ -n $PROCESSING_BASH ]]; then
        if [[ -d "$ROPERDOT_DIR"/app-bin-bash ]]; then
            \rm "$ROPERDOT_DIR"/app-bin-bash/* >/dev/null 2>&1
        else
            mkdir "$ROPERDOT_DIR"/app-bin-bash
        fi
    elif ! command -v bash >/dev/null 2>&1; then
        \rm -rf "$ROPERDOT_DIR"/app-bin-bash
    fi
    if [[ -n $PROCESSING_ZSH ]]; then
        if [[ -d "$ROPERDOT_DIR"/app-bin-zsh ]]; then
            \rm "$ROPERDOT_DIR"/app-bin-zsh/* >/dev/null 2>&1
        else
            mkdir "$ROPERDOT_DIR"/app-bin-zsh
        fi
    elif ! command -v zsh >/dev/null 2>&1; then
        \rm -rf "$ROPERDOT_DIR"/app-bin-zsh
    fi
else
    if [[ $current_shell = zsh ]]; then
        PROCESSING_ZSH=true
        if [[ -d "$ROPERDOT_DIR"/app-bin-zsh ]]; then
            \rm "$ROPERDOT_DIR"/app-bin-zsh/* >/dev/null 2>&1
        else
            mkdir "$ROPERDOT_DIR"/app-bin-zsh
        fi
        if [[ -d "$ROPERDOT_DIR"/app-bin-bash ]]; then
            PROCESSING_BASH=true
            \rm "$ROPERDOT_DIR"/app-bin-bash/* >/dev/null 2>&1
        fi
    else
        PROCESSING_BASH=true
        if [[ -d "$ROPERDOT_DIR"/app-bin-bash ]]; then
            \rm "$ROPERDOT_DIR"/app-bin-bash/* >/dev/null 2>&1
        else
            mkdir "$ROPERDOT_DIR"/app-bin-bash
        fi
        if [[ -d "$ROPERDOT_DIR"/app-bin-zsh ]]; then
            PROCESSING_ZSH=true
            \rm "$ROPERDOT_DIR"/app-bin-zsh/* >/dev/null 2>&1
        fi
    fi
fi

[[ -n $PROCESSING_BASH ]] && echo "Creating bash scripts"
[[ -n $PROCESSING_ZSH ]] && echo "Creating zsh scripts"

# last_matching_dir will return the lexicographically largest directory matching the string
last_matching_dir () {
    re_match "$1" "^(.*)/(.*?)\$"
    find "${re_match[1]}" -maxdepth 1 -type d -iname "${re_match[2]}*" 2>/dev/null | sort -f | tail -1
}

create_binary_script_linux () {
    if [[ $# -eq 1 ]]; then
        binpath=$(\which "$1")
        [[ -z "$binpath" ]] && return
        read -r -d '' script_text << EOT
app="$binpath"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" >& /dev/null& )
else
    ( "\$app" >& /dev/null& )
fi
EOT
    else
        if [[ $# -ne 2 ]]; then
            [[ ! -d "$1" ]] && return
            shift
        fi
        read -r -d '' script_text << EOT
app="$2"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" >& /dev/null& )
else
    ( "\$app" >& /dev/null& )
fi
EOT
    fi
    [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
    [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
}

create_browser_script_linux () {
    if [[ $# -eq 1 ]]; then
        binpath=$(\which "$1")
        [[ -z "$binpath" ]] && return
        read -r -d '' script_text << EOT
app="$binpath"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" >& /dev/null& )
elif [[ "$1" =~ ^(http|www) ]]; then
    ( "\$app" "\$1" >& /dev/null& )
else
    ( "\$app" >& /dev/null& )
fi
EOT
    else
        if [[ $# -ne 2 ]]; then
            [[ ! -d "$1" ]] && return
            shift
        fi
        read -r -d '' script_text << EOT
app="$2"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" >& /dev/null& )
elif [[ "\$1" =~ ^(http|www) ]]; then
    ( "\$app" "\$1" >& /dev/null& )
else
    ( "\$app" >& /dev/null& )
fi
EOT
    fi
    [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
    [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
}

create_app_script () {
    local script_name=$1
    local bash_script
    local zshScript
    shift
    for script; do
        [[ -n $PROCESSING_BASH && -e "$ROPERDOT_DIR"/app-bin-bash/$script ]] && bash_script=$script
        [[ -n $PROCESSING_ZSH && -e "$ROPERDOT_DIR"/app-bin-zsh/$script ]] && zshScript=$script
        [[ -n $bash_script || -n $zshScript ]] && break
    done
    [[ -n $PROCESSING_BASH && -z $bash_script ]] && bash_script=$default_app
    [[ -n $PROCESSING_ZSH && -z $zshScript ]] && zshScript=$default_app
    if [[ -n $bash_script ]]; then
        cat << EOT >> "$ROPERDOT_DIR"/app-bin-bash/"$script_name"
#!/usr/bin/env bash
( $bash_script "\$@" & )
EOT
    fi
    if [[ -n $zshScript ]]; then
        cat << EOT >> "$ROPERDOT_DIR"/app-bin-zsh/"$script_name"
#!/usr/bin/env zsh
( $zshScript "\$@" & )
EOT
    fi
}

create_text_editor_script () {
    local script_name=$1
    local bash_script
    local zshScript
    shift
    for script; do
        [[ -n $PROCESSING_BASH && -e "$ROPERDOT_DIR"/app-bin-bash/$script ]] && bash_script=$script
        [[ -n $PROCESSING_ZSH && -e "$ROPERDOT_DIR"/app-bin-zsh/$script ]] && zshScript=$script
        [[ -n $bash_script || -n $zshScript ]] && break
    done
    [[ -n $PROCESSING_BASH && -z $bash_script ]] && bash_script=$default_app
    [[ -n $PROCESSING_ZSH && -z $zshScript ]] && zshScript=$default_app
    if [[ -n $bash_script ]]; then
        cat << EOT >> "$ROPERDOT_DIR"/app-bin-bash/"$script_name"
#!/usr/bin/env bash
if [[ -n "\$VSCODE_INJECTION" ]] || [[ "\$TERM_PROGRAM" == "vscode" ]] || [[ -n "\$VSCODE_PID" ]]; then
    code "\$@" &
else
    ( $bash_script "\$@" & )
fi
EOT
    fi
    if [[ -n $zshScript ]]; then
        cat << EOT >> "$ROPERDOT_DIR"/app-bin-zsh/"$script_name"
#!/usr/bin/env zsh
if [[ -n "\$VSCODE_INJECTION" ]] || [[ "\$TERM_PROGRAM" == "vscode" ]] || [[ -n "\$VSCODE_PID" ]]; then
    code "\$@" &
else
    ( $zshScript "\$@" & )
fi
EOT
    fi
}

#>"$func_file"
echo -n > "$func_file"

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then

    SYSTEM32=$(win_env_linux_path SYSTEMROOT)/System32

    create_binary_script_windows () {
        [[ ! -f "$2" ]] && return
        read -r -d '' script_text << EOT
app="$2"
if [[ -e "\$1" ]]; then
    ( "\$app" "\$(fix-path "\$1")" >/dev/null 2>&1 & )
else
    ( "\$app" >/dev/null 2>&1 & )
fi
EOT
        [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
        [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
        created=1
    }

    create_binary_script_windows_pf () {
        unset created
        create_binary_script_windows "$1" "${rd_program_files}/$2"
        [[ -z "$created" ]] && create_binary_script_windows "$1" "${rd_program_files_x86}/$2"
    }

    create_browser_script_windows () {
        [[ ! -f "$2" ]] && return
        read -r -d '' script_text << EOT
app="$2"
if [[ -e "\$1" ]]; then
    ( "\$app" "\$(fix-path "\$1")" >/dev/null 2>&1 & )
elif [[ "\$1" =~ ^(http|www) ]]; then
    ( "\$app" "\$1" >/dev/null 2>&1 & )
else
    ( "\$app" >/dev/null 2>&1 & )
fi
EOT
        [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
        [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
        created=1
    }

    create_browser_script_windows_pf () {
        unset created
        create_browser_script_windows "$1" "${rd_program_files}/$2"
        [[ -z "$created" ]] && create_browser_script_windows "$1" "${rd_program_files_x86}/$2"
    }

    cat << EOT >> "$func_file"
exp () {
    local f
    if [[ \$# -eq 0 ]]; then
        f="\$(fix-path "\$(pwd)")"
    else
        local abs_file="\$(abs-path "\$1")"
         if [[ -f "\$abs_file" ]]; then
            fm_archive "\$abs_file"
        elif [[ ! -d "\$1" ]]; then
            echo "Error: directory \$1 does not exist"
        else
            f="\$(fix-path "\$1")"
        fi
    fi
    [[ -n "\$f" ]] && ( explorer.exe "\$f" & )
}

fm () {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    [[ \$# -eq 0 ]] && \$ROPERDOT_FILE_MANAGER || \$ROPERDOT_FILE_MANAGER "\$1"
}
EOT
    if [[ -d "${rd_program_files}/GPSoftware/Directory Opus" ]]; then
        cat << EOT >> "$func_file"
dopus () {
    local f
    if [[ \$# -eq 0 ]]; then
        f="\$(fix-path "\$(pwd)")"
    else
        local abs_file="\$(abs-path "\$1")"
         if [[ -f "\$abs_file" ]]; then
            fm_archive "\$abs_file"
        elif [[ ! -d "\$1" ]]; then
            echo "Error: directory \$1 does not exist"
        else
            f="\$(fix-path "\$1")"
        fi
    fi
    [[ -n "\$f" ]] && ( "${rd_program_files}/GPSoftware/Directory Opus/dopus.exe" "\$f" & )
}
export ROPERDOT_FILE_MANAGER=dopus
EOT
    else
        echo "export ROPERDOT_FILE_MANAGER=exp" >> "$func_file"
    fi
    
    winuser="$(cd /mnt/c && cmd.exe /c "echo %USERNAME%" 2>/dev/null)"

    create_binary_script_windows_pf subl Sublime\ Text/subl.exe
    # create_binary_script_windows_pf code Microsoft\ Visual\ Studio/2019/Community/Common7/IDE/devenv.exe
    # create_binary_script_windows code "/mnt/c/Users/${winuser}/AppData/Local/Programs/Microsoft VS Code/code"
    create_binary_script_windows_pf code "Microsoft VS Code/bin/code.exe"
    create_binary_script_windows_pf npp "Notepad++/notepad++.exe"
    create_binary_script_windows_pf uedit IDM\ Computer\ Solutions/UltraEdit/uedit64.exe
    create_binary_script_windows notepad "$SYSTEM32"/notepad.exe
    create_browser_script_windows_pf firefox Mozilla\ Firefox/firefox.exe
    create_browser_script_windows_pf chrome Google/Chrome/Application/chrome.exe
    create_browser_script_windows_pf ie Internet\ Explorer/iexplore.exe
    create_binary_script_windows_pf winrar WinRAR/WinRAR.exe
    create_binary_script_windows_pf winzip WinZip/WINZIP64.EXE
    create_binary_script_windows_pf vlc VideoLAN/VLC/vlc.exe
    create_binary_script_windows_pf foobar2000 foobar2000/foobar2000.exe
    create_binary_script_windows_pf wmp Windows\ Media\ Player/wmplayer.exe
    # Windows image viewer: Photos: can't get it to open a specified file!?!?!?!
    create_binary_script_windows paint "$SYSTEM32"/mspaint.exe
    create_binary_script_windows_pf winamp Winamp/winamp.exe
    create_binary_script_windows_pf irfanview IrfanView/i_view64.exe

    gimp_dir=$(max-file-for-pattern "$rd_program_files" "^GIMP \\d+")
    if [[ -n "$gimp_dir" ]]; then
        gimp_path=$(find "$gimp_dir" -regextype posix-extended -regex "^.*/gimp-[0-9].*\.exe")
        [[ -n "$gimp_path" ]] && create_binary_script_windows gimp "$gimp_path"
    fi
    create_binary_script_windows_pf acrobat Adobe/Acrobat\ Reader\ DC/Reader/AcroRd32.exe
    create_binary_script_windows_pf cdisplayex CDisplayEx/CDisplayEx.exe
    create_binary_script_windows_pf calibre Calibre2/ebook-viewer.exe

    office_dir=$(last_matching_dir "$rd_program_files/Microsoft Office/Office")
    [[ -z "$office_dir" ]] && office_dir=$(last_matching_dir "$rd_program_files_x86/Microsoft Office/Office")

    if [[ -n "$office_dir" ]]; then
        create_binary_script_windows word "$office_dir/WINWORD.EXE"
        create_binary_script_windows excel "$office_dir/EXCEL.EXE"
        create_binary_script_windows powerpoint "$office_dir/POWERPNT.EXE"
    else
        office_dir=$(last_matching_dir "$rd_program_files/LibreOffice")
        [[ -z "$office_dir" ]] && office_dir=$(last_matching_dir "$rd_program_files_x86/OpenOffice")
        if [[ -n "$office_dir" ]]; then
            create_binary_script_windows word "$office_dir/program/swriter.exe"
            create_binary_script_windows excel "$office_dir/program/scalc.exe"
            create_binary_script_windows powerpoint "$office_dir/program/simpress.exe"
        fi
    fi

    create_binary_script_windows_pf typora "Typora/Typora.exe"
    create_binary_script_windows_pf ghostwriter "ghostwriter/ghostwriter.exe"

    default_app=explorer
    create_app_script archive-editor-app winrar winzip
    default_app=show-file
    create_text_editor_script text-editor-app subl npp uedit notepad
    create_app_script code-editor-app code subl npp uedit notepad
    create_app_script web-browser-app chrome firefox ie
    create_app_script video-player-app vlc wmp
    create_app_script video-editor-app vlc wmp
    create_app_script audio-player-app foobar2000 winamp wmp
    create_app_script audio-editor-app foobar2000 winamp wmp
    create_app_script image-viewer-app irfanview paint
    create_app_script image-editor-app gimp paint
    create_app_script pdf-viewer-app acrobat
    create_app_script pdf-editor-app acrobat
    create_app_script ebook-viewer-app calibre
    create_app_script word-processor-app word
    create_app_script spreadsheet-app excel
    create_app_script presentation-app powerpoint
    default_app=list-archive
    create_app_script comic-viewer-app cdisplayex winrar winzip
    create_text_editor_script markdown-app typora ghostwriter npp

elif [[ "$ROPERDOT_OS_ENV" = "darwin" ]]; then

    app_path () {
        local app_name="$1.app"
        
        if [[ -d "$HOME/Applications/$app_name" ]]; then
            echo "$HOME/Applications/$app_name"
        elif [[ -d "/Applications/$app_name" ]]; then
            echo "/Applications/$app_name"
        else
            echo "NOT FOUND"
        fi
    }

    create_binary_script_mac () {
        local script_text
        if [[ $# -eq 1 ]]; then
            binpath=$(\which "$1")
            [[ -z "$binpath" ]] && return
            read -r -d '' script_text << EOT
app="$binpath"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" & )
else
    ( "\$app" & )
fi
EOT
        else
            if [[ $# -ne 2 ]]; then
                [[ ! -d "$1" ]] && return
                shift
            fi
            read -r -d '' script_text << EOT
if [[ -n "\$1" ]]; then
    ( $2 "\$(abs-path "\$1")" & )
else
    ( $2 & )
fi
EOT
        fi
        [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
        [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
    }

    create_browser_script_mac () {
        local script_text
        if [[ $# -eq 1 ]]; then
            binpath=$(\which "$1")
            [[ -z "$binpath" ]] && return
            read -r -d '' script_text << EOT
app="$binpath"
if [[ -n "\$1" ]]; then
    ( "\$app" "\$(abs-path "\$1")" & )
elif [[ "\$1" =~ ^(http|www) ]]; then
    ( "\$app" "\$1" & )
else
    ( "\$app" & )
fi
EOT
        else
            if [[ $# -ne 2 ]]; then
                [[ ! -d "$1" ]] && return
                shift
            fi
            read -r -d '' script_text << EOT
if [[ -n "\$1" ]]; then
    ( $2 "\$(abs-path "\$1")" & )
elif [[ "\$1" =~ ^(http|www) ]]; then
    ( $2 "\$1" & )
else
    ( $2 & )
fi
EOT
        fi
        [[ -n $PROCESSING_BASH ]] && echo "#!/usr/bin/env bash" > "$ROPERDOT_DIR"/app-bin-bash/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-bash/"$1"
        [[ -n $PROCESSING_ZSH ]] && echo "#!/usr/bin/env zsh" > "$ROPERDOT_DIR"/app-bin-zsh/"$1" && echo "$script_text" >> "$ROPERDOT_DIR"/app-bin-zsh/"$1"
    }

    cat << EOT >> "$func_file"
finder () {
    local localpath
    if [[ \$# -eq 0 ]]; then
        localpath="\$(pwd)"
    else
        localpath="\$(realpath "\$1")"
        local re="^.*/Applications/[^/]+/?\$"
        if [[ "\$localpath" =~ \$re ]]; then
            localpath="\$localpath/Contents"
        elif [[ -f "\$localpath" ]]; then
            fm_archive "\$localpath"
            return
        fi
        if [[ ! -d "\$localpath" ]]; then
            echo "Error: directory \$localpath does not exist"
            return
        fi
    fi
    ( /usr/bin/open "\$localpath" & )
}
EOT
    if [[ "$(app_path 'Path Finder')" != "NOT FOUND" ]]; then
        cat << EOT >> "$func_file"
pathfinder () {
    local localpath
    if [[ \$# -eq 0 ]]; then
        localpath="\$(pwd)"
    else
        localpath="\$(realpath "\$1")"
        local re="^.*/Applications/[^/]+/?\$"
        if [[ "\$localpath" =~ \$re ]]; then
            localpath="\$localpath/Contents"
        elif [[ -f "\$localpath" ]]; then
            fm_archive "\$localpath"
            return
        fi
        if [[ ! -d "\$localpath" ]]; then
            echo "Error: directory \$localpath does not exist"
            return
        fi
    fi
    ( /usr/bin/open -a "Path Finder" "\$localpath" & )
}
EOT
        primary_fm=pathfinder
    elif [[ "$(app_path 'Forklift')" != "NOT FOUND" ]]; then
        cat << EOT >> "$func_file"
forklift () {
    local localpath
    if [[ \$# -eq 0 ]]; then
        localpath="\$(pwd)"
    else
        localpath="\$(realpath "\$1")"
        local re="^.*/Applications/[^/]+/?\$"
        if [[ "\$localpath" =~ \$re ]]; then
            localpath="\$localpath/Contents"
        elif [[ -f "\$localpath" ]]; then
            fm_archive "\$localpath"
            return
        fi
        if [[ ! -d "\$localpath" ]]; then
            echo "Error: directory \$localpath does not exist"
            return
        fi
    fi
    ( /usr/bin/open -a "Forklift" "\$localpath" & )
}
EOT
        primary_fm=forklift
    fi
    if [[ -n "$primary_fm" ]]; then
        cat << EOT >> "$func_file"
fm () {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    if [[ \$# -eq 0 ]]; then
        $primary_fm
    elif [[ "\$1" =~ ^\\.dmg$ ]]; then
        finder "\$1"
    else
        $primary_fm "\$1"
    fi
}
EOT
		echo "export ROPERDOT_FILE_MANAGER=$primary_fm" >> "$func_file"
    else
        cat << EOT >> "$func_file"
fm () {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    [[ \$# -eq 0 ]] && finder || finder "\$1"
}
EOT

		echo "export ROPERDOT_FILE_MANAGER=finder" >> "$func_file"
    fi
    application_path="$(app_path 'Sublime Text')"
    create_binary_script_mac "$application_path" sublime-text "\"${application_path}/Contents/SharedSupport/bin/subl\" --add"
    #"
    create_binary_script_mac "$(app_path 'Visual Studio Code')" code "open -a \"Visual Studio Code\""
    create_binary_script_mac "$(app_path TextWrangler)" textwrangler "open -a TextWrangler"
    create_binary_script_mac textedit "open -a TextEdit"
    create_browser_script_mac "$(app_path 'Google Chrome')" chrome "open -a \"Google Chrome\""
    create_browser_script_mac "$(app_path Firefox)" firefox "open -a Firefox"
    create_browser_script_mac safari "open -a Safari"
    create_binary_script_mac "$(app_path BetterZip)" betterzip "open -a BetterZip"
    create_binary_script_mac archiveutility "open -a \"Archive Utility\""
    create_binary_script_mac "$(app_path VLC)" vlc "open -a VLC"
    create_binary_script_mac quicktime "open -a \"QuickTime Player\""
    create_binary_script_mac "$(app_path foobar2000)" foobar2000 "open -a foobar2000"
    create_binary_script_mac itunes "open -a iTunes"
    create_binary_script_mac preview "open -a Preview"
    create_binary_script_mac "$(app_path Gimp)" gimp "open -a Gimp"
    application_path="$(app_path calibre)"
    create_binary_script_mac "$application_path" calibre "${application_path}/Contents/MacOS/ebook-viewer"
    create_binary_script_mac opendoc "open"
    create_binary_script_mac simplecomic "open -a \"Simple Comic\""
    create_binary_script_mac word "open -a \"Microsoft Word\""
    create_binary_script_mac excel "open -a \"Microsoft Excel\""
    create_binary_script_mac powerpoint "open -a \"Microsoft PowerPoint\""
    create_binary_script_mac macdown "open -a MacDown"
    
    default_app=show-file
    create_text_editor_script text-editor-app sublime-text textwrangler textedit
    create_app_script code-editor-app code sublime textwrangler textedit
    create_app_script web-browser-app chrome firefox safari
    create_app_script archive-editor-app betterzip archiveutility
    create_app_script video-player-app vlc quicktime
    create_app_script video-editor-app vlc quicktime
    create_app_script audio-player-app foobar2000 itunes
    create_app_script audio-editor-app foobar2000 itunes
    create_app_script image-viewer-app preview
    create_app_script image-editor-app gimp preview
    create_app_script pdf-viewer-app preview
    create_app_script pdf-editor-app preview
    create_app_script ebook-viewer-app calibre preview
    create_app_script word-processor-app opendoc
    create_app_script spreadsheet-app opendoc
    create_app_script presentation-app opendoc
    create_text_editor_script markdown-app macdown
    default_app=list-archive
    create_app_script comic-viewer-app simplecomic betterzip archiveutility

elif [[ "$ROPERDOT_OS_ENV" = "ubuntu" ]]; then
    cat << EOT >> "$func_file"
nautilus () {
    if [[ \$# -eq 0 ]]; then
        ( /usr/bin/nautilus --browser "\$(pwd)" >&/dev/null & )
    elif [[ "\$1" =~ ^(http|www) ]]; then
        ( /usr/bin/nautilus "\$1" >&/dev/null & )
    else
        local f="\$(fix-path "\$1")"
        if [[ -f "$f" ]]; then
            fm_archive "\$f"
        elif [[ ! -d "$f" ]]; then
            echo "Error: directory \$f does not exist"
        else
            ( /usr/bin/nautilus --browser "\$f" >&/dev/null & )
        fi
    fi
}

fm() {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    [[ \$# -eq 0 ]] && \$ROPERDOT_FILE_MANAGER || \$ROPERDOT_FILE_MANAGER "\$1"
}

if command -v spacefm >/dev/null 2>&1; then
    spacefm () {
        if [[ \$# -eq 0 ]]; then
            ( /usr/bin/spacefm "\$(pwd)" >&/dev/null & )
        else
            local f="\$(fix-path "\$1")"
            if [[ -f "\$f" ]]; then
                fm_archive "\$f"
            elif [[ ! -d "\$f" ]]; then
                echo "Error: directory \$f does not exist"
            else
                ( /usr/bin/spacefm "\$f" >&/dev/null & )
            fi
        fi
    }

    export ROPERDOT_FILE_MANAGER=spacefm
else
    export ROPERDOT_FILE_MANAGER=nautilus
fi
EOT
    create_binary_script_linux peazip
    create_binary_script_linux subl
    create_binary_script_linux opendoc xdg-open
    create_browser_script_linux firefox
    create_binary_script_linux rhythmbox
    create_binary_script_linux totem
    
    create_binary_script_linux code
    create_binary_script_linux notepadqq
    if command -v google-chrome-stable >/dev/null 2>&1; then
        create_browser_script_linux chrome google-chrome-stable
    elif command -v chromium-browser >/dev/null 2>&1; then
        create_browser_script_linux chrome chromium-browser
    fi
    create_binary_script_linux gimp 
    create_binary_script_linux calibre
    create_binary_script_linux vlc
    create_binary_script_linux ghostwriter
    
    default_app=show-file
    create_text_editor_script text-editor-app subl notepadqq
    create_app_script code-editor-app code subl notepadqq
    create_app_script web-browser-app chrome firefox nautilus
    create_app_script archive-editor-app peazip
    create_app_script video-player-app vlc totem
    create_app_script video-editor-app vlc totem
    create_app_script audio-player-app totem
    create_app_script audio-editor-app totem
    create_app_script image-viewer-app opendoc
    create_app_script image-editor-app gimp
    create_app_script pdf-viewer-app opendoc
    create_app_script pdf-editor-app opendoc
    create_app_script ebook-viewer-app ebook-viewer opendoc
    create_app_script word-processor-app opendoc
    create_app_script spreadsheet-app opendoc
    create_app_script presentation-app opendoc
    create_text_editor_script markdown-app ghostwriter
    default_app=list-archive
    create_app_script comic-viewer-app calibre
    if command -v spacefm >/dev/null 2>&1; then
        echo "alias fm=spacefm" >> "$func_file"
    else
        echo "alias fm=nautilus" >> "$func_file"
    fi
elif [[ "$ROPERDOT_OS_ENV" = "kubuntu" ]]; then
    cat << EOT >> "$func_file"
dolphin () {
    if [[ \$# -eq 0 ]]; then
        ( /usr/bin/dolphin "\$(pwd)" >& /dev/null & )
    else
        f="\$(fix-path "\$1")"
        if [[ -e "\$f" ]]; then
            ( /usr/bin/dolphin "\$f" >& /dev/null & )
        else
            echo "Error: directory \$f does not exist"
        fi
    fi
}

fm () {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    [[ \$# -eq 0 ]] && dolphin || dolphin "\$1"
}
EOT
	echo "export ROPERDOT_FILE_MANAGER=dolphin" >> "$func_file"
    create_binary_script_linux kate
    create_binary_script_linux /opt/sublime_text_2 sublime /opt/sublime_text_2/sublime_text
    create_binary_script_linux ark
    create_browser_script_linux chrome chromium-browser
    create_browser_script_linux firefox
    create_binary_script_linux gimp
    create_binary_script_linux vlc
    create_binary_script_linux dragon
    create_binary_script_linux amarok
    create_binary_script_linux mcomix
    create_binary_script_linux opendoc xdg-open
    create_binary_script_linux ghostwriter
    default_app=show-file
    create_text_editor_script text-editor-app sublime kate
    create_app_script code-editor-app sublime kate
    create_app_script web-browser-app chrome firefox
    create_app_script archive-editor-app ark
    create_app_script video-player-app vlc dragon
    create_app_script video-editor-app vlc dragon
    create_app_script audio-player-app amarok
    create_app_script audio-editor-app amarok
    create_app_script image-viewer-app opendoc
    create_app_script image-editor-app gimp
    create_app_script pdf-viewer-app opendoc
    create_app_script pdf-editor-app opendoc
    create_app_script ebook-viewer-app ebook-viewer opendoc
    create_app_script word-processor-app opendoc
    create_app_script spreadsheet-app opendoc
    create_app_script presentation-app opendoc
    create_text_editor_script markdown-app ghostwriter
    default_app=list-archive
    create_app_script comic-viewer-app peruse ark
elif [[ "$ROPERDOT_OS_ENV" = "mint" ]]; then
    cat << EOT >> "$func_file"
nemo () {
    if [[ \$# -eq 0 ]]; then
        ( /usr/bin/nemo "\$(pwd)" >&/dev/null & )
    elif [[ "$1" =~ ^(http|www) ]]; then
        ( /usr/bin/nemo "\$1" >&/dev/null & )
    else
        local f="\$(fix-path "\$1")"
        if [[ -f "\$f" ]]; then
            fm_archive "\$f"
        elif [[ ! -d "\$f" ]]; then
            echo "Error: directory \$f does not exist"
        else
            ( /usr/bin/nemo "\$f" >&/dev/null & )
        fi
    fi
}

fm() {
    if [[ "\$1" == "--help" || "\$1" == "-h" || "\$1" == "-?" ]] ; then
        cat <<EOH
fm: open a directory in a file manager
Usage: fm [target-dir]

If no target directory is specified, the current directory will be used.
EOH
        return
    fi
    [[ \$# = 0 ]] && \$ROPERDOT_FILE_MANAGER || \$ROPERDOT_FILE_MANAGER "\$1"
}

if command -v spacefm >/dev/null 2>&1; then
    spacefm () {
        if [[ \$# -eq 0 ]]; then
            ( /usr/bin/spacefm "\$(pwd)" >&/dev/null & )
        else
            local f="\$(fix-path "\$1")"
            if [[ -f "\$f" ]]; then
                fm_archive "\$f"
            elif [[ ! -d "\$f" ]]; then
                echo "Error: directory \$f does not exist"
            else
                ( /usr/bin/spacefm "\$f" >&/dev/null & )
            fi
        fi
    }

    export ROPERDOT_FILE_MANAGER=spacefm
else
    export ROPERDOT_FILE_MANAGER=nemo
fi
EOT
    create_binary_script_linux peazip
    create_binary_script_linux xed
    create_binary_script_linux opendoc xdg-open
    create_browser_script_linux firefox
    create_binary_script_linux rhythmbox
    create_binary_script_linux xplayer
    
    create_binary_script_linux subl
    create_binary_script_linux atom
    if command -v google-chrome-stable >/dev/null 2>&1; then
        create_browser_script_linux chrome google-chrome-stable
    elif command -v chromium-browser >/dev/null 2>&1; then
        create_browser_script_linux chrome chromium-browser
    fi
    create_binary_script_linux gimp 
    create_binary_script_linux calibre
    create_binary_script_linux vlc
    create_binary_script_linux ghostwriter
    
    default_app=show-file
    create_text_editor_script text-editor-app subl notepadqq xed
    create_app_script code-editor-app code subl notepadqq xed
    create_app_script web-browser-app chrome firefox nemo
    create_app_script archive-editor-app peazip
    create_app_script video-player-app vlc xplayer
    create_app_script video-editor-app vlc xplayer
    create_app_script audio-player-app rhythmbox
    create_app_script audio-editor-app rhythmbox
    create_app_script image-viewer-app opendoc
    create_app_script image-editor-app gimp
    create_app_script pdf-viewer-app opendoc
    create_app_script pdf-editor-app opendoc
    create_app_script ebook-viewer-app ebook-viewer opendoc
    create_app_script word-processor-app opendoc
    create_app_script spreadsheet-app opendoc
    create_app_script presentation-app opendoc
    create_text_editor_script markdown-app ghostwriter
    default_app=list-archive
    create_app_script comic-viewer-app peazip
    if command -v spacefm >/dev/null 2>&1; then
        echo "alias fm=spacefm" >> "$func_file"
    else
        echo "alias fm=nemo" >> "$func_file"
    fi
fi

[[ -n $PROCESSING_BASH ]] && chmod u+x "$ROPERDOT_DIR"/app-bin-bash/*
[[ -n $PROCESSING_ZSH ]] && chmod u+x "$ROPERDOT_DIR"/app-bin-zsh/*
[[ -n $need_to_unset_null_glob ]] && unsetopt NULL_GLOB
