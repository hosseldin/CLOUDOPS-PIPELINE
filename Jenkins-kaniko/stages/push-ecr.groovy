def call() {
    container('kaniko') {
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