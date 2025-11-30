pipeline {
  agent any

  environment {
    // used for Sonar later if needed
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build (Ant)') {
      steps {
        echo 'Running Ant...'
        // run ant; requires ant on PATH or configured tool
        bat 'ant clean dist'
        archiveArtifacts artifacts: 'dist/*.war', fingerprint: true
      }
    }

    stage('Deploy to Tomcat') {
      when { expression { return true } } // keep deploy step active; change to false to skip
      steps {
        withCredentials([usernamePassword(credentialsId: 'tomcat-cred', usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
          bat """
            set WAR=%WORKSPACE%\\dist\\BloodBank.war
            REM Undeploy (ignore error)
            curl -u %TOMCAT_USER%:%TOMCAT_PASS% "http://<TOMCAT_HOST>:8080/manager/text/undeploy?path=/BloodBank" || echo "undeploy failed"
            REM Deploy new WAR
            curl -u %TOMCAT_USER%:%TOMCAT_PASS% -T "%WAR%" "http://<TOMCAT_HOST>:8080/manager/text/deploy?path=/BloodBank&update=true"
          """
        }
      }
    }

    stage('Smoke test') {
      steps {
        bat 'timeout /t 5 >nul & curl -f "http://<TOMCAT_HOST>:8080/BloodBank/index.jsp"'
      }
    }
  }

  post {
    success { echo 'Pipeline succeeded' }
    failure { echo 'Pipeline failed — check console output' }
  }
}
