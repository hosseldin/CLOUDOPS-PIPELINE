// stages/push-ecr.groovy
def call() {
  stage('Push Verified Image to ECR') {
    steps {
      container('kaniko') {
        script {
          sh """
            /kaniko/executor \
            --tarPath=/workspace/image.tar \
            --destination=${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:v${BUILD_NUMBER} \
            --dockerfile=${WORKSPACE}/${env.TARGET_FOLDER}/Dockerfile \
            --cache
          """
          echo "✅ Successfully pushed to ECR!"
        }
      }
    }
  }
}