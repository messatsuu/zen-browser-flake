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

resolve_url() {
    url="https://api.github.com/repos/zen-browser/desktop/releases/latest"
    url=$(curl $url | grep "browser_download_url.*zen.linux-specific.tar" | grep -oP '(?<="browser_download_url": ")[^"]*')
    echo "${url}"
}

get_version() {
    echo "$1" | grep -oP '(?<=download/)[^/]+'
}

url=$(resolve_url)
version=$(get_version "${url}")
if [[ ${version} != "$(json_get ".version")" ]]; then
    sri=$(nix-prefetch-url --unpack "$url")
    json_set ".version" "${version}"
    json_set ".hash" "sha256:${sri}"
fi
