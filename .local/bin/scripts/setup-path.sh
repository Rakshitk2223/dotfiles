#!/bin/bash
# Add ~/.local/bin to PATH if not already present
# This ensures that scripts in ~/.local/bin/scripts are accessible

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi