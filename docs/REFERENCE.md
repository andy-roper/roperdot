# Reference

## Advanced Configuration

### Updating Scripts for Apps on Your System

This is typically done when you need to add handling for additional applications not accounted for in the distributed copy of update-app-binaries. update-app-binaries creates scripts in app-bin-bash and app-bin-zsh based on the applications that are installed on your system.

Make the necessary changes for your applications in roperdot/bin-bash/update-app-binaries, source source-scripts/copy-scripts to update the scripts in bin-bash and bin-zsh, and then execute update-app-binaries. Alternatively, you can directly modify update-app-binaries for your shell (e.g. in bin-zsh) and then execute it.

update-app-binaries will update the scripts in app-bin-bash and app-bin-zsh that are used to open files in GUI viewers/editors.

To support file extensions that currently don't have an associated application in zsh, you'll also want to update roperdot/.zsh-suffix-aliases.

### Application Installation JSON Structure

Each OS has (if applicable) a shell apps JSON file and a GUI apps JSON file that defines how applications are installed. These files are located in install-profiles/<profile-name> (install-profiles/standard for the included install profile).

Here's an explanation of the properties of the installation definitions in the JSON files:

| Property            | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `app`               | Name of the app (referenced during the install)              |
| `bundle_name`       | (MacOS) Bundle name, i.e. the directory in Applications (if different than app) |
| `package`           | Package name used by the package manager                     |
| `package_manager`   | Package manager used to install the application, e.g. brew, apt, choco, etc. |
| `list_prerequisite` | (Optional) Package manager required to be present in order to include the app in the install list |
| `binary`            | (Used for shell apps) Binary to check for to determine if the package is already installed |
| `presence_command`  | (Optional) Command to execute to check if the package is installed (mainly used for libraries) |
| `install_script`    | (Optional) Script to use to install the application instead of direct installation with the package manager |
| `install_command`   | (Optional) Command to use to install the application         |
| `groups`            | (Optional) Array of groups for which to install the application; if not present, the application will be installed regardless of the group(s) designated when installing |
| `exclusionGroups`   | (Optional) Array of groups for which the application should **not** be installed |
| `disabledByDefault` | (Optional) Exclude the application from the ones to install **unless** it's in a group and that group is referenced when installing |
| `sudo_not_required` | (Optional) Don't require sudo to install the application     |

If neither install_script nor install_command are defined, the package_manager will be used to install the application.

*More coming soon*

## Third-Party Applications

roperdot makes use of a number of excellent third party terminal applications.

- **`ag`** - [The Silver Searcher](https://github.com/ggreer/the_silver_searcher) - Fast code search
- **[`diff-so-fancy`](https://github.com/so-fancy/diff-so-fancy)** - Formatter and colorizer for git diff
- **[`dos2unix`](https://dos2unix.sourceforge.io/)** - Convert line endings between formats
- **[`entr`](https://eradman.com/entrproject/)** - Run commands when files change
- **[`fd`](https://github.com/sharkdp/fd)** - Modern, fast alternative to find command
- **[`fzf`](https://github.com/junegunn/fzf)** - Fuzzy finder integration throughout the system
- **[`gawk`](https://www.gnu.org/software/gawk/)** - GNU awk for advanced text processing
- **[`gh`](https://cli.github.com/)** - GitHub CLI
- **`grc`** - [Generic colouriser](https://github.com/garabik/grc) for command output
- **[`htop`](https://htop.dev/)** - Interactive process monitor
- **[`hub`](https://hub.github.com/)** - Extension for command-line git
- **[`jq`](https://jqlang.org/)** - JSON processor and formatter
- **[`keychain`](https://www.funtoo.org/Keychain)** - SSH key management
- **`mc`** - [Midnight Commander](http://midnight-commander.org) - Shell-based file manager
- **[`mtr`](https://github.com/traviscross/mtr)** - Network diagnostic tool
- **[`ncdu`](https://dev.yorhel.nl/ncdu)** - NCurses disk usage analyzer
- **[`p7zip`](https://p7zip.sourceforge.net/)** - Archive manager with support for 7z and many other formats
- **`pygmentize`** - [Pygments](https://pygments.org/) - Syntax highlighter
- **[`shellcheck`](https://www.shellcheck.net/)** - Shell script linter
- **[`speedtest-cli`](https://github.com/sivel/speedtest-cli)** - Test internet connection speed
- **[`ssh-copy-id`](https://www.ssh.com/academy/ssh/copy-id)** - Use locally available keys to authorize logins on remote machines
- **[`starship`](https://starship.rs/)** - Modern cross-shell prompt
- **[`testssl`](https://testssl.sh/)** - TLS/SSL security testing
- **[`tree`](https://gitlab.com/OldManProgrammer/unix-tree)** - Directory structure visualization
- **[`z`](https://github.com/rupa/z)** - Jump to frequently used directories based on usage patterns

## History

I was exposed to Unix and shell scripting when I attended university. I already had a lot of experience with DOS commands and batch files by then, so it came fairly naturally.

Soon after graduating I discovered [4DOS](https://en.wikipedia.org/wiki/4DOS), a greatly enhanced command interpreter for MS-DOS and Windows. Several years later, JP Software released [Take Command](https://jpsoft.com/products/take-command.html), a Windows console with the same features and more. Being primarily a Windows user, that was my shell of choice for quite a few years.

Around 2017, I began working on a project for a client that required frequently remoting into their RHEL server. I adapted many of my Take Command batch files to shell aliases, functions and scripts.

Then I found out about the concept of dotfiles. I set up Cygwin on my Windows machine and ported my scripts etc. there and converted them to work on Windows. I updated my dotfiles to use the [Chocolatey](https://chocolatey.org/) package manager to install applications. Then I did the same for my company MacBook and used [Homebrew](https://brew.sh/) to install applications on that platform.

When WSL became viable for me on Windows with the advent of WSL 2, I switched to using Ubuntu on that platform instead of Cygwin. I also built a couple of Linux machines at home and set up my dotfiles on them as well.

In 2025, I updated my dotfiles to incorporate the concept of app "groups" and to support installation on macOS without admin access for compatibility with an upcoming client project.

## To Do/Future Plans

- Test and retool Ubuntu/Mint/WSL (Ubuntu) installs if necessary after the recent MacOS-centric retooling
- Update other OSes’ shell-apps JSON files to take same approach used for MacOS for Python apps/libraries
  - Remove html5print and xml2json
  - Add cssbeautifier, beautifulsoup4 and xmltodict
- Update other OSes' shell apps
  - Add awscli, ffmpeg, gifsicle (if available)
- Update other OSes’ GUI apps
  - Add Brave browser; disable WebStorm
- Finish implementing change scheme
- Formalize support for alternate/multiple installation profiles
- Update VS Code configuration when switching scheme (colors only)
- Build install for Oracle SQL Developer
  - https://www.oracle.com/database/sqldeveloper/technologies/download/
  - Will need to check for Java to determine which file to download
  - May be available via choco or apt-get
- Institute use of print_important_message during after after install
  - Use for things like running update-vscode-settings for VS Code, importing iTerm2 profile, etc.