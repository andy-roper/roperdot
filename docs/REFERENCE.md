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
| `app_dir`           | (Optional) Directory to check for within the applications directory to determine if the application is installed; used with `install_script` for GUI applications |
| `install_command`   | (Optional) Command to use to install the application         |
| `groups`            | (Optional) Array of groups for which to install the application; if not present, the application will be installed regardless of the group(s) designated when installing |
| `exclusionGroups`   | (Optional) Array of groups for which the application should **not** be installed |
| `disabledByDefault` | (Optional) Exclude the application from the ones to install **unless** it's in a group and that group is referenced when installing |
| `sudo_not_required` | (Optional) Don't require sudo to install the application     |
| `always_prompt`     | (Optional) If true, always prompt the user to install the application instead of checking if it's installed. This is needed for applications which are unpacked from zips, such as Oracle SQL Developer for Windows. |

If neither install_script nor install_command are defined, the package_manager will be used to install the application.

*More coming soon*

## Third-Party Applications

roperdot makes use of a number of excellent third party terminal applications.

### Compression and Archives

- **[`p7zip`](https://p7zip.sourceforge.net/)** - Archive manager with support for 7z and many other formats
- **[`rar`](https://www.rarlab.com/)** - RAR archive support
- **[`zopfli`](https://github.com/google/zopfli)** - Advanced compression library

### Development Environments and Managers

- **[`Java`](https://openjdk.org/)** - Java runtime and development
- **[`jENV`](https://www.jenv.be/)** - Java environment manager
- **[`Node.js`](https://nodejs.org/)** - JavaScript runtime
- **[`nvm`](https://github.com/nvm-sh/nvm)** - Node version manager
- **[`pipx`](https://pipx.pypa.io/stable/)** - Python application isolation
- **[`Python setuptools`](https://setuptools.pypa.io/)** - Python package tools
- **`sdk`** - [SDKMAN](https://sdkman.io): SDK manager for installing and managing parallel versions of JVM tools
- **[`wheel`](https://wheel.readthedocs.io/)** - Python package distribution

### Development Tools

- **[`gh`](https://cli.github.com/)** - GitHub CLI
- **[`git`](https://git-scm.com/)** - Version control system
- **[`git-lfs`](https://git-lfs.github.com/)** - Git large file storage
- **[`gradle`](https://gradle.org)** - Build automation tool for Java and other JVM languages
- **[`jq`](https://jqlang.org/)** - JSON processor and formatter
- **`mvn`** - [Maven](https://maven.apache.org): build automation and dependency management tool for Java projects
- **[`Neovim`](https://neovim.io/)** - Modern Vim editor
- **[`oc`](https://openshift.com)** - CLI for Red Hat OpenShift container platform and Kubernetes
- **[`shellcheck`](https://www.shellcheck.net/)** - Shell script linter
- **[`sqlplus`](https://www.oracle.com/database/technologies/instant-client.html)** - Oracle SQL*Plus CLI for Oracle databases
- **`tkn`** - [Tekton](https://tekton.dev) CLI for managing CI/CD pipelines on Kubernetes
- [**`uuid-runtime`**](https://packages.debian.org/sid/uuid-runtime) - Library for generating and parsing UUIDs
- **[`Vim/vimdiff`](https://www.vim.org/)** - Text editor and diff tool
- **[`xmllint`](http://xmlsoft.org/xmllint.html)** - XML parsing and validation

### Multimedia and Graphics

- **[`FFmpeg`](https://ffmpeg.org/)** - Video/audio processing
- **[`gifsicle`](https://www.lcdf.org/gifsicle/)** - GIF manipulation
- **[`ImageMagick`](https://imagemagick.org/)** - Image editing suite
- **[`pngpaste`](https://github.com/jcsalterego/pngpaste)** - Pastes PNG into files on MacOS
- **[`tesseract`](https://github.com/tesseract-ocr/tesseract)** - OCR engine library

### Network and Security

- **[`AWS CLI`](https://aws.amazon.com/cli/)** - Amazon Web Services CLI
- **[`keychain`](https://www.funtoo.org/Keychain)** - SSH key management
- **[`lynx`](https://lynx.browser.org/)** - Text-based web browser
- **[`mtr`](https://github.com/traviscross/mtr)** - Network diagnostic tool
- **[`OpenVPN`](https://openvpn.net/)** - VPN client
- **[`speedtest-cli`](https://github.com/sivel/speedtest-cli)** - Test internet connection speed
- **[`ssh-copy-id`](https://www.ssh.com/academy/ssh/copy-id)** - Use locally available keys to authorize logins on remote machines
- **[`testssl`](https://testssl.sh/)** - TLS/SSL security testing
- **[`tnftp/tnftpd`](https://ftp.netbsd.org/pub/NetBSD/misc/tnftp/)** - FTP client/server

### Package Managers and Tools

- **[`alien`](https://joeyh.name/code/alien/)** - Convert or install RPM packages on Debian-based systems
- **[`apt-file`](https://packages.debian.org/stable/apt-file)** - Debian package content search
- **[`Linuxbrew`](https://docs.brew.sh/Homebrew-on-Linux)** - Homebrew for Linux

### Python Libraries

- **[`BeautifulSoup4`](https://www.crummy.com/software/BeautifulSoup/)** - Python library for HTML/XML parsing
- **[`colored`](https://pypi.org/project/colored/)** - Python library for adding color and formatting to terminal output
- **[`cryptography`](https://cryptography.io/)** - Python cryptography module
- **[`jsoncomment`](https://pypi.org/project/jsoncomment/)** - Python JSON parser wrapper for parsing files with nonstandard formatting
- **[`playwright`](https://playwright.dev/python/)** - Python library for browser automation
- **[`py-rolldice`](https://pypi.org/project/py-rolldice/)** - Python library for evaluating dice notation
- **[`pypdf`](https://pypi.org/project/pypdf/)** - Python library for PDF manipulation
- **[`sqlparse`](https://pypi.org/project/sqlparse/)** - Python library for parsing and formatting SQL
- **[`tabulate`](https://pypi.org/project/tabulate/)** - Python library for pretty-printing tabular data
- **[`xmltodict`](https://pypi.org/project/xmltodict/)** - Python library for converting XML to dictionary

### Python-Based Tools

- **[`cssbeautifier`](https://pypi.org/project/cssbeautifier/)** - Python script for beautifying CSS
- **[`jsbeautifier`](https://pypi.org/project/jsbeautifier/)** - Python script for formatting JavaScript/CSS/HTML
- **[`WhisperX`](https://github.com/m-bain/whisperX)** - Speech transcription package with word-level timestamps and speaker diarization

### Shell Customization

- **[`diff-so-fancy`](https://github.com/so-fancy/diff-so-fancy)** - Formatter and colorizer for git diff
- **`grc`** - [Generic colouriser](https://github.com/garabik/grc) for command output
- **`pygmentize`** - [Pygments](https://pygments.org/) - Syntax highlighter
- **[`starship`](https://starship.rs/)** - Modern cross-shell prompt
- **[`ydiff`](https://github.com/ymattw/ydiff)** - Diff colorization tool

### Shell Enhancements

- **`mc`** - [Midnight Commander](http://midnight-commander.org/) - Shell-based file manager
- **[`pv`](https://www.ivarch.com/programs/pv.shtml)** - Pipeline progress monitor
- **[`tree`](https://gitlab.com/OldManProgrammer/unix-tree)** - Directory structure visualization
- **[`xclip`](https://github.com/astrand/xclip)** - X11 clipboard interface
- **[`z`](https://github.com/rupa/z)** - Jump to frequently used directories based on usage patterns

### System Monitoring and Utilities

- **[`entr`](https://eradman.com/entrproject/)** - Run commands when files change
- **[`htop`](https://htop.dev/)** - Interactive process monitor
- **[`ncdu`](https://dev.yorhel.nl/ncdu)** - NCurses disk usage analyzer
- **[`terminal-notifier`](https://github.com/julienXX/terminal-notifier)** - macOS notifications

### Text and File Processing

- **`ag`** - [The Silver Searcher](https://github.com/ggreer/the_silver_searcher) - Fast code search
- **[`dos2unix`](https://dos2unix.sourceforge.io/)** - Convert line endings between formats
- **[`fd`](https://github.com/sharkdp/fd)** - Modern, fast alternative to find command
- **[`fzf`](https://github.com/junegunn/fzf)** - Fuzzy finder integration throughout the system
- **[`gawk`](https://www.gnu.org/software/gawk/)** - GNU awk for advanced text processing
- **[`VBinDiff`](https://www.cjmweb.net/vbindiff/)** - Binary file comparison

### Frequently Already Installed

- **[`curl`](https://curl.se/)** - Tool for transferring data from/to servers
- **[`net-tools`](https://sourceforge.net/projects/net-tools/)** - Networking toolkit (ifconfig, netstat, etc.)
- **[`Python 3`](https://www.python.org/)** - Python programming language
- **[`Python 3 pip`](https://pip.pypa.io/)** - Python package installer
- **[`Ruby`](https://www.ruby-lang.org/)** - Ruby programming language
- **[`telnet`](https://www.telnet.org/)** - Telnet client
- **[`telnetd`](https://www.telnet.org/)** - Telnet server
- **[`unzip`](http://infozip.sourceforge.net/UnZip.html)** - Archive extraction utility
- **[`wget`](https://www.gnu.org/software/wget/)** - File downloader

## History

I was exposed to Unix and shell scripting when I attended university. I already had a lot of experience with DOS commands and batch files by then, so it came fairly naturally.

Soon after graduating I discovered [4DOS](https://en.wikipedia.org/wiki/4DOS), a greatly enhanced command interpreter for MS-DOS and Windows. Several years later, JP Software released [Take Command](https://jpsoft.com/products/take-command.html), a Windows console with the same features and more. Being primarily a Windows user, that was my shell of choice for quite a few years.

Around 2017, I began working on a project for a client that required frequently remoting into their RHEL server. I adapted many of my Take Command batch files to shell aliases, functions and scripts.

Then I found out about the concept of dotfiles. I set up Cygwin on my Windows machine and ported my scripts etc. there and converted them to work on Windows. I updated my dotfiles to use the [Chocolatey](https://chocolatey.org/) package manager to install applications. Then I did the same for my company MacBook and used [Homebrew](https://brew.sh/) to install applications on that platform.

When WSL became viable for me on Windows with the advent of WSL 2, I switched to using Ubuntu on that platform instead of Cygwin. I also built a couple of Linux machines at home and set up my dotfiles on them as well.

In 2025, I updated my dotfiles to incorporate the concept of app "groups" to provide for installing apps only for specified groups or to exclude an app for a specified group.

## To Do/Future Plans

- Update install-claude to add configuration

- Update install-apps to support installation of a single app or list of apps outside of installing roperdot

  - Sample invocation: install-apps gui "Some App"

  - The app name will be looked up in the appropriate JSON based on the app property

  - Provide for selection of apps to install using fzf if gui/shell is passed as the first argument but no second argument is passed

- Revisit issue where the prompt hangs if there's no internet connection
  This is due to `git rev-parse --git-dir` causing a hang likely because either Git is trying to contact credential helpers (the `/home/linuxbrew/.linuxbrew/bin/gh` helper) or there's a WSL-specific filesystem/network interaction issue

- Consider adding VMware Fusion (Mac) or VMware Workstation Pro (others) to installs

- Consider adding additional AWS apps to installs

  - aws-sam-cli (awssamcli in Chocolatey), session-manager-plugin, terraform

- Consider adding a space visualizer install to Mint and Ubuntu GUI apps, either QDirStat or Baobab

- Figure out how to eliminate warning from mergepdfs and pdfcount scripts:
  WARNING: (<class 'ply.yacc.VersionError'>, VersionError('yacc table file version is out of date'), <traceback object at 0x7fbbd69a0b00>)

- Add comment to install scripts that rely on a hardcoded version number/URL that I can grep on like:

  \# Hardcoded version reference: SQL Developer v23.1.1.345.2114, last updated on 9/23/2025

  - Create a script named “list-hardcoded-installs” to do a recursive grep to list them

- Implement conditioning of VS Code extensions based on group in install-vscode

- Finish implementing change scheme

- Test upgrading to a later Python version (e.g. 3.13)

  - Need to ask user about switching to newer version instead of arbitrarily doing so
  - Will need to reinstall Python packages for scripts in bin to use it properly
  - Will need to update installs to add install/upgrade to latest python version
  - `brew install python` or `brew upgrade python`

- Revisit installing non-standard installation

  - Need to support a different/second install profile
  - Need to support installing a second profile after installing standard

- Consider trying [scoop](https://github.com/ScoopInstaller/Scoop) to install GUI apps for non-admin Windows users

- Revisit issue with being repeatedly asked for the sudo password when installing WSL/Ubuntu shell apps (apt-file, git-lfs, fd-find, jq, shellcheck, speedtest-cli)

  - The sudo keepalive approach in install_shell_apps didn't work

- Integrate eza, a modern ls alternative: https://github.com/eza-community/eza

- Integrate bat, a modern cat alternative: https://github.com/sharkdp/bat

- Other apps to evaluate and possibly integrate:

  - [btop](https://github.com/aristocratos/btop): resource monitor
  - [choose](https://github.com/theryangeary/choose): human-friendly cut/awk alternative
  - [delta](https://github.com/dandavison/delta): syntax-highlighting pager for git, diff, grep and blame
  - [duf](https://github.com/muesli/duf): disk usage/free utility
  - [dust](https://github.com/bootandy/dust): more intuitive version of du
  - [httpie](https://github.com/httpie/cli): user-friendly HTTP client
  - [procs](https://github.com/dalance/procs): modern ps alternative

- Update VS Code configuration when switching scheme (colors only)

- Institute use of print_important_message during after after install

  - Use while installing to print important messages and to accumulate them to re-print them at the end of the install
  - Use for things like running update-vscode-settings for VS Code, importing iTerm2 profile, etc.