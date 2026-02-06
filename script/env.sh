#!/bin/bash
#################################################
# 概要:
#   - check-arene-next Job用
#     共通パラメータ定義
#################################################
export BRANCH_SEC="feature"
export BRANCH_NAME="arene-next"

# Jenkins関連変数
export JENKINS_URL="https://jenkins.geniie.net/bevs3cdc"
export JENKINS_JOB_URL="${JENKINS_URL}/job/01-build-linux/job/${BRANCH_SEC}/job/${BRANCH_NAME}"

# Github関連変数
export GITHUB_URL="https://github.com"
export NAMESPACE_DTEN_IVI="bevs3-cdc"
export DN_CDC_URL="${GITHUB_URL}/${NAMESPACE_DTEN_IVI}"

export TARGET_REPO=(
  dn-cdc-lvgvm-26bev-repo
  dn-cdc-lvgvm-manifest-collection
  dn-cdc-lvgvm-misc-integ-key-management
  dn-cdc-lvgvm-misc-integ-signing-tools
  dn-cdc-lvgvm-tier1-param
  meta-dn-cdc
  meta-dn-selinux-policies
)

export TARGET_BRANCH="${BRANCH_SEC}/${BRANCH_NAME}"
