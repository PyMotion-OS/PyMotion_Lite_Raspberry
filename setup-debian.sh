#!/usr/bin/env bash
set -euo pipefail

bundle_root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
data_root="${XDG_DATA_HOME:-${HOME}/.local/share}"
if [[ -n "${PYMOTION_PYTHON:-}" ]]; then
    python_command="$PYMOTION_PYTHON"
elif [[ -x /usr/bin/python3 ]]; then
    python_command=/usr/bin/python3
else
    python_command=python3
fi

[[ "${EUID}" -ne 0 ]] || {
    printf '%s\n' 'Run setup as your normal user, not with sudo.' >&2
    exit 1
}
[[ -r /etc/os-release ]] || {
    printf '%s\n' 'Debian 13 is required.' >&2
    exit 1
}
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == "13" ]] || {
    printf 'Debian 13 is required; found %s %s.\n' "${ID:-unknown}" "${VERSION_ID:-unknown}" >&2
    exit 1
}
[[ "$(uname -m)" == "aarch64" ]] || {
    printf 'A 64-bit ARM kernel and user space are required; found %s.\n' "$(uname -m)" >&2
    exit 1
}
venv_path="${PYMOTION_VENV:-${data_root}/pymotion-lite/venv-cp313-debian13}"
if [[ -f "$bundle_root/internal/install.sh" ]]; then
    PYMOTION_PYTHON="$python_command" PYMOTION_VENV="$venv_path" bash "$bundle_root/internal/install.sh"
else
    PYMOTION_PYTHON="$python_command" PYMOTION_VENV="$venv_path" bash "$bundle_root/install.sh"
fi
printf '\n%s\n' 'Installation diagnostics (no device connection):'
"$venv_path/bin/pymotion" doctor --offline
printf '\n%s\n' 'Debian 13 ARM64 setup finished.'
printf '%s\n' 'If doctor reports missing USB permission, run bash ./install-udev.sh, then reconnect the device.'
printf '%s\n' 'Set the device token in this shell before the live USB example (do not place it in command history).'
printf 'SDK Python: %s/bin/python\n' "$venv_path"
