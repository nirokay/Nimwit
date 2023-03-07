#!/bin/bash

# Local variables:
PID=-1

# Default config:
CONFIGFILE_path="config.sh"
CONFIGFILE_default='#!/bin/bash

# Restart interval:
export EXEC_delay=$(( 60 * 60 * 6 )) # default: 60 * 60 * 6
'

function build() {
    git pull
    make build
}

function loadConfigFile() {
    # Create config file:
    [ ! -f "$CONFIGFILE_path" ] && echo "$CONFIGFILE_default" > "$CONFIGFILE_path"

    # Attemt to ead config file:
    if [ -f "$CONFIGFILE_path" ]
        then source "$CONFIGFILE_path"
        else eval "$CONFIGFILE_default" # Config file does not exist, evaluate 
    fi
}

function main() {
    build

    # Killing process, if already started:
    if [ $PID -gt 0 ]
        then kill $PID && echo "Restarting..."
        else echo "Starting up..."
    fi

    # Starting Process in background and saving process id:
    ./Nimwit &
    PID=$!

    loadConfigFile

    echo "Going to sleep for $EXEC_delay seconds." && sleep "$EXEC_delay"
}

while true; do
    echo "Starting up..."
    main
done
