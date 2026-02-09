#!/bin/bash
set -ex
cd "$(dirname "$0")"

ARENE_REPO_NAME=${1}
ARENE_TAG=${2}
ARENE_MAIN_HASH=${3}
DTEN_REPO_NAME=${4}
DTEN_TAG=${5}
TIER1_LATEST_HASH=${6}


LOG_COMMENT="\n\
\"■実行リポジトリ情報\n\"\
${ARENE_REPO_NAME} : ${ARENE_TAG} : ${ARENE_MAIN_HASH}\n\
${DTEN_REPO_NAME} : ${DTEN_TAG} : ${TIER1_LATEST_HASH}\
"

echo "${LOG_COMMENT}" >&2
