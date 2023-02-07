#!/bin/bash

PID=-1
EXEC_delay=$(( 60 * 60 * 6  ))

function build() {
    git pull
    make build
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

    echo "Going to sleep for $EXEC_delay seconds." && sleep $EXEC_delay
}

while true; do
    echo "Starting up..."
    main
done
