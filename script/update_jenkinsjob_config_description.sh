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

# JenkinsのルートURLを推定 (Crumb取得用)
JENKINS_ROOT_URL=$(echo "${JENKINS_JOB_URL}" | sed 's|/job/.*||')

# Crumb（CSRFトークン）を取得
CRUMB_VALUE=$(curl -s -u "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${JENKINS_ROOT_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
CRUMB_HEADER=""
if [[ "$CRUMB_VALUE" == *"Jenkins-Crumb"* ]]; then
  echo "Crumb取得成功: ${CRUMB_VALUE}" >&2
  CRUMB_HEADER="${CRUMB_VALUE}"
else
  echo "Crumb取得スキップ (または失敗): ${CRUMB_VALUE}" >&2
fi

# config.xmlを取得
JOB_XML="$(curl -s -u "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${JENKINS_JOB_URL}/config.xml")"

echo "JOB_XML:${JOB_XML}" >&2

# config.xmlのdescription要素を更新
UPDATED_JOB_XML="$(echo "${JOB_XML}" | xmlstarlet ed -u "/*/description" -v "${JENKINS_JOB_DESCRIPTION}")"
if [[ -z "${UPDATED_JOB_XML}" ]]; then
  echo "Error: config.xmlの更新に失敗しました" >&2
  exit 1
fi

echo "UPDATED_JOB_XML:${UPDATED_JOB_XML}" >&2

# 更新したconfig.xmlをJenkinsに反映
CURL_CMD=(curl -L -s -o error_response.html -w "%{http_code}" -X POST)
CURL_CMD+=(-u "${JENKINS_USERNAME}:${JENKINS_TOKEN}")
CURL_CMD+=(-H "Content-Type: application/xml")
if [[ -n "${CRUMB_HEADER}" ]]; then
  CURL_CMD+=(-H "${CRUMB_HEADER}")
fi
CURL_CMD+=(--data-binary "${UPDATED_JOB_XML}" "${JENKINS_JOB_URL}/config.xml")

http_status=$("${CURL_CMD[@]}")

if [[ "$http_status" -ne 200 && "$http_status" -ne 204 ]]; then
  echo "Error: Jenkinsジョブconfig.xml更新失敗 (HTTP status: $http_status)" >&2
  echo "error_response.htmlの内容:" >&2
  cat error_response.html >&2
  exit 1
fi
echo "Jenkinsジョブconfig.xml更新成功"
