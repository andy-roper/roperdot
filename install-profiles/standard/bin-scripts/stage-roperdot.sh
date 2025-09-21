#
# Description: Commits and pushes the dotfiles while prompting for a version number and commit message
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

# Get current version
if [[ -f "$ROPERDOT_DIR/VERSION" ]]; then
    CURRENT_VERSION=$(cat "$ROPERDOT_DIR/VERSION" 2>/dev/null | tr -d '\n\r ')
    echo "Current version: $CURRENT_VERSION"
else
    echo "Error: VERSION file not found at $ROPERDOT_DIR/VERSION. Please ensure the dotfiles are properly installed."
    exit 1
fi

echo -n "Enter new version: "
read NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
    echo "Version cannot be empty"
    exit 1
fi

echo -n "Enter commit message: "
read COMMIT_MESSAGE

if [[ -z "$COMMIT_MESSAGE" ]]; then
    echo "Commit message cannot be empty"
    exit 1
fi

echo "$NEW_VERSION" > "$ROPERDOT_DIR/VERSION"
git add "$ROPERDOT_DIR/VERSION"
git add .
git commit -m "v$NEW_VERSION: $COMMIT_MESSAGE"
git push

echo "Released v$NEW_VERSION"