def call() {
    container('kaniko') {
        sh """
            /kaniko/executor \
            --tarPath=/workspace/image.tar \
            --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:v${BUILD_NUMBER} \
            --dockerfile=${WORKSPACE}/${TARGET_FOLDER}/Dockerfile \
            --cache
        """
        echo "✅ Image pushed to ECR as v${BUILD_NUMBER}"
    }
}
