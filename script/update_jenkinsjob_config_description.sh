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

# Cookie保存用の一時ファイルを作成 (Crumb/POSTで同一セッションを維持する)
COOKIE_JAR="$(mktemp)"
trap 'rm -f "${COOKIE_JAR}"' EXIT

# Crumb（CSRFトークン）を取得
# 例: Jenkins-Crumb:xxxxxxxx の形式が返る
CRUMB_HEADER=$(curl -s \
  -c "${COOKIE_JAR}" \
  --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
  "${JENKINS_ROOT_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

if [[ -z "${CRUMB_HEADER}" || "${CRUMB_HEADER}" != *":"* || "${CRUMB_HEADER}" == *"<"* ]]; then
  echo "Warning: Crumb取得に失敗、または形式が不正です: ${CRUMB_HEADER}" >&2
  CRUMB_HEADER=""
fi

# config.xmlを取得 (Cookieを使用)
JOB_XML="$(curl -s -b "${COOKIE_JAR}" "${JENKINS_JOB_URL}/config.xml")"
if [[ -z "${JOB_XML}" ]]; then
  echo "Error: Jenkinsジョブのconfig.xml取得に失敗しました" >&2
  exit 1
fi

if [[ "${JOB_XML}" == *"<!DOCTYPE html"* || "${JOB_XML}" == *"<html"* ]]; then
  echo "Error: config.xmlではなくHTMLが返りました。認証/権限不足の可能性があります" >&2
  exit 1
fi

# config.xmlのdescription要素を更新
UPDATED_JOB_XML="$(echo "${JOB_XML}" | xmlstarlet ed -u "/*/description" -v "${JENKINS_JOB_DESCRIPTION}")"
if [[ -z "${UPDATED_JOB_XML}" ]]; then
  echo "Error: config.xmlの更新に失敗しました" >&2
  exit 1
fi

# 更新したconfig.xmlをJenkinsに反映
http_status=$(
  curl -s -o error_response.html -w "%{http_code}" -X POST \
    "${JENKINS_JOB_URL}/config.xml" \
    -b "${COOKIE_JAR}" \
    -H "Content-Type: application/xml; charset=UTF-8" \
    ${CRUMB_HEADER:+-H "${CRUMB_HEADER}"} \
    --data-binary @"-" << EOF
${UPDATED_JOB_XML}
EOF
)

if [[ "$http_status" -ne 200 && "$http_status" -ne 204 ]]; then
  echo "Error: Jenkinsジョブのconfig.xml更新に失敗しました (HTTP status: $http_status)" >&2
  echo "Response:" >&2
  cat error_response.html >&2
  exit 1
fi
