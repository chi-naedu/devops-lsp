pipeline {
    agent any

    tools {
        nodejs 'node20'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        VENV_HOME = "${WORKSPACE}/venv"
        // REPLACE THIS with your actual ECR URL from Terraform Output
        // Example: 123456789.dkr.ecr.eu-west-2.amazonaws.com
        ECR_REGISTRY = '484336990036.dkr.ecr.eu-west-2.amazonaws.com' 
        AWS_REGION = 'eu-west-2'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Install Backend Deps') {
            steps {
                dir('backend') {
                    sh '''
                        python3 -m venv ${VENV_HOME}
                        . ${VENV_HOME}/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install && npm run build'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
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

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    // This logs Docker into AWS ECR so we can push images
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Build & Push Images') {
            steps {
                script {
                    // 1. Build & Push Backend
                    sh """
                        docker build -t ${ECR_REGISTRY}/linksnap-backend:latest ./backend
                        docker push ${ECR_REGISTRY}/linksnap-backend:latest
                    """
                    
                    // 2. Build & Push Frontend
                    sh """
                        docker build -t ${ECR_REGISTRY}/linksnap-frontend:latest ./frontend
                        docker push ${ECR_REGISTRY}/linksnap-frontend:latest
                    """
                }
            }
        }
    }
}