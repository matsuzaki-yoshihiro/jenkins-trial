#!/bin/bash
#################################################
# 概要:
#   - GitHubリポジトリのHEADハッシュ取得スクリプト
#################################################
set -ex
cd "$(dirname "$0")"

# 引数チェック
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <GITHUB_REPOSITORY> <GITHUB_BRANCH>" >&2
  exit 1
fi
GITHUB_REPOSITORY=${1}
GITHUB_BRANCH=${2}
if [[ -z "${GITHUB_REPOSITORY}" ]]; then
  echo "Error: GitHubリポジトリを指定してください" >&2
  exit 1
fi
if [[ -z "${GITHUB_BRANCH}" ]]; then
  echo "Error: GitHubブランチを指定してください" >&2
  exit 1
fi
# GitHub APIを使用してHEADハッシュを取得
API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/branches/${GITHUB_BRANCH}"
HEAD_HASH=$(curl -s "${API_URL}" | grep '"sha":' | head -n 1 | awk -F '"' '{print $4}')
if [[ -z "${HEAD_HASH}" ]]; then
  echo "Error: HEADハッシュの取得に失敗しました" >&2
  exit 1
fi
echo "HEAD hash of ${GITHUB_REPOSITORY} branch ${GITHUB_BRANCH}: ${HEAD_HASH}" >&2
echo "${HEAD_HASH}"