#!/bin/bash
#################################################
# 注意
#################################################
# JENKINS_USERNAME, JENKINS_TOKENをexport前提
# xmlstarletのインストールが必要
#################################################
set -ex
cd "$(dirname "$0")"

JENKINS_FOLDER_NAME=${1:-"test-folder"}

source ./jenkins_env.sh

FOLDER_URL="${JENKINS_FULL_BUILD_URL}/createItem?name=${JENKINS_FOLDER_NAME}"
FOLDER_XML='<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.722.v8165b_a_cf25e9"><actions/><description>trialフォルダ</description><properties/><com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder><views/><tabBar class="hudson.views.DefaultViewsTabBar"/></com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder><healthMetrics/><icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/></com.cloudbees.hudson.plugins.folder.Folder>'

http_status=$(curl -L -s -o /dev/null -w "%{http_code}" -X POST \
  "${FOLDER_URL}" \
  --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" \
  --header "Content-type: application/xml" \
  --data-binary "${FOLDER_XML}")

if [[ "$http_status" -ne 200 ]]; then
  echo "Error: Jenkinsフォルダ作成失敗 (HTTP status: $http_status)" >&2
  exit 1
fi

echo "Jenkinsフォルダ作成成功"
