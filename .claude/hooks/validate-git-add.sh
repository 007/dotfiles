#!/bin/bash

# Validate git add commands to prevent using . or -A or directories
# This hook runs before Bash commands that start with "git add"

# Read JSON input from stdin
JSON_INPUT=$(cat)

# Extract the command from the JSON input
# The JSON structure for PreToolUse hooks contains the command in params.command
COMMAND=$(echo "$JSON_INPUT" | jq -r '.params.command // empty')

# If we couldn't extract the command, exit gracefully
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Check if command contains 'git add .' or 'git add -A'
if [[ "$COMMAND" =~ git[[:space:]]+add[[:space:]]+(\.|(-A|--all)) ]]; then
    echo "ERROR: git add . and git add -A are not allowed in this repository."
    echo "Please use explicit file paths as specified in CLAUDE.md:"
    echo "  git add <file1> <file2> ..."
    exit 1
fi

# Extract the git add arguments (everything after 'git add')
if [[ "$COMMAND" =~ git[[:space:]]+add[[:space:]]+(.+)$ ]]; then
    ARGS="${BASH_REMATCH[1]}"
    
    # Split arguments by spaces (simple parsing - doesn't handle quoted paths)
    IFS=' ' read -ra ITEMS <<< "$ARGS"
    
    for item in "${ITEMS[@]}"; do
        # Skip git options that start with -
        if [[ "$item" =~ ^- ]]; then
            continue
        fi
        
        # Check if the item ends with / (directory indicator)
        if [[ "$item" =~ /$ ]]; then
            echo "ERROR: git add with directories is not allowed in this repository."
            echo "Found directory: $item"
            echo "Please use explicit file paths as specified in CLAUDE.md:"
            echo "  git add <file1> <file2> ..."
            exit 1
        fi
        
        # Check if item exists and is a directory
        if [[ -d "$item" ]]; then
            echo "ERROR: git add with directories is not allowed in this repository."
            echo "Found directory: $item"
            echo "Please use explicit file paths as specified in CLAUDE.md:"
            echo "  git add <file1> <file2> ..."
            exit 1
        fi
    done
fi

# Allow the command to proceed
exit 0