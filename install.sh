#/usr/bin/env bash

SYSTEMD_UNITS_DIR=/etc/systemd/system
SERVICE=nimwit.service

HERE=$(dirname $0)

[ ! -d "$SYSTEMD_UNITS_DIR" ] && {
    echo -e "Systemd directory '${SYSTEMD_UNITS_DIR}' does not exist :/"
    exit 1
}
[ ! -f "${HERE}/${SERVICE}" ] && {
    echo -e "Service file does not exist at '${HERE}/${SERVICE}' :("
    exit 1
}

# Decide, link or copy:
CHOICE="?"
while [ "$CHOICE" != "ln" ] && [ "$CHOICE" != "LN" ] && [ "$CHOICE" != "cp" ] && [ "$CHOICE" != "CP" ]; do
    echo -e "Choose a method:"
    echo -e "    ln -> Symlinks service module to ${SYSTEMD_UNITS_DIR}/${SERVICE}"
    echo -e "    cp -> Copies service module to ${SYSTEMD_UNITS_DIR}/${SERVICE}"
    echo -en "[ ln | cp ] ? "
    read CHOICE
done

case "$CHOICE" in
    "ln"|"LN")
        echo -e "Creating symlink!"
        sudo ln -s "${HERE}/${SERVICE}" "${SYSTEMD_UNITS_DIR}/${SERVICE}" || {
            echo -e "Failed to create symlink, aborting."
            exit 1
        }
        ;;
    "cp"|"CP")
        echo -e "Copying!"
        sudo cp "${HERE}/${SERVICE}" "${SYSTEMD_UNITS_DIR}/${SERVICE}" || {
            echo -e "Failed to copy file, aborting."
            exit 1
        }
        ;;
    *)
        echo -e "Unrecognized option '$CHOICE'"
        exit 2
        ;;
esac

sudo systemctl enable "$SERVICE"
sudo systemctl start "$SERVICE"
