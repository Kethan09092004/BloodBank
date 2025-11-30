pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build (Ant)') {
      steps {
        echo 'Running Ant build...'
        script {
          // use Ant tool configured in Manage Jenkins -> Global Tool Configuration (name = ant)
          def antHome = tool 'ant'
          bat "\"${antHome}\\bin\\ant\" clean dist"
        }
        archiveArtifacts artifacts: 'dist/*.war', fingerprint: true
      }
    }

    stage('Deploy to Tomcat') {
      when { expression { return true } } // change to false to skip deploy
      steps {
        withCredentials([usernamePassword(credentialsId: 'tomcat-cred', usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
          bat """
            set WAR=%WORKSPACE%\\dist\\BloodBank.war
            echo Undeploying previous app (if exists)...
            curl -s -u %TOMCAT_USER%:%TOMCAT_PASS% "http://localhost:8090/manager/text/undeploy?path=/BloodBank" || echo "undeploy ignored"
            echo Deploying new WAR...
            curl -s -u %TOMCAT_USER%:%TOMCAT_PASS% -T "%WAR%" "http://localhost:8090/manager/text/deploy?path=/BloodBank&update=true"
          """
        }
      }
    }

   

  post {
    success { echo 'Pipeline succeeded — application deployed.' }
    failure { echo 'Pipeline failed — check console output for errors.' }
  }
}
