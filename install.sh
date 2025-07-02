#/usr/bin/env bash

SYSTEMD_UNITS_DIR=/etc/systemd/system
SERVICE=nimwit.service
SYSTEMD_UNIT_TARGET="${SYSTEMD_UNITS_DIR}/${SERVICE}"

HERE=$(dirname $0)
SYSTEMD_UNIT_SOURCE="${HERE}/${SERVICE}"

[ ! -d "$SYSTEMD_UNITS_DIR" ] && {
    echo -e "Systemd directory '${SYSTEMD_UNITS_DIR}' does not exist :/"
    exit 1
}
[ ! -f "$SYSTEMD_UNIT_SOURCE" ] && {
    echo -e "Service file does not exist at '$SYSTEMD_UNIT_SOURCE' :("
    exit 1
}

# Decide, link or copy:
CHOICE="?"
while [ "$CHOICE" != "ln" ] && [ "$CHOICE" != "LN" ] && [ "$CHOICE" != "cp" ] && [ "$CHOICE" != "CP" ]; do
    echo -e "Choose a method:"
    echo -e "    ln -> Symlinks service module to ${SYSTEMD_UNIT_TARGET}"
    echo -e "    cp -> Copies service module to ${SYSTEMD_UNIT_TARGET}"
    echo -en "[ ln | cp ] ? "
    read CHOICE
done

[ -f "$SYSTEMD_UNIT_TARGET" ] && {
    echo -e "Removing already existing file at '${SYSTEMD_UNIT_TARGET}'"
    sudo rm "$SYSTEMD_UNIT_TARGET" || {
        echo -e "Failed to remove already existing file at '${SYSTEMD_UNIT_TARGET}', aborting."
        exit 1
    }
}

case "$CHOICE" in
    "ln"|"LN")
        echo -e "Creating symlink!"
        sudo ln -s "$SYSTEMD_UNIT_SOURCE" "$SYSTEMD_UNIT_TARGET" || {
            echo -e "Failed to create symlink, aborting."
            exit 1
        }
        ;;
    "cp"|"CP")
        echo -e "Copying!"
        sudo cp "${SYSTEMD_UNIT_SOURCE}" "${SYSTEMD_UNIT_TARGET}" || {
            echo -e "Failed to copy file, aborting."
            exit 1
        }
        ;;
    *)
        echo -e "Unrecognized option '$CHOICE'"
        exit 2
        ;;
esac

sudo systemctl enable "$SERVICE" && echo -e "Enabling service."
sudo systemctl start "$SERVICE" && echo -e "Starting service."
