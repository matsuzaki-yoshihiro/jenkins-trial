#!/bin/bash
set -ex
cd "$(dirname "$0")"

MK_TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${MK_TEMP_DIR}"' EXIT HUP INT TERM

echo "MK_TEMP_DIR: ${MK_TEMP_DIR}"

touch "${MK_TEMP_DIR}/test_file.txt"

echo "ls /tmp: $(ls /tmp -l)"
echo "ls ${MK_TEMP_DIR}: $(ls ${MK_TEMP_DIR} -l)"

# 現在時刻の表示（日本時間/JST, YYYY-MM-DD HH:MM:SS形式）
BUILD_ALL_DESCRIPTION="
■ 概要
Arene : mainブランチのHEAD
Tier1 : 集約最新タグ
TMC : main-26cdcブランチのHEAD
meta-luarocks : kirkstone-tmcブランチのHEAD
の組み合わせでビルドを実行し、AreneやTMCの変更によるビルド問題を早期検出する事を目的としたジョブ

■ ビルドトリガー
90-misc/check-arene-tmc-nextジョブにより、ビルド環境の更新とbuild-allジョブの実行が行われる

■ ビルド環境（現在の設定：$(TZ='Asia/Tokyo' date '+%Y-%m-%d %H:%M:%S')更新）
"

echo "${BUILD_ALL_DESCRIPTION}"

echo "Sleeping for 10 seconds..."
sleep 10
