pipeline {
    agent any

    tools {
        nodejs 'node20'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        VENV_HOME = "${WORKSPACE}/venv"
        
        // --- CONFIGURATION ---
        ECR_REGISTRY = '484336990036.dkr.ecr.eu-west-2.amazonaws.com' 
        AWS_REGION = 'eu-west-2'
        
        // REPLACE THIS with your actual EKS Cluster Name (from Terraform/AWS Console)
        EKS_CLUSTER_NAME = 'linksnap-cluster' 
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
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Build & Push Images') {
            steps {
                script {
                    // Note: No --platform flag needed here because Jenkins is running on Linux!
                    
                    // 1. Backend
                    sh """
                        docker build -t ${ECR_REGISTRY}/linksnap-backend:latest ./backend
                        docker push ${ECR_REGISTRY}/linksnap-backend:latest
                    """
                    
                    // 2. Frontend
                    sh """
                        docker build -t ${ECR_REGISTRY}/linksnap-frontend:latest ./frontend
                        docker push ${ECR_REGISTRY}/linksnap-frontend:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // 1. Update kubeconfig so Jenkins can talk to the cluster
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"

                    // 2. Apply Kubernetes Manifests
                    // Assumes your yaml files are in the root of the repo. 
                    // If they are in a folder, use: kubectl apply -f k8s/
                    sh "kubectl apply -f backend-deployment.yaml"
                    sh "kubectl apply -f backend-service.yaml"
                    sh "kubectl apply -f frontend-deployment.yaml"
                    sh "kubectl apply -f frontend-service.yaml"
                    
                    // Only apply ingress if you haven't already, or if it changed
                    sh "kubectl apply -f ingress.yaml"

                    // 3. Force Rollout Restart
                    // This ensures pods pull the new 'latest' image we just pushed
                    sh "kubectl rollout restart deployment/backend"
                    sh "kubectl rollout restart deployment/frontend"
                }
            }
        }
    }
}