def loadStages() {
    // Load and execute each stage
    stage('Checkout') {
        def checkout = load 'stages/checkout.groovy'
        checkout.call()
    }

    stage('Build & Scan') {
        def buildScan = load 'stages/build-scan.groovy'
        buildScan.call()
    }

    stage('Push to ECR') {
        def pushEcr = load 'stages/push-ecr.groovy'
        pushEcr.call()
    }

    stage('Notify') {
        def notify = load 'stages/notify.groovy'
        notify.call()
    }
}

return this