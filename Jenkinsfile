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
            setlocal enabledelayedexpansion
            set WAR=%WORKSPACE%\\dist\\BloodBank.war
            echo === Undeploying previous app (if exists) ===
            rem we capture output to undeploy_out.txt for debugging; ignore non-zero (app might not exist)
            curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% "http://localhost:8092/manager/text/undeploy?path=/BloodBank" > undeploy_out.txt 2>&1 || echo "undeploy ignored (see undeploy_out.txt)"
            echo --- undeploy output (first 200 lines) ---
            for /f "tokens=1* delims=:" %%A in ('powershell -Command "Get-Content undeploy_out.txt -TotalCount 200"') do @echo %%A:%%B
            echo ----------------------------------------

            echo === Deploying new WAR ===
            rem first attempt (capture verbose output)
            curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% -T "%WAR%" "http://localhost:8092/manager/text/deploy?path=/BloodBank&update=true" > deploy_out.txt 2>&1
            set RC=%ERRORLEVEL%
            echo --- initial deploy curl exit code: !RC! ---
            type deploy_out.txt || echo "(no deploy output)"

            if !RC! EQU 0 (
              echo Initial deploy failed. Polling Tomcat manager (max attempts) and will retry.
              set ATTEMPTS=0
              :WAIT_LOOP
                rem check manager text endpoint (quiet)
                curl -s --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% "http://localhost:8092/manager/text/list" > nul 2>&1
                if !ERRORLEVEL! EQU 0 (
                  set /A ATTEMPTS+=1
                  if !ATTEMPTS! GEQ 12 (
                    echo Tomcat manager did not become available after !ATTEMPTS! attempts.
                    echo Showing last deploy output:
                    type deploy_out.txt
                    exit /b 1
                  )
                  rem wait ~5s using ping (works in non-interactive shells)
                  ping -n 6 127.0.0.1 >nul
                  goto WAIT_LOOP
                )

              echo Manager is up — retrying deploy now...
              curl -v --http1.1 -u %TOMCAT_USER%:%TOMCAT_PASS% -T "%WAR%" "http://localhost:8092/manager/text/deploy?path=/BloodBank&update=true" > deploy_out_retry.txt 2>&1
              set RC2=%ERRORLEVEL%
              echo --- retry deploy curl exit code: !RC2! ---
              type deploy_out_retry.txt || echo "(no retry output)"
              exit /b !RC2!
            ) else (
              echo Deploy succeeded on first attempt.
              exit /b 0
            )
          """
        }
      }
    }

    stage('Smoke test') {
      steps {
        echo 'Waiting for app to start...'
        // wait ~5s without using timeout
        bat 'ping -n 6 127.0.0.1 >nul'
        // check the main page, fail pipeline if non-200; use --silent to reduce output but -f to fail on HTTP error
        bat 'curl -f "http://localhost:8091/BloodBank/index.jsp"'
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
