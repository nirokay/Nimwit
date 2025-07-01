#!/usr/bin/env bash

cd $(dirname $0)

while ! git pull; do
    echo -e "Failed to pull changes... retrying."
    sleep 10
done


make build || echo -e "Failed to compile... running bot anyways"

while ! ./Nimwit; do
    echo -e "Bot crashed... restarting."
    sleep 10
done
