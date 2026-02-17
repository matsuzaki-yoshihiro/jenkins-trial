#!/bin/bash
set -ex
cd "$(dirname "$0")"

echo "pwd: $(pwd)"
echo "ls: $(ls -l)"

MK_TEMP="$(mktemp)"
trap 'rm -f "${MK_TEMP}"' EXIT

echo "Cookie Jar: ${MK_TEMP}"

echo "ls: $(ls -l)"

echo "Sleeping for 10 seconds..."
sleep 10
