#!/bin/bash

PID=-1
EXEC_delay=$(( 20  ))

function build() {
    git pull
    make build
}

function main() {
    build

    kill $PID && echo "Restarting..."
    ./Nimwit &
    PID=$!

    echo "Going to sleep for $EXEC_delay seconds." && sleep $EXEC_delay
}

while true; do
    echo "Starting up..."
    main
done


