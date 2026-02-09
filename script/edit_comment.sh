#!/bin/bash
set -ex
cd "$(dirname "$0")"

ARENE_REPO_NAME=${1}
ARENE_TAG=${2}
DTEN_REPO_NAME=${3}
DTEN_TAG=${4}

TIER1_LATEST_HASH=$(bash -x ./script/get_github_repository_head_hash.sh "bevs3-cdc" "${DTEN_REPO_NAME}" "${DTEN_TAG}")
ARENE_MAIN_HASH=$(bash -x ./script/get_github_repository_head_hash.sh "arene-cockpit-sdk" "${ARENE_REPO_NAME}" "${ARENE_TAG}")

echo "ARENE_MAIN_HASH=${ARENE_MAIN_HASH}"
echo "TIER1_LATEST_HASH=${TIER1_LATEST_HASH}"

LOG_COMMENT="
■ 実行リポジトリ情報
・ARENE
${ARENE_REPO_NAME} 
${ARENE_TAG}
${ARENE_MAIN_HASH}

・TIER1
${DTEN_REPO_NAME}
${DTEN_TAG}
${TIER1_LATEST_HASH}
"

echo "${LOG_COMMENT}" >&2
echo "${LOG_COMMENT}"
