VERSION="1.0"
COMMAND_NAME="conteur"

USER_NAME="$(logname)"
USER_MAIN_GROUP="$(id -gn "${USER_NAME}")"
USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"

INSTALL_DIR="/usr/local/share/${COMMAND_NAME}"
BIN_LINK="/usr/local/bin/${COMMAND_NAME}"
CONFIG_DIR="${USER_HOME}/.config/conteur"