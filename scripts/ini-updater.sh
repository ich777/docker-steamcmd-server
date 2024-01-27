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
    echo "Set to $(get_ini_value "$key")"
}

get_ini_value() {
    local key="${1}"

    # Output only the value of the key
    grep -Po "(?<=${key}=)[^,]*" "${cfgFile}"
}

# Check if the number of arguments is valid for both set and get options
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "Usage:"
    echo "To set a value: $0 set <key> <value>"
    echo "To get a value: $0 get <key>"
    exit 1
fi

# Check the option provided (set or get)
option="$1"
shift

case "$option" in
    "set")
        # Check if two arguments are provided for set option
        if [ "$#" -ne 2 ]; then
            echo "Usage for set option: $0 set <key> <value>"
            exit 1
        fi
        set_ini_value "$@"
        ;;
    "get")
        # Check if one argument is provided for get option
        if [ "$#" -ne 1 ]; then
            echo "Usage for get option: $0 get <key>"
            exit 1
        fi
        get_ini_value "$1"
        ;;
    *)
        echo "Invalid option: $option"
        echo "Usage:"
        echo "To set a value: $0 set <key> <value>"
        echo "To get a value: $0 get <key>"
        exit 1
        ;;
esac
