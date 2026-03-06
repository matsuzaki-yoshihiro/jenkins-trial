pipeline {
    agent any

    parameters {
        string(name: 'ARENE_TAG', defaultValue: "default", description: '取り込むARENEのタグ e.g.v12.5.0')
        string(name: 'DTEN_TAG', defaultValue: "default", description: '取り込むDTENのタグ e.g.0.20.0.0-rc.2')
    }

    environment {
        // proxy setting
        http_proxy="http://in-proxy.geniie.net:8080"
        https_proxy="http://in-proxy.geniie.net:8080"
        no_proxy="127.0.0.1,localhost,art.geniie.net,gitlab.geniie.net,jenkins.geniie.net"
        BRANCH = "${env.JOB_NAME.substring((env.JOB_NAME.indexOf("/")+1), env.JOB_NAME.lastIndexOf("/"))}"
        JOB_DIR = "${env.JOB_NAME.substring(0, env.JOB_NAME.lastIndexOf("/"))}"
    }

    stages {
        stage('trap test') {
            when {
                expression { return false }
            }
            steps {
                sh '''
                # 現在時刻の表示（YYYY-MM-DD HH:MM:SS形式）
                echo "Current time: $(date '+%Y-%m-%d %H:%M:%S')"
                ./script/trap_test.sh
                '''
            }
        }
        stage('Show parameters') {
            steps {
                echo "JENKINS_URL is ${env.JENKINS_URL}"
                // ジョブ名表示
                echo "JOB_NAME is ${env.JOB_NAME}"
                echo "JOB_DIR is ${JOB_DIR}"
                // カレントディレクトリ表示
                sh 'echo "pwd:`pwd`"'
                // 作業ディレクトリとファイル一覧を表示
                sh 'ls -la'


                echo "ARENE_TAG: ${ARENE_TAG}"
                echo "DTEN_TAG: ${DTEN_TAG}"

                script {
                    // ARENE_TAGがdefaultの場合、mainブランチを取得
                    if (ARENE_TAG == "default") {
                        env.ARENE_TAG = "main"
                    }

                    // DTEN_TAGがdefaultの場合、最新タグを取得
                    if (DTEN_TAG == "default") {
                        env.DTEN_TAG = sh(script: "git describe --tags \$(git rev-list --tags --max-count=1)", returnStdout: true).trim()
                    }

                    // このJOBに設定された定期実行情報（cron文字列 / trigger XML / trigger JSON）を取得
                    def CRON_SCHEDULE = ""
                    def TRIGGER_XML = ""
                    def TRIGGER_JSON = ""
                    withCredentials([
                        usernamePassword(credentialsId: "GENIIE_JENKINS_CREDS", passwordVariable: 'JENKINS_TOKEN', usernameVariable: 'JENKINS_USERNAME')
                    ]) {
                        CRON_SCHEDULE = sh(script: '''
                        set -e

                        JOB_PATH=$(printf '%s' "${JOB_NAME}" | sed 's|/|/job/|g')
                        CONFIG_URL="${JENKINS_URL%/}/job/${JOB_PATH}/config.xml"

                        curl -fsSL --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${CONFIG_URL}" \
                        | sed -n 's:.*<spec>\\(.*\\)</spec>.*:\\1:p' \
                        | head -n1
                        ''', returnStdout: true).trim()

                        TRIGGER_XML = sh(script: '''
                        set -e

                        JOB_PATH=$(printf '%s' "${JOB_NAME}" | sed 's|/|/job/|g')
                        CONFIG_URL="${JENKINS_URL%/}/job/${JOB_PATH}/config.xml"

                        CONFIG_XML=$(curl -fsSL --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${CONFIG_URL}")

                        if printf '%s\n' "${CONFIG_XML}" | grep -q '<triggers/>'; then
                            printf '%s\n' '<triggers/>'
                        else
                            printf '%s\n' "${CONFIG_XML}" | awk 'index($0,"<triggers"){f=1} f{print} index($0,"</triggers>"){f=0}'
                        fi
                        ''', returnStdout: true).trim()

                        TRIGGER_JSON = sh(script: '''
                        set -e

                        JOB_PATH=$(printf '%s' "${JOB_NAME}" | sed 's|/|/job/|g')
                        API_URL="${JENKINS_URL%/}/job/${JOB_PATH}/api/json"

                        curl -fsSL --user "${JENKINS_USERNAME}:${JENKINS_TOKEN}" "${API_URL}"
                        ''', returnStdout: true).trim()
                    }
                    echo "CRON_SCHEDULE: ${CRON_SCHEDULE}"
                    echo "TRIGGER_XML:\n${TRIGGER_XML}"
                    echo "TRIGGER_JSON: ${TRIGGER_JSON}"

                    
                }

                echo "ARENE_TAG: ${ARENE_TAG}"
                echo "DTEN_TAG: ${DTEN_TAG}"
            }
        }
        stage('Set environment') {
            when {
                expression { return false }
            }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: "GENIIE_ARTIFACTORY_CREDS", passwordVariable: 'GENIIE_ART_APIKEY'     , usernameVariable: 'GENIIE_ART_ID'),
                    usernamePassword(credentialsId: "GENIIE_WIKI_CREDS"       , passwordVariable: 'GENIIE_WIKI_TOKEN'     , usernameVariable: 'GENIIE_WIKI_ID'),
                    usernamePassword(credentialsId: "GENIIE_JIRA_CREDS"       , passwordVariable: 'GENIIE_JIRA_TOKEN'     , usernameVariable: 'GENIIE_JIRA_ID'),
                    usernamePassword(credentialsId: "GENIIE_GITLAB_CREDS"     , passwordVariable: 'GENIIE_GITLAB_PAT'     , usernameVariable: 'GENIIE_GITLAB_ID'),
                    usernamePassword(credentialsId: "GITHUB_DTEN_CREDS"       , passwordVariable: 'GENIIE_GITHUB_PAT'     , usernameVariable: 'GENIIE_GITHUB_ID'),
                    usernamePassword(credentialsId: "GITHUB_TMCSG_CREDS"      , passwordVariable: 'TMCSG_GITHUB_PAT'      , usernameVariable: 'TMCSG_GITHUB_ID'),
                    usernamePassword(credentialsId: "GITHUB_WOVEN_CREDS"      , passwordVariable: 'TMCSG_GITHUB_EMU_TOKEN', usernameVariable: 'TMCSG_GITHUB_EMU_ID'),
                    usernamePassword(credentialsId: "GIT_CODELINARO_CREDS"    , passwordVariable: 'CODELINARO_GITLAB_PAT' , usernameVariable: 'CODELINARO_GITLAB_ID'),
                    usernamePassword(credentialsId: "TMCSG_ARTIFACTORY_CREDS" , passwordVariable: 'TMCSG_SAAS_ART_APIKEY' , usernameVariable: 'TMCSG_SAAS_ART_ID'),
                    usernamePassword(credentialsId: "GENIIE_JENKINS_CREDS"    , passwordVariable: 'JENKINS_TOKEN'         , usernameVariable: 'JENKINS_USERNAME'),
                    usernamePassword(credentialsId: "RC_BOT_CREDS"            , passwordVariable: 'RC_BOT_APIKEY'         , usernameVariable: 'RC_BOT_APIID'),
                    usernamePassword(credentialsId: "CONFLUENCE_TMCSG_CREDS"  , passwordVariable: 'TMCSG_CONFLUENCE_PAT'  , usernameVariable: 'TMCSG_CONFLUENCE_ID')
                    ]) {
                    script {
                        sh '''
                        # clean workspace ("-ffdx" is not typo)
                        git clean -ffdx

                        # setup environment
                        ./script/setup.sh
                        '''

                        //def TIER1_LATEST_HASH = sh(script: "./script/get_github_repository_head_hash.sh \"bevs3-cdc\" \"dn-cdc-lvgvm-26bev-repo\" \"${option}\"", returnStdout: true).trim()
                        //def ARENE_MAIN_HASH = sh(script: "./script/get_github_repository_head_hash.sh \"arene-cockpit-sdk\" \"arene-cockpit-sdk-26bev-repo\" \"main\"", returnStdout: true).trim()

                        //echo "ARENE_MAIN_HASH=${ARENE_MAIN_HASH}"
                        //echo "TIER1_LATEST_HASH=${TIER1_LATEST_HASH}"

                        def LOG_COMMENT = sh(script: "./script/edit_comment.sh \"arene-cockpit-sdk-26bev-repo\" \"main\" \"dn-cdc-lvgvm-26bev-repo\" \"${option}\" ", returnStdout: true).trim()
                        currentBuild.description = "${LOG_COMMENT}"
                    }
                }
            }
        }
        stage('Test') {
            when {
                expression { return false }
            }
            steps {
                echo 'Testing...'
                withCredentials([
                    usernamePassword(credentialsId: "GENIIE_JENKINS_CREDS"    , passwordVariable: 'JENKINS_TOKEN'         , usernameVariable: 'JENKINS_USERNAME'),
                    ]) {
                    sh '''
                    # clean workspace ("-ffdx" is not typo)
                    git clean -ffdx

#                    ./script/trial.sh ${option}

                    DESCRIPTION='\
                    \n\
                    ■概要\n\
                    　Arene : mainブランチ\n\
                    　Tier1 : 集約最新タグ\n\
                    　の組み合わせでのビルド実行\n\
                    \n\
                    ■ビルドトリガー\n\
                    　90-misc/check-arene-next Jobにより環境の更新とこのJobの実行が行われる\'

                    # DESCRIPTIONの先頭と各行頭の空白を削除
                    DESCRIPTION=$(echo "${DESCRIPTION}" | sed 's/^[ \t]*//;s/\\n[ \t]*/\\n/g')

                    ./script/write_jenkinsjob_description.sh "https://jenkins.geniie.net/bevs3cdc/job/99-maintenance/job/trial_matsuzaki/job/trial" "${DESCRIPTION}"
                    '''
                }
            }
        }
    }
}