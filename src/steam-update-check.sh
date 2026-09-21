#!/usr/bin/env bash

set -u

if [[ -z "${STEAMAPP_ID:-}" ]]; then
    printf 'false\n'
    exit 0
fi

if ! CURRENT_BUILD_ID="$(
    curl -fsSL \
        "https://api.steamcmd.net/v1/info/${STEAMAPP_ID}" |
    jq -er \
        ".data[\"${STEAMAPP_ID}\"].depots.branches.public.buildid"
)"; then
    printf 'false\n'
    exit 0
fi

if [[ ! "${CURRENT_BUILD_ID}" =~ ^[0-9]+$ ]]; then
    printf 'false\n'
    exit 0
fi

if ! INSTALLED_BUILD_ID="$(steam-buildid 2>/dev/null)"; then
    printf 'false\n'
    exit 0
fi

if [[ "${INSTALLED_BUILD_ID}" == "${CURRENT_BUILD_ID}" ]]; then
    printf 'true\n'
else
    printf 'false\n'
fi
