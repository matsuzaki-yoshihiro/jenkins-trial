#!/bin/bash
#################################################
# 注意
#################################################
# JENKINS_USERNAME, JENKINS_TOKENをexport前提
#################################################
set -ex
cd "$(dirname "$0")"

# 引数チェック
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <JENKINS_JOB_URL> <JENKINS_JOB_DESCRIPTION>" >&2
  exit 1
fi

source ./jenkins_env.sh

JENKINS_JOB_URL=${1}
JENKINS_JOB_DESCRIPTION=${2}

if [[ -z "${JENKINS_JOB_URL}" ]]; then
  echo "Error: JenkinsジョブURLを指定してください" >&2
  exit 1
fi

if [[ -z "${JENKINS_JOB_DESCRIPTION}" ]]; then
  echo "Error: Jenkinsジョブ説明文を指定してください" >&2
  exit 1
fi

# Jenkins Job の存在確認
JOB_CHECK_URL="${JENKINS_JOB_URL}/api/json"
http_status=$(curl -L -s -o /dev/null -w "%{http_code}" \
  "${JOB_CHECK_URL}" \
  --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}")
if [[ "$http_status" -ne 200 ]]; then
  echo "Error: Jenkinsジョブが存在しません (HTTP status: $http_status)" >&2
  exit 1
fi

# Jenkins Job 説明文更新
JOB_URL="${JENKINS_JOB_URL}/description"
DESCRIPTION="${JENKINS_JOB_DESCRIPTION}"

http_status=$(curl -L -s -o /dev/null -w "%{http_code}" -X POST \
  "${JOB_URL}" \
  --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
  --data-urlencode "description=${DESCRIPTION}")
if [[ "$http_status" -ne 200 && "$http_status" -ne 204 ]]; then
  echo "Error: Jenkinsジョブ説明文更新失敗 (HTTP status: $http_status)" >&2
  exit 1
fi
echo "Jenkinsジョブ説明文更新成功"
