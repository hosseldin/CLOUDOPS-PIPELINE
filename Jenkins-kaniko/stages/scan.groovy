def call() {
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
