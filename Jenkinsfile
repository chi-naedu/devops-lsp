pipeline {
    agent any

    tools {
        nodejs 'node20'  // Uses the tool we just configured
        // We don't need a specific Python tool; the server's default python3 is sufficient.
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        VENV_HOME = "${WORKSPACE}/venv"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Backend Deps (Flask)') {
            steps {
                dir('backend') {
                    sh '''
                        echo "--- Setting up Python Virtual Env ---"
                        python3 -m venv ${VENV_HOME}
                        . ${VENV_HOME}/bin/activate
                        
                        echo "--- Installing Flask Requirements ---"
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Build Frontend (React)') {
            steps {
                dir('frontend') {
                    sh '''
                        echo "--- Installing Node Modules ---"
                        npm install
                        
                        echo "--- Building React App ---"
                        npm run build
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    // We scan the root (.) but exclude the heavy folders
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=linksnap-monorepo \
                        -Dsonar.projectName="LinkSnap Platform" \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=**/node_modules/**,**/venv/**,**/.git/**,**/build/** \
                        -Dsonar.python.version=3
                    """
                }
            }
        }
        stage("Quality Gate") {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    // This pauses the pipeline until SonarQube sends the webhook back
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}