#!/bin/bash
set -ex
cd "$(dirname "$0")"

ARENE_REPO_NAME=${1}
ARENE_TAG=${2}
DTEN_REPO_NAME=${3}
DTEN_TAG=${4}

TIER1_LATEST_HASH=$(bash -x ./get_github_repository_head_hash.sh "bevs3-cdc" "${DTEN_REPO_NAME}" "${DTEN_TAG}")
ARENE_MAIN_HASH=$(bash -x ./get_github_repository_head_hash.sh "arene-cockpit-sdk" "${ARENE_REPO_NAME}" "${ARENE_TAG}")

echo "ARENE_MAIN_HASH=${ARENE_MAIN_HASH}"
echo "TIER1_LATEST_HASH=${TIER1_LATEST_HASH}"

LOG_COMMENT="
■ 実行リポジトリ情報
・ARENE
${ARENE_REPO_NAME} 
${ARENE_TAG}
${ARENE_MAIN_HASH}

・TIER1
${DTEN_REPO_NAME}
${DTEN_TAG}
${TIER1_LATEST_HASH}
"

echo "${LOG_COMMENT}" >&2

JENKINS_JOB_URL="https://jenkins.geniie.net/bevs3cdc/job/99-maintenance/job/trial_matsuzaki/job/test-folder"

docker run \
  --rm \
  -e http_proxy="${http_proxy}" \
  -e https_proxy="${https_proxy}" \
  -e no_proxy="${no_proxy}" \
  -e JENKINS_USERNAME="${JENKINS_USERNAME}" \
  -e JENKINS_TOKEN="${JENKINS_TOKEN}" \
  -v "${HOME}":/home/hosthome:ro \
  -v "$(pwd)":/workdir \
  --name poky-"$(id -un)" \
  art.geniie.net/bevs3cdc-docker-tier1/poky:ubuntu-22.04 \
  --workdir=/workdir \
  /bin/bash -c "\
            bash -x ./update_jenkinsjob_config_description.sh \"${JENKINS_JOB_URL}\" \"${LOG_COMMENT}\" >&2 \
        " >&2

echo "${LOG_COMMENT}"
