#!/bin/bash
#################################################
# 注意
#################################################
# JENKINS_USERNAME, JENKINS_TOKENをexport前提
#################################################
set -ex
cd "$(dirname "$0")"

source ./jenkins_env.sh

JOB_NAME="trial"

echo "JENKINS_URL: ${JENKINS_URL}"

# ジョブのビルドURL
JOB_URL="${JENKINS_FULL_BUILD_URL}/job/${JOB_NAME}/build"
echo "JOB_URL: ${JOB_URL}"

# Jenkins Crumb取得
CRUMB=$(curl -s --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# ビルド実行
http_status=$(curl -L -s -o /dev/null -w "%{http_code}" -X POST \
"${JOB_URL}" \
--user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
-H "$CRUMB")

# 201 Created: キューに追加された
if [[ "$http_status" -eq 201 ]]; then
  echo "Jenkins Job起動成功"
else
  echo "Error: Jenkins Job起動失敗 (HTTP status: $http_status)" >&2
  exit 1
fi