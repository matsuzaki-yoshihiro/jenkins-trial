#!/bin/bash
#################################################
# 概要:
#   - Jenkinsジョブconfig.xml更新スクリプト
# 注意:
#   JENKINS_USERNAME, JENKINS_TOKENをexport前提
#   xmlstarletのインストールが必要
#################################################
set -ex
cd "$(dirname "$0")"

# 引数チェック
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <JENKINS_JOB_URL> <JENKINS_JOB_DESCRIPTION>" >&2
  exit 1
fi

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

# config.xmlを取得
JOB_XML="$(curl -s -u "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${JENKINS_JOB_URL}/config.xml")"
if [[ -z "${JOB_XML}" ]]; then
  echo "Error: Jenkinsジョブのconfig.xml取得に失敗しました" >&2
  exit 1
fi

# config.xmlのdescription要素を更新
UPDATED_JOB_XML="$(echo "${JOB_XML}" | xmlstarlet ed -u "/*/description" -v "${JENKINS_JOB_DESCRIPTION}")"
if [[ -z "${UPDATED_JOB_XML}" ]]; then
  echo "Error: config.xmlの更新に失敗しました" >&2
  exit 1
fi

# 更新したconfig.xmlをJenkinsに反映
HTTP_STATUS=$(
  curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${JENKINS_JOB_URL}/config.xml" \
    --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
    -H "Content-Type: application/xml" \
    --data-binary @"-" << EOF
${UPDATED_JOB_XML}
EOF
)
if [[ "$HTTP_STATUS" -ne 200 ]]; then
  echo "Error: Jenkinsジョブのconfig.xml更新に失敗しました (HTTP status: $HTTP_STATUS)" >&2
  exit 1
fi
