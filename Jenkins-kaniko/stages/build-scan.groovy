def call() {
    container('kaniko') {
        sh """
            /kaniko/executor \
            --context=dir://${WORKSPACE}/${env.TARGET_FOLDER} \
            --dockerfile=${WORKSPACE}/${env.TARGET_FOLDER}/Dockerfile \
            --no-push \
            --tarPath=/workspace/image.tar
        """
    }
    container('trivy') {
        sh """
            trivy image \
            --exit-code 0 \
            --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL \
            --no-progress \
            --input /workspace/image.tar
        """
    }
}