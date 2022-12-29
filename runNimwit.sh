#!/bin/bash

PID=0
EXEC_delay=$(( 60 * 60 * 6 ))

function main() {
    git pull
    make build

    ./Nimwit &
    PID=$!

    sleep $EXEC_delay
    kill $PID
}

while true; do
    echo "Starting up..."
    main
done


