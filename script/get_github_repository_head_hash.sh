#!/bin/bash
#################################################
# 概要:
#   - GitHubリポジトリのHEADハッシュ取得スクリプト
#################################################
set -ex
cd "$(dirname "$0")"

# 引数チェック
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <GITHUB_REPOSITORY> <GITHUB_BRANCH> <GITHUB_TOKEN>" >&2
  exit 1
fi
GITHUB_REPOSITORY=${1}
GITHUB_BRANCH=${2}
GITHUB_TOKEN=${3}

if [[ -z "${GITHUB_REPOSITORY}" ]]; then
  echo "Error: GitHubリポジトリを指定してください" >&2
  exit 1
fi
if [[ -z "${GITHUB_BRANCH}" ]]; then
  echo "Error: GitHubブランチを指定してください" >&2
  exit 1
fi
if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "Error: GitHubトークンを指定してください" >&2
  exit 1
fi
if [[ "${GITHUB_BRANCH}" == *"/"* ]]; then
  # スラッシュを含む場合はURLエンコードする (e.g. feature/abc -> feature%2Fabc)
  GITHUB_BRANCH_ENCODED=$(echo "${GITHUB_BRANCH}" | sed 's/\//%2F/g')
  API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_BRANCH_ENCODED}"
else
  API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_BRANCH}"
fi

# 認証トークンがある場合はヘッダーに追加
CURL_OPTS=(-s)
if [[ -n "${GITHUB_TOKEN}" ]]; then
  CURL_OPTS+=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

RESPONSE=$(curl "${CURL_OPTS[@]}" "${API_URL}")
HEAD_HASH=$(echo "${RESPONSE}" | grep '"sha":' | head -n 1 | awk -F '"' '{print $4}')

if [[ -z "${HEAD_HASH}" ]]; then
  echo "Error: HEADハッシュの取得に失敗しました" >&2
  echo "Response: ${RESPONSE}" >&2
  exit 1
fi
echo "HEAD hash of ${GITHUB_REPOSITORY} branch ${GITHUB_BRANCH}: ${HEAD_HASH}" >&2
echo "${HEAD_HASH}"