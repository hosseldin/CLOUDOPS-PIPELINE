// vars/shared-library
def checkoutStage() {
  load '../stages/checkout.groovy'
}

def buildScanStage() {
  load '../stages/build-scan.groovy'
}

def pushEcrStage() {
  load '../stages/push-ecr.groovy'
}

def notifyStage() {
  load '../stages/notify.groovy'
}