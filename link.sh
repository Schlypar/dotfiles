#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if links.txt exists
LINKS_FILE="$SCRIPT_DIR/links.txt"
if [[ ! -f "$LINKS_FILE" ]]; then
    echo "Error: links.txt not found in script directory!" >&2
    exit 1
fi

# Function to create symlink
create_symlink() {
    local target_dir="$1"
    local source_file="$2"
    local link_name="$3"
    
    # Expand variables in target directory (like $HOME)
    target_dir=$(eval echo "$target_dir")
    
    # Get absolute path to source file
    local source_path="$SCRIPT_DIR/$source_file"
    
    # Determine link name if not provided
    if [[ -z "$link_name" ]]; then
        link_name=$(basename "$source_file")
    fi
    
    local link_path="$target_dir/$link_name"
    
    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
        echo "Warning: Source '$source_path' does not exist. Skipping." >&2
        return 1
    fi
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        echo "Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Check if link already exists
    if [[ -e "$link_path" ]] || [[ -L "$link_path" ]]; then
        echo "Warning: '$link_path' already exists. Skipping." >&2
        return 1
    fi
    
    # Create the symlink
    if ln -s "$source_path" "$link_path"; then
        echo "Created symlink: $link_path -> $source_path"
    else
        echo "Error: Failed to create symlink '$link_path'" >&2
        return 1
    fi
}

# Read links.txt line by line
while IFS='|' read -r target source name || [[ -n "$target" ]]; do
    # Skip empty lines and lines starting with #
    if [[ -z "$target" ]] || [[ "$target" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Trim whitespace from all fields
    target=$(echo "$target" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    source=$(echo "$source" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    name=$(echo "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    
    create_symlink "$target" "$source" "$name"
done < "$LINKS_FILE"

echo "Symlink creation completed!"
