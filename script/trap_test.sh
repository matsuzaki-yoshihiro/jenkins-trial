#!/bin/bash
set -ex
cd "$(dirname "$0")"

MK_TEMP="$(mktemp)"
trap 'rm -f "${MK_TEMP}"' EXIT

echo "MK_TEMP: ${MK_TEMP}"

echo "ls: $(ls /tmp -l)"

echo "Sleeping for 10 seconds..."
sleep 10
