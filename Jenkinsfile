pipeline {
    agent {
        kubernetes {
            serviceAccount 'jenkins'
            // This YAML defines the "Build Agent" that spins up just for this job
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              # 1. Container to build Docker Images (using Kaniko, the K8s standard)
              - name: kaniko
                image: gcr.io/kaniko-project/executor:v1.14.0-debug
                command:
                - /busybox/cat
                tty: true
                volumeMounts:
                  - name: docker-config
                    mountPath: /kaniko/.docker
              # 2. Container to run Kubectl commands
              - name: kubectl
                # This image is built for CI/CD: runs as root, has sh/bash/helm/kubectl
                image: dtzar/helm-kubectl:latest
                command:
                - cat
                tty: true
              volumes:
                - name: docker-config
                  emptyDir: {}
            '''
        }
    }

    environment {
        // REPLACE with your ECR URL
        ECR_REGISTRY = '484336990036.dkr.ecr.eu-west-2.amazonaws.com' 
        AWS_REGION = 'eu-west-2'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // Note: For simplicity in this K8s migration, we are skipping the 
        // Python/Node install stages. Kaniko handles the build directly from the Dockerfile.

        stage('Build & Push Images') {
            steps {
                container('kaniko') {
                    // Create a config.json for Kaniko to authenticate with ECR
                    // This uses the Node's IAM Role automatically!
                    sh '''
                        echo "{\\"credsStore\\":\\"ecr-login\\"}" > /kaniko/.docker/config.json
                    '''

                    // Build Backend
                    sh """
                        /kaniko/executor --context `pwd`/backend \
                        --dockerfile `pwd`/backend/Dockerfile \
                        --destination ${ECR_REGISTRY}/linksnap-backend:latest
                    """

                    // Build Frontend
                    sh """
                        /kaniko/executor --context `pwd`/frontend \
                        --dockerfile `pwd`/frontend/Dockerfile \
                        --destination ${ECR_REGISTRY}/linksnap-frontend:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                container('kubectl') {
                    // No login needed! It uses the Service Account.
                    
                    // Apply Manifests
                    sh "kubectl apply -f k8s/backend-deployment.yaml"
                    sh "kubectl apply -f k8s/backend-service.yaml"
                    sh "kubectl apply -f k8s/frontend-deployment.yaml"
                    sh "kubectl apply -f k8s/frontend-service.yaml"
                    sh "kubectl apply -f k8s/ingress.yaml"
                    // Force Restart
                    sh "kubectl rollout restart deployment/backend"
                    sh "kubectl rollout restart deployment/frontend"
                }
            }
        }
    }
}