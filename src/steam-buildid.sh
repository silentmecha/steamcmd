#!/usr/bin/env bash

set -euo pipefail

# Ensure required environment variables are set
if [[ -z "${STEAMAPP_ID:-}" ]]; then
    echo "ERROR: STEAMAPP_ID environment variable is not set." >&2
    exit 1
fi

if [[ -z "${STEAMAPPDIR:-}" ]]; then
    echo "ERROR: STEAMAPPDIR environment variable is not set." >&2
    exit 1
fi

MANIFEST="${STEAMAPPDIR}/steamapps/appmanifest_${STEAMAPP_ID}.acf"

# Ensure the manifest exists
if [[ ! -f "${MANIFEST}" ]]; then
    echo "ERROR: Steam app manifest not found: ${MANIFEST}" >&2
    exit 1
fi

# Extract the installed Steam build ID
BUILDID="$(
    awk -F'"' '
        $2 == "buildid" {
            print $4
            exit
        }
    ' "${MANIFEST}"
)"

# Ensure a build ID was found
if [[ -z "${BUILDID}" ]]; then
    echo "ERROR: Failed to determine Steam build ID from: ${MANIFEST}" >&2
    exit 1
fi

# Output only the build ID
printf '%s\n' "${BUILDID}"
