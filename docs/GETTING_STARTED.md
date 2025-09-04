# Getting Started

## Installation Guide

The applications that will be installed are controlled by the OS-specific JSON files in roperdot/install-profiles/standard. If an application requires a more advanced installation, it will have an install script in roperdot/install-profiles/standard/installs.

Applications can have groups or exclusionGroups properties that can be used to control which applications are installed on a machine.

Command line options are used with install.sh to control or automate the installation process.

```
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
```

Example:

```
./install.sh --recommended --all-shell --all-gui --groups work
```

By default, running install.sh will perform an interactive installation. The `--recommended` option will cause questions to use the default answer instead.

On Windows, you should install [Chocolatey](https://chocolatey.org) first if you plan to install GUI applications with roperdot.

Installation can be done on macOS even as a non-admin user. Homebrew will be installed in ~/homebrew and applications in ~/Applications.

After installing, either source ~/roperdot-loader or restart your shell.

On MacOS, you'll want to import the roperdot/config/apps/macos-terminal/roperdot-hybrid.terminal profile into Terminal, and the roperdot/config/apps/iTerm2/roperdot-hybrid.json profile into iTerm2.

The installation will create helpful symlinks to your user folders in $HOME, e.g. on Windows to Desktop, Documents, Downloads, Music, Pictures and Videos.

An installation which encounters a problem can usually be resumed using the `--resume` option.

## Configuration

### Configuration Variables

Variables are defined in ~/roperdot-loader that control how the dotfiles function. This file will be populated by the install but can be modified after.

```bash
export ROPERDOT_LOADED=true
export ROPERDOT_SUPPRESS_INFO=true                   # suppress post-install info
export ROPERDOT_DOT_IN_PATH=true                     # include cwd in PATH
export ROPERDOT_PROFILES=standard                    # profiles in use
export ROPERDOT_CUSTOM_CD=true                       # enhanced cd behavior in shell
export ROPERDOT_CUSTOM_CP=true                       # enhanced cp behavior in shell
export ROPERDOT_CUSTOM_LS=true                       # enhanced ls behavior in shell
export ROPERDOT_CUSTOM_MV=true                       # enhanced mv behavior in shell
export ROPERDOT_CUSTOM_RM=true                       # enhanced rm behavior in shell
export ROPERDOT_COLOR_SCHEME=default                 # color scheme to use (or default)
export ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME=hybrid   # default color scheme
export ROPERDOT_COMMON_COLOR_SCHEME=default          # color scheme for pygmentize
export ROPERDOT_OVERRIDE_PROMPT=true                 # override bash prompt
export ROPERDOT_PROMPT_LINES=1                       # number of lines in bash prompt
export ROPERDOT_SHOW_GIT_PROMPT_INFO=true            # show git info in bash prompt
export EDITOR=vi                                     # default shell editor
export ROPERDOT_ARC_TYPE=zip                         # default archive type
export ROPERDOT_HISTORY_BY_SESSION=true              # store history by session
export ROPERDOT_MC_SCHEME=dark                       # Midnight Commander scheme
export ROPERDOT_USE_VIM_SETTINGS=true                # use Vim settings
export ROPERDOT_VI_BACKGROUND=dark                   # vi background
export ROPERDOT_VI_COLOR_SCHEME=hybrid               # vi color scheme
```

### Adding Custom Commands/Values

roperdot will source `~/.extra` if it exists, allowing you to define custom functions, aliases and/or environment variables.
