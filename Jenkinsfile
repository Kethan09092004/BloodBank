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

    stage('SonarQube Analysis') {
      steps {
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('SonarQube') {
            script {
              // use the SonarScanner installed via Global Tool Config (name = SonarScanner)
              def scannerHome = tool 'SonarScanner'
              bat """
                \"${scannerHome}\\bin\\sonar-scanner.bat\" ^
                  -Dsonar.projectKey=BloodBank ^
                  -Dsonar.sources=src ^
                  -Dsonar.java.binaries=build\\WEB-INF\\classes ^
                  -Dsonar.login=%SONAR_TOKEN%
              """
            }
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          // requires SonarQube plugin; will abort pipeline if Quality Gate not OK
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Deploy to Tomcat') {
      when { expression { return true } }
      steps {
        withCredentials([usernamePassword(credentialsId: 'tomcat-cred', usernameVariable: 'TOMCAT_USER', passwordVariable: 'TOMCAT_PASS')]) {
          bat """
            @echo off
            setlocal enabledelayedexpansion

            set WAR=%WORKSPACE%\\dist\\BloodBank.war
            echo === Preparing deploy: %WAR% ===

            rem 1) Try undeploy (capture output; ignore non-zero)
            echo === Undeploy (if exists) ===
            curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% "http://localhost:8092/manager/text/undeploy?path=/BloodBank" > undeploy_out.txt 2>&1 || echo undeploy returned non-zero (ignored)
            echo ---- undeploy_out.txt ----
            type undeploy_out.txt
            echo -------------------------

            rem 2) First attempt: use POST multipart form (server allows POST)
            echo === Deploying (POST multipart/form-data) ===
            curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% -F "file=@%WAR%" "http://localhost:8092/manager/text/deploy?path=/BloodBank&update=true" > deploy_out.txt 2>&1
            set RC=%ERRORLEVEL%
            echo Initial deploy curl exit code: %RC%

            if %RC% EQU 0 goto DEPLOY_SUCCESS

            echo initial deploy failed (exit %RC%). Checking manager readiness and will retry up to 12 times...
            set ATTEMPTS=0

            :CHECK_LOOP
              curl -s --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% "http://localhost:8092/manager/text/list" > nul 2>&1
              if %ERRORLEVEL% EQU 0 goto RETRY_DEPLOY
              set /A ATTEMPTS+=1
              if %ATTEMPTS% GEQ 12 goto MANAGER_UNAVAILABLE
              rem wait ~5 seconds without timeout
              ping -n 6 127.0.0.1 > nul
              goto CHECK_LOOP

            :RETRY_DEPLOY
              echo Manager available — retrying deploy (POST form)...
              curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% -F "file=@%WAR%" "http://localhost:8092/manager/text/deploy?path=/BloodBank&update=true" > deploy_out_retry.txt 2>&1
              set RC2=%ERRORLEVEL%
              echo Retry deploy curl exit code: %RC2%
              if %RC2% EQU 0 goto DEPLOY_SUCCESS
              rem print retry output then exit failure
              echo ---- deploy_out_retry.txt ----
              type deploy_out_retry.txt
              echo -------------------------------
              exit /b %RC2%

            :MANAGER_UNAVAILABLE
              echo Tomcat manager did not become available after %ATTEMPTS% attempts.
              echo --- initial deploy output ---
              type deploy_out.txt
              echo -----------------------------
              exit /b 1

            :DEPLOY_SUCCESS
              echo Deploy succeeded.
              echo ---- deploy_out.txt ----
              type deploy_out.txt
              echo -------------------------
              exit /b 0
          """
        }
      }
    }

    stage('Smoke test') {
      steps {
        echo 'Waiting for app to start...'
        // wait ~5s without using timeout
        bat 'ping -n 6 127.0.0.1 >nul'
        // check the main page, fail pipeline if non-200; change port if your Tomcat serves on another port
        bat 'curl -f "http://localhost:13968/BloodBank/index.jsp"'
      }
    }
  }

  post {
    success { echo 'Pipeline succeeded — application deployed.' }
    failure {
      echo 'Pipeline failed — check console output for errors.'
      // optionally: archive the deploy logs for debugging
      archiveArtifacts artifacts: '**/deploy_out*.txt', allowEmptyArchive: true
    }
  }
}
