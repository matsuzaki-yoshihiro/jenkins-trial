#!/bin/bash
set -eu

##################
# ~/.netrc
##################
# GitLabはパスワードでもアクセスできるがPATを使う方が安定性が高いためPATを使用
# ~/.netrcをクリア
echo "" > ~/.netrc
echo "machine gitlab.geniie.net               login ${GENIIE_ART_ID} password ${GENIIE_GITLAB_PAT}" >> ~/.netrc
echo "machine art.geniie.net                  login ${GENIIE_ART_ID} password ${GENIIE_ART_APIKEY}" >> ~/.netrc
echo "machine wiki.geniie.net                 login ${GENIIE_WIKI_ID} password ${GENIIE_WIKI_TOKEN}" >> ~/.netrc
echo "machine artifactory.stargate.toyota     login ${TMCSG_SAAS_ART_ID} password ${TMCSG_SAAS_ART_APIKEY}" >> ~/.netrc
echo "machine jp1-artifactory.stargate.toyota login ${TMCSG_SAAS_ART_ID} password ${TMCSG_SAAS_ART_APIKEY}" >> ~/.netrc
echo "machine github.com                      login ${GENIIE_GITHUB_ID} password ${GENIIE_GITHUB_PAT}" >> ~/.netrc
echo "machine confluence.tmc-stargate.com     login ${TMCSG_CONFLUENCE_ID} password ${TMCSG_CONFLUENCE_PAT}" >> ~/.netrc
echo "machine github.tmc-stargate.com         login ${TMCSG_GITHUB_ID} password ${TMCSG_GITHUB_PAT}" >> ~/.netrc

# sstate-cacheを使うために~/.netrcの権限を600にする必要あり(664は不可)
chmod 600 ~/.netrc
stat ~/.netrc

##################
# Git setting
##################
# ~/.gitconfigをクリア
echo "" > ~/.gitconfig
git config --global user.name "Natsumi Kamei"
git config --global user.email natsumi.kamei.j5j@jpgr.denso.com
git config --global url."https://".insteadOf git://

# 認証情報を設定（GitHubの2つのOrgからのリポジトリを取得するため）
# TMC Stargate GitHub EMU
git config --global url."https://${TMCSG_GITHUB_EMU_ID}:${TMCSG_GITHUB_EMU_TOKEN}@github.com/arene-cockpit-sdk".insteadOf "https://github.com/arene-cockpit-sdk"
git config --global url."https://${TMCSG_GITHUB_EMU_ID}:${TMCSG_GITHUB_EMU_TOKEN}@github.com/arene-cockpit-sdk-sandbox".insteadOf "https://github.com/arene-cockpit-sdk-sandbox"
git config --global url."https://${TMCSG_GITHUB_EMU_ID}:${TMCSG_GITHUB_EMU_TOKEN}@github.com/arene-vehicle-sdk".insteadOf "https://github.com/arene-vehicle-sdk"
git config --global url."https://${TMCSG_GITHUB_EMU_ID}:${TMCSG_GITHUB_EMU_TOKEN}@github.com/arene-spl".insteadOf "https://github.com/arene-spl"
git config --global url."https://${TMCSG_GITHUB_EMU_ID}:${TMCSG_GITHUB_EMU_TOKEN}@github.com/digital-cockpit".insteadOf "https://github.com/digital-cockpit"
# Geniie GitHub
git config --global url."https://${GENIIE_GITHUB_ID}:${GENIIE_GITHUB_PAT}@github.com/bevs3-cdc".insteadOf "https://github.com/bevs3-cdc"
# Geniie GitLab
git config --global url."https://${GENIIE_GITLAB_ID}:${GENIIE_GITLAB_PAT}@gitlab.geniie.net".insteadOf "https://gitlab.geniie.net"

# エラー対策
#   error: RPC failed; result=22, HTTP code = 404
#   fatal: The remote end hung up unexpectedly
git config --global http.postBuffer 524288000
cat ~/.gitconfig

# dn-cdc-lvgvm-misc-integ-agent.gitは${WORKSPACE}に展開されるが、
# bitbakeの中で${WORKSPACE}がmainブランチに意図せず切り替わる為、
# ${WORKSPACE}のスクリプトではなく、ここで取得したスクリプトを使う。
git clone https://github.com/bevs3-cdc/dn-cdc-lvgvm-misc-integ-agent.git
git -C dn-cdc-lvgvm-misc-integ-agent checkout "${GIT_COMMIT}"

##################
# Docker setting
##################
# Setup proxy
sudo mkdir -p /etc/systemd/system/docker.service.d
echo '[Service]' | sudo sh -c 'cat - > /etc/systemd/system/docker.service.d/http-proxy.conf'
echo 'Environment="HTTP_PROXY=http://in-proxy.geniie.net:8080"' | sudo sh -c 'cat - >> /etc/systemd/system/docker.service.d/http-proxy.conf'
echo 'Environment="HTTPS_PROXY=http://in-proxy.geniie.net:8080"' | sudo sh -c 'cat - >> /etc/systemd/system/docker.service.d/http-proxy.conf'
cat /etc/systemd/system/docker.service.d/http-proxy.conf
sudo systemctl daemon-reload
sudo systemctl restart docker

# Geniie Artifactoryへのログイン
echo "${GENIIE_ART_APIKEY}" | docker login --username="${GENIIE_ART_ID}" --password-stdin art.geniie.net
# 起動中のpokyコンテナを停止して削除
if docker ps -a | grep "poky-$(id -un)"; then
  docker stop "poky-$(id -un)"
  docker rm "poky-$(id -un)"
fi
