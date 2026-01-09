pipeline {
    agent {
        kubernetes {
            serviceAccount 'jenkins'
            yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                app: jenkins-agent
            spec:
              containers:
              # 1. THE AGENT ITSELF (Crucial to limit this!)
              - name: jnlp
                image: jenkins/inbound-agent:3148.v532a_7e715ee3-1
                resources:
                  requests:
                    memory: "128Mi"  # <--- Lowered to fit in your cluster
                    cpu: "100m"

              # 2. BUILDER (Kaniko)
              - name: kaniko
                image: gcr.io/kaniko-project/executor:v1.14.0-debug
                command:
                - /busybox/cat
                tty: true
                volumeMounts:
                  - name: docker-config
                    mountPath: /kaniko/.docker
                resources:
                  requests:
                    memory: "256Mi"  # <--- Lowered significantly
                    cpu: "250m"

              # 3. DEPLOYER (Kubectl)
              - name: kubectl
                image: dtzar/helm-kubectl:latest
                command:
                - cat
                tty: true
                resources:
                  requests:
                    memory: "64Mi"   # <--- Very tiny footprint
                    cpu: "50m"

              # 4. QUALITY SCANNER (New!)
              # Use a container for this so we don't worry about install paths
              - name: sonar
                image: sonarsource/sonar-scanner-cli:latest
                command:
                - cat
                tty: true
                resources:
                  requests:
                    memory: "128Mi"
                    cpu: "100m"

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

        // MOVED UP: Fail fast if code quality is bad!
        stage('SonarQube Analysis') {
            steps {
                container('sonar') {
                    withSonarQubeEnv('sonarqube-server') {
                        // The scanner is already in the path in this image!
                        sh """
                        sonar-scanner \
                        -Dsonar.projectKey=linksnap-backend \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000/sonarqube \
                        -Dsonar.login=$SONAR_AUTH_TOKEN
                        """
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build & Push Images') {
            steps {
                container('kaniko') {
                    // Create a config.json for Kaniko to authenticate with ECR
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
                    // Apply Manifests
                    sh "kubectl apply -f k8s/backend-deployment.yaml"
                    sh "kubectl apply -f k8s/backend-service.yaml"
                    sh "kubectl apply -f k8s/frontend-deployment.yaml"
                    sh "kubectl apply -f k8s/frontend-service.yaml"
                    sh "kubectl apply -f k8s/ingress.yaml"
                    // Force Restart to pick up new images
                    sh "kubectl rollout restart deployment/backend"
                    sh "kubectl rollout restart deployment/frontend"
                }
            }
        } 
    }   
}