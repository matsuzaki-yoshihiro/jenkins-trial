#!/bin/bash
set -ex
cd "$(dirname "$0")"

MK_TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${MK_TEMP_DIR}"' EXIT HUP INT TERM

echo "MK_TEMP_DIR: ${MK_TEMP_DIR}"

touch "${MK_TEMP_DIR}/test_file.txt"

echo "ls /tmp: $(ls /tmp -l)"
echo "ls ${MK_TEMP_DIR}: $(ls ${MK_TEMP_DIR} -l)"

echo "Sleeping for 10 seconds..."
sleep 10
