def call() {
    container('kaniko') {
        sh """
            /kaniko/executor \
            --context=dir://${WORKSPACE}/${TARGET_FOLDER} \
            --dockerfile=${WORKSPACE}/${TARGET_FOLDER}/Dockerfile \
            --no-push \
            --tarPath=/workspace/image.tar
        """
    }
}
