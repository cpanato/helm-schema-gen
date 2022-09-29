#!/usr/bin/env sh

# Improved and inspired by https://github.com/databus23/helm-diff/blob/master/install-binary.sh

PROJECT_NAME="helm-schema-gen"
PROJECT_ORG="${PROJECT_ORG:-cpanato}"
PROJECT_GH="$PROJECT_ORG/$PROJECT_NAME"
export GREP_COLOR="never"

if command -v cygpath >/dev/null 2>&1; then
  HELM_BIN="$(cygpath -u "${HELM_BIN}")"
  HELM_PLUGIN_DIR="$(cygpath -u "${HELM_PLUGIN_DIR}")"
fi

[ -z "$HELM_BIN" ] && HELM_BIN=$(command -v helm)

[ -z "$HELM_HOME" ] && HELM_HOME=$(helm env | grep 'HELM_DATA_HOME' | cut -d '=' -f2 | tr -d '"')

mkdir -p "${HELM_HOME}"

: "${HELM_PLUGIN_DIR:="$HELM_HOME/plugins/$PROJECT_NAME"}"

# Convert the HELM_PLUGIN_DIR to unix if cygpath is
# available. This is the case when using MSYS2 or Cygwin
# on Windows where helm returns a Windows path but we
# need a Unix path


if [ "$SKIP_BIN_INSTALL" = "1" ]; then
  echo "Skipping binary install"
  exit
fi

# which mode is the common installer script running in
SCRIPT_MODE="install"
if [ "$1" = "-u" ]; then
  SCRIPT_MODE="update"
fi

# initArch discovers the architecture for this system.
initArch() {
  ARCH=$(uname -m)
  case $ARCH in
  armv5*) ARCH="armv5" ;;
  armv6*) ARCH="armv6" ;;
  armv7*) ARCH="armv7" ;;
  aarch64) ARCH="arm64" ;;
  x86) ARCH="386" ;;
  x86_64) ARCH="amd64" ;;
  i686) ARCH="386" ;;
  i386) ARCH="386" ;;
  esac
}

# initOS discovers the operating system for this system.
initOS() {
  OS=$(uname | tr '[:upper:]' '[:lower:]')

  case "$OS" in
  # Msys support
  msys*) OS='windows' ;;
  # Minimalist GNU for Windows
  mingw*) OS='windows' ;;
  cygwin*) OS='windows' ;;
  esac
}

# verifySupported checks that the os/arch combination is supported for
# binary builds.
verifySupported() {
  supported="linux-amd64\ndarwin-amd64\nlinux-arm\nlinux-arm64\ndarwin-arm64\nwindows-amd64"
  if ! echo "${supported}" | grep -q "${OS}-${ARCH}"; then
    echo "No prebuild binary for ${OS}-${ARCH}."
    exit 1
  fi

  if ! type "curl" >/dev/null && ! type "wget" >/dev/null; then
    echo "Either curl or wget is required"
    exit 1
  fi
}

# getDownloadURL checks the latest available version.
getDownloadURL() {
  #version=$(git -C "$HELM_PLUGIN_DIR" describe --tags --exact-match 2>/dev/null || :)
  version="$(grep "version" "$HELM_PLUGIN_DIR/plugin.yaml" | cut -d '"' -f 2)"
  if [ "$SCRIPT_MODE" = "install" ] && [ -n "$version" ]; then
    DOWNLOAD_URL="https://github.com/$PROJECT_GH/releases/download/v$version/$PROJECT_NAME-$OS-$ARCH"
  else
    # Use the GitHub API to find the download url for this project.
    DOWNLOAD_URL="https://github.com/$PROJECT_GH/releases/latest/download/$PROJECT_NAME-$OS-$ARCH"
  fi
}

# Temporary dir
mkTempDir() {
  HELM_TMP="$(mktemp -d -t "${PROJECT_NAME}-XXXXXX")"
}
rmTempDir() {
  if [ -d "${HELM_TMP:-/tmp/helm-diff-tmp}" ]; then
    rm -rf "${HELM_TMP:-/tmp/helm-diff-tmp}"
  fi
}

# downloadFile downloads the latest binary package and also the checksum
# for that binary.
downloadFile() {
  PLUGIN_TMP_FILE="${HELM_TMP}/${PROJECT_NAME}"
  echo "Downloading $DOWNLOAD_URL"

  if type "curl" >/dev/null 2>&1; then
    HTTP_CODE=$(curl -sSfL --write-out "%{http_code}" --output "$PLUGIN_TMP_FILE" "$DOWNLOAD_URL")
    if [ "${HTTP_CODE}" -ne 200 ]; then
      exit 1
    fi
  elif type "wget" >/dev/null 2>&1; then
    wget -q -O "$PLUGIN_TMP_FILE" "$DOWNLOAD_URL"
  fi
}

installPlugin() {
  echo "Preparing to install into ${HELM_PLUGIN_DIR}"
  mkdir -p "$HELM_PLUGIN_DIR/bin"
  cp "$PLUGIN_TMP_FILE" "$HELM_PLUGIN_DIR/bin"
  chmod +x "$HELM_PLUGIN_DIR/bin/$PROJECT_NAME"
}

# exit_trap is executed if an error occurs.
exit_trap() {
  result=$?
  rmTempDir
  if [ "$result" != "0" ]; then
    echo "Failed to install $PROJECT_NAME"
    printf '\tFor support, go to https://github.com/%s.\n' "$PROJECT_GH"
  fi
  exit $result
}

# testVersion tests the installed client to make sure it is working.
testVersion() {
  set +e
  echo "$PROJECT_NAME installed into $HELM_PLUGIN_DIR/$PROJECT_NAME"
  "${HELM_PLUGIN_DIR}/bin/$PROJECT_NAME" version
  set -e
}

# Execution

#Stop execution on any error
trap "exit_trap" EXIT
set -e
initArch
initOS
verifySupported
getDownloadURL
mkTempDir
downloadFile
installPlugin
testVersion
