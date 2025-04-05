#!/usr/bin/env nix-shell
#!nix-shell -i bash -p cacert curl jq nix moreutils --pure
#shellcheck shell=bash
set -eu -o pipefail

cd "$(dirname "$0")"

err() {
    echo "$*" >&2
    exit 1
}

json_get() {
    jq -r "$1" < "./versions.json"
}

json_set() {
    jq --arg x "$2" "$1 = \$x" < "./versions.json" | sponge "./versions.json"
}

newest_version=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r '.tag_name')
url="https://github.com/zen-browser/desktop/releases/download/$newest_version"

if [[ ${newest_version} != "$(json_get ".version")" ]]; then
    sri=$(nix-prefetch-url --type sha256 --unpack $url/zen.linux-x86_64.tar.xz)
    json_set ".version" "${newest_version}"
    json_set ".hash" "sha256:${sri}"

    nix flake update
    nix build
fi
