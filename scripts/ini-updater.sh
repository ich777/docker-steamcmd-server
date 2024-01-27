#!/bin/bash

cfgFile=${SERVER_DIR}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini

set_ini_value() {
    local key="${1}"
    local value="${2}"

    # Check if the value contains spaces or special characters
    if [[ "$value" =~ [[:space:]] || "$value" =~ [^a-zA-Z0-9_.-] ]]; then
        # Add quotes around the value
        value="\"$value\""
    fi

    echo "Setting ${key}..."
    sed -i "s|\(${key}=\)[^,]*|\1${value}|g" "${cfgFile}"
    echo "Set to $(grep -Po "${key}=[^,]*" "${cfgFile}")"
}

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <key> <value>"
    exit 1
fi

# Call set_ini_value with command-line arguments
set_ini_value "$1" "$2"

echo "Done!"