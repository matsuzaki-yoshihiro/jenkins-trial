#!/bin/bash
#################################################
# 注意
#################################################
# JENKINS_USERNAME, JENKINS_TOKENをexport前提
# xmlstarletのインストールが必要
#################################################
set -ex
cd "$(dirname "$0")"

source ./jenkins_env.sh

JENKINS_FOLDER_NAME=${1:-"test-folder"}

echo "JENKINS_URL: ${JENKINS_URL}"

FOLDER_URL="${JENKINS_FULL_BUILD_URL}/job/${JENKINS_FOLDER_NAME}/doDelete"
# Jenkins Crumb取得
CRUMB=$(curl -s --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

http_status=$(curl -L -s -o /dev/null -w "%{http_code}" -X POST \
"${FOLDER_URL}" \
--user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
-H "$CRUMB")

if [[ "$http_status" -eq 200 ]]; then
  echo "Jenkinsフォルダ削除成功"
elif [[ "$http_status" -eq 404 ]]; then
  echo "Jenkinsフォルダが存在しません（既に削除済み）"
  exit 0
else
  echo "Error: Jenkinsフォルダ削除失敗 (HTTP status: $http_status)" >&2
  exit 1
fi
