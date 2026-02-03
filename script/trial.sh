#!/bin/bash
set -ex
cd "$(dirname "$0")"

source ./jenkins_env.sh

if [[ "$1" == "create" ]]; then
    ./create_jenkins_folder.sh
elif [[ "$1" == "delete" ]]; then
    ./delete_jenkins_folder.sh
else
  echo "usage: $0 create|delete" >&2
  exit 1
fi