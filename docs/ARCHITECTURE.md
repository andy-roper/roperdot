# Architecture

## Directory Structure

```bash
roperdot/
├── Core Configuration:
├── .aliases                    # Cross-platform aliases
├── .bash_prompt                # bash prompt
├── .functions                  # Cross-platform functions
├── .inputrc                    # Readline key bindings
├── .roperdot-os-*              # OS-specific settings
├── .zsh-suffix-aliases         # Associates file extensions with commands in zsh
├── define-colors               # Defines bash prompt colors
├── roperdot-bootstrap          # Core bootstrap script loaded by shells
├── 
├── Scripts and Binaries:
├── app-bin-bash/               # Application scripts for bash (created during install)
├── app-bin-zsh/                # Application scripts for zsh (created during install)
├── apps-and-packages/          # Included/modified supporting applications
├── bin/                        # Portable scripts (Perl, Python, shell)
├── bin-bash/                   # Bash-specific scripts (created during install)
├── bin-zsh/                    # Zsh-specific scripts (created during install)
├── examples/                   # Example scripts
├── extra-bin/                  # Additional utilities
├── os-bin/                     # OS-specific scripts
├── source-scripts/             # Utility scripts (sourced in other scripts)
├── 
├── Installation System:
├── install.sh                  # Main installation script
├── install-apps                # Application installer script
├── install-profiles/           # Installation profiles
├── ├── standard/               # Default installation profile
├── │   ├── *-shell-apps.json   # Shell applications by OS
├── │   ├── *-gui-apps.json     # GUI applications by OS
├── │   ├── app-scripts/        # Scripts for driving applications
├── │   ├── bin-scripts/        # Scripts to copy into bin-bash and bin-zsh
├── │   ├── config-files/       # Application configuration files
├── │   └── installs/           # Installation scripts for apps
├── 
├── Configuration:
├── config/
├── ├── apps/                   # App configuration files
├── ├── color-schemes/          # Unified color schemes
├── └── help-definitions/       # Help text for aliases, functions and binaries
```

### Files in $HOME

```bash
.bash_history            # bash command history
.bashrc                  # bash configuration and initialization
.fdignore                # files and directories for fd to ignore when searching
.fzf.bash                # fzf fuzzy finder integration for bash
.fzf.zsh                 # fzf fuzzy finder integration for zsh
.lesshst                 # Less pager command history
roperdot-help.txt        # help text for roperdot commands; searched with help command
roperdot-info.txt        # post-install info; disable display at shell start by removing 
                         # the file or setting ROPERDOT_SUPPRESS_INFO env var to true
roperdot-install.log     # roperdot installation log
roperdot-loader          # defines ROPERDOT env vars and loads roperdot-bootstrap
.roperdot-os-functions   # OS-specific functions; created during installation
.viminfo                 # Vim editor session info and history
.vimrc                   # Vim editor configuration
.z.*                     # Z jump-around command history database
.zshrc                   # zsh configuration and initialiation
```

## Starship Prompt

As I migrated from [powerlevel10k](https://github.com/romkatv/powerlevel10k) to [Starship](https://starship.rs/), I discovered several of the features I used previously weren't directly supported in the Starship prompt.

I wrote functions that do that work instead by setting environment variables that are used in the prompt. See set_git_info, set_status_info and set_dir_stack_info in roperdot-bootstrap.

## Enhanced Shell Commands

I've enhanced the behavior of the ls, cd, cp, mv and rm commands when they're run in a shell but I wanted to avoid impacting script execution. I did this by using aliases that override the behavior in the shell by calling (for instance) __ls, which is a function defined in .functions.

See **[ENHANCED_SHELL_COMMANDS](./ENHANCED_SHELL_COMMANDS.md)**.

## Color Schemes

I've made an effort to use consistent/similar color schemes throughout my dotfiles, including:

- Defining color environment variables to be commonly used by applications, e.g. COLOR_BLACK (`\e[30m`), COLOR_BG_BLUE (`\e[44m`), COLOR_BRWHITE (`\e[1;37m`), COLOR_CYAN_CODE (`36`), COLOR_RED_RGB (`922f33`), etc.
- Colorizing the bash or zsh prompt (Starship) making use of color environment variables
- Colorizing `ls` using dircolors and the .dircolors file for the color scheme in use
- Colorizing `less` output based on the file extension using [Pygments](https://pygments.org/docs/cmdline/) via the LESSOPEN environment variable and the lessfilter script
- Colorizing `diff` output by using `ydiff`
- Colorizing man pages with a wrapper function that sets LESS_TERMCAP variables
- Colorizing various commands' output (`curl`, `du`, `head`, `ifconfig`, `mount`, `netstat`, `tail`, etc.) using [generic colouriser](https://github.com/garabik/grc). I created customized generic colouriser config files that match the colors for each color scheme. The default scheme's config files are copied during installation to ~/.grc.
- Colorizing git with .gitcolors, git diff and git show commands using [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy), and by using the git-blame-colored script
- Colorizing and theming vim using color schemes (based on the ROPERDOT_VI_COLOR_SCHEME environment variable) and plugins like vim-airline, vim-airline-themes, etc.

Much of this is controlled by roperdot/source-scripts/initialize-colors which utilizes color schemes defined in roperdot/config/color-schemes.

## gum and fzf Integration

[gum](https://github.com/charmbracelet/gum) and [fzf](https://github.com/junegunn/fzf) are used by multiple commands (cd, cdd, cdj, cds, e, gm, gi, gli, gt, je, nav, pushd, up and v) for selection of files, directories and options. The fzf plugin is also used in vim.

Additionally, fzf is used in zsh when interactively selecting commands from history using Ctrl+R.

## Adding New Scripts

Scripts should be created in the installation profile (usually install-profile/standard) in the bin-scripts directory. The scripts should be created without a shebang line and should be compatible with both bash and zsh.

You'll need to source roperdot/source/copy-scripts afterwards for the scripts to be copied to bin-bash and bin-zsh.

## Adding New GUI App Scripts

Support for the new script must be added to install-profiles/standard/bin-scripts/update-app-binaries.sh.

For each operating system which supports the application, a call to create the script for the application must be added. Examples for MacOS:

```bash
create_binary_script_mac itunes "open -a iTunes"

create_browser_script_mac "$(app-path 'Google Chrome')" chrome "open -a \"Google Chrome\""
```

The application name used in the create binary script call must be added to a create_app_script call to assign that application to an application type. default_app is set before the calls to create_app_script to designate the default application to use if no matching app script is present for the application type. Multiple applications can be specified so that if one is not present, usage will fall back to another application. Example for MacOS:

```bash
create_app_script code-editor-app code sublime textwrangler textedit
```

After making these updates, you'll need to source roperdot/source/refresh-roperdot. That will update the update-app-binaries script in bin-bash and bin-zsh and to call the script to update the scripts in app-bin-bash and app-bin-zsh.