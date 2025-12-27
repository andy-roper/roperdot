# Enhanced Shell Commands

Roperdot provides enhanced versions of common shell commands with consistent behavior improvements across `ls`, `cd`, `cp`, `mv`, and `rm`. These enhancements are designed to improve productivity and provide intuitive conveniences while maintaining compatibility with standard command usage.

## Philosophy

These enhancements maintain the original command semantics while adding convenience features that make common operations faster and more intuitive. All enhancements are implemented as shell functions that wrap the actual commands.

### Automatic Bypass

**All enhanced commands automatically revert to standard behavior when:**
- Data is piped to the command
- Output is redirected
- The command is called from another function or script

This ensures that scripts and pipelines continue to work as expected without modification.

## Common Enhancements

### Triple-Dot Path Expansion

All enhanced commands support expanded parent directory navigation:
- `...` expands to `../..`
- `....` expands to `../../..`
- `.....` expands to `../../../..`
- And so on...

**Examples:**
```bash
cd ...              # Go up two levels
ls .../projects     # List contents two levels up
cp file ...         # Copy to two levels up
```

This provides a faster alternative to typing multiple `../` sequences.

## Enhanced `ls` Features

#### 1. Symlink Directory Resolution
When `ls` is given a directory symlink as an argument, it shows the contents of the target directory instead of the symlink itself.

**Standard behavior:**

```bash
ls mylink/    # Shows: mylink/
```

**Enhanced behavior:**

```bash
ls mylink/    # Shows contents of the directory mylink points to
```

#### 2. Smart `-d` Flag for Non-Directories
When arguments include non-directory items (files), the `-d` flag is automatically added to suppress single-level recursion into directories.

**Standard behavior:**
```bash
ls file1 dir1     # Shows: file1  dir1:  <contents of dir1>
```

**Enhanced behavior:**
```bash
ls file1 dir1     # Shows: file1  dir1
```

This prevents unexpected directory expansion when you're just checking if items exist.

## Enhanced `cd` Features

#### 1. Interactive Directory Selection (No Arguments)
When `cd` is called without arguments, instead of going to `$HOME`, it prompts you to select a subdirectory in the current location using fzf.

**Standard behavior:**
```bash
cd              # Changes to $HOME
```

**Enhanced behavior:**
```bash
cd              # Opens gum or fzf to select from subdirectories
```

#### 2. Interactive Directory Selection (`.` Argument)
When `cd .` is called, it prompts you to select a subdirectory.

**Example:**
```bash
cd .            # Opens gum or fzf to select from subdirectories
```

#### 3. Glob Expansion Selection
When using globs that match multiple directories, you'll be prompted to select which one.

**Example:**
```bash
cd proj*        # If multiple matches, opens gum or fzf to select
```

#### 4. Archive Auto-Extraction
You can `cd` to an archive file. It will automatically be extracted to a temporary directory and you'll be taken there.

**Supported formats:**
- `.tar.gz`, `.tgz`
- `.tar.bz2`, `.tbz2`
- `.tar.xz`, `.txz`
- `.zip`
- `.tar`

**Example:**
```bash
cd myarchive.tar.gz    # Extracts to temp dir and changes to it
```

#### 5. DMG Mounting (macOS)
On macOS, you can `cd` to a `.dmg` file. It will automatically be mounted and you'll be taken to the mount directory.

**Example:**
```bash
cd installer.dmg       # Mounts and changes to mount point
```

#### 6. ISO Mounting (Debian, Ubuntu, Mint)
On supported Linux distributions, you can `cd`to an `.iso` file. It will automatically be mounted.

**Example:**

```bash
cd ubuntu.iso          # Mounts and changes to mount point
```

### Requirements

The interactive selection features require `fzf` to be installed.

## Enhanced `cp` Features

#### 1. Hidden File Matching
The `*` glob pattern matches both regular and hidden files (those starting with `.`).

**Standard behavior:**
```bash
cp * backup/         # Doesn't copy hidden files
```

**Enhanced behavior:**
```bash
cp * backup/         # Copies all files including hidden ones
```

#### 2. Current Directory Default Target
If no target directory is specified, files are copied to the current directory.

**Standard behavior:**
```bash
cp /path/to/file     # Error: missing destination
```

**Enhanced behavior:**
```bash
cp /path/to/file     # Copies to current directory
```

## Enhanced `mv` Features

#### 1. Hidden File Matching
The `*` glob pattern matches both regular and hidden files (those starting with `.`).

**Standard behavior:**
```bash
mv * backup/         # Doesn't move hidden files
```

**Enhanced behavior:**
```bash
mv * backup/         # Moves all files including hidden ones
```

#### 2. Current Directory Default Target
If no target directory is specified, files are moved to the current directory.

**Standard behavior:**
```bash
mv /path/to/file     # Error: missing destination
```

**Enhanced behavior:**
```bash
mv /path/to/file     # Moves to current directory
```

## Enhanced `rm` Features

#### 1. Hidden File Matching
The `*` glob pattern matches both regular and hidden files (those starting with `.`).

**Standard behavior:**
```bash
rm *                 # Doesn't remove hidden files
```

**Enhanced behavior:**
```bash
rm *                 # Removes all files including hidden ones
```

**⚠️ Warning:** Be especially careful with `rm *` in the enhanced version, as it will remove hidden files too.

## Configuration

All enhanced commands can be individually enabled or disabled during installation, or by setting the corresponding environment variables in your shell configuration:

```bash
export ROPERDOT_CUSTOM_LS=true
export ROPERDOT_CUSTOM_CD=true
export ROPERDOT_CUSTOM_CP=true
export ROPERDOT_CUSTOM_MV=true
export ROPERDOT_CUSTOM_RM=true
```

Set any of these variables to `false` in ~/roperdot-loader to disable that enhancement.

### Reverting to Standard Behavior

If you need standard command behavior temporarily:

```bash
command ls ...       # Bypass function wrapper
/bin/ls ...          # Call command directly
```

## Tips and Best Practices

### Interactive `cd`

The no-argument `cd` behavior is helpful for exploring:

```bash
cd              # Browse subdirectories
cd .            # Same as above
cd proj*        # Select from matching directories
```

### Hidden File Operations

Remember that `*` includes hidden files with enhanced `cp`, `mv`, and `rm`:

```bash
# These will include hidden files:
cp * backup/
mv * archive/
rm *            # ⚠️ Be careful!

# To exclude hidden files, use explicit patterns:
cp [^.]* backup/
```
