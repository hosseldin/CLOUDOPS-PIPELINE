// stages/checkout.groovy
def call() {
  stage('Checkout') {
    steps {
      git url: 'https://github.com/hosseldin/CLOUDOPS-APP-PIPELINE.git', 
          branch: 'main'
    }
  }
}