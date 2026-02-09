#!/bin/bash
#################################################
# 概要:
#   - GitHubリポジトリのHEADハッシュ取得スクリプト
#################################################
set -ex
cd "$(dirname "$0")"

# 引数チェック
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <GITHUB_NAME_SPACE> <GITHUB_REPOSITORY> <GITHUB_BRANCH>" >&2
    exit 1
fi

GITHUB_NAME_SPACE=${1}
GITHUB_REPOSITORY=${2}
GITHUB_BRANCH=${3}

if [[ -z "${GITHUB_NAME_SPACE}" ]]; then
    echo "Error: GitHub名前空間を指定してください" >&2
    exit 1
fi
if [[ -z "${GITHUB_REPOSITORY}" ]]; then
    echo "Error: GitHubリポジトリを指定してください" >&2
    exit 1
fi
if [[ -z "${GITHUB_BRANCH}" ]]; then
    echo "Error: GitHubブランチを指定してください" >&2
    exit 1
fi

# GITHUB_TOKENを~/.gitconfigから取得する
GITHUB_TOKEN="$(grep "https://.*@github.com/${GITHUB_NAME_SPACE}" ~/.gitconfig | head -n1 | cut -d: -f3 | cut -d@ -f1)"
if [ -z "$GITHUB_TOKEN" ]; then
    echo "🚨 ~/.gitconfig に ${GITHUB_NAME_SPACE} org の Github Personal Access Token が見つかりませんでした。"
    echo "🚨 下記手順書を参照して ~/.gitconfig を改めてください。"
    echo "https://wiki.geniie.net/x/g0WJqg"
    exit 1
fi

API_URL="https://api.github.com/repos/${GITHUB_NAME_SPACE}/${GITHUB_REPOSITORY}/commits/${GITHUB_BRANCH}"

RESPONSE=$(curl -s \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_URL}")

HEAD_HASH=$(echo "${RESPONSE}" | grep '"sha":' | head -n 1 | awk -F '"' '{print $4}')

if [[ -z "${HEAD_HASH}" ]]; then
    echo "Error: HEADハッシュの取得に失敗しました" >&2
    echo "Response: ${RESPONSE}" >&2
    exit 1
fi

echo "HEAD hash of ${GITHUB_REPOSITORY} branch ${GITHUB_BRANCH}: ${HEAD_HASH}" >&2
echo "${HEAD_HASH}"
