// stages/notify.groovy
def call() {
  stage('Notify Slack') {
    steps {
      script {
        slackSend(
          channel: 'eks-jenkins-notifications',
          attachments: [
            [
              fallback: "Build #${env.BUILD_NUMBER} finished",
              color: '#36a64f',
              title: "Build #${env.BUILD_NUMBER} Complete",
              text: "Project: *${env.JOB_NAME}*\nBranch: *${env.GIT_BRANCH}*\nStatus: *SUCCESS*\nCommit: *${env.GIT_COMMIT}*",
              fields: [
                [title: "Started by", value: "${currentBuild.getBuildCauses()[0].userName ?: 'Auto Triggered'}", short: true],
                [title: "Duration", value: "${currentBuild.durationString}", short: true]
              ],
              image_url: 'https://mediaaws.almasryalyoum.com/news/large/2025/01/16/2583858_0.jpg'
            ]
          ]
        )
      }
    }
  }
}