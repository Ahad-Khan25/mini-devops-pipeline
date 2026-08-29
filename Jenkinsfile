pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('dockerhub-creds')
        IMAGE_NAME = "ahadkhanx25/mini-devops-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EC2_HOST = "ubuntu@3.81.118.187"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    try {
                        sh """
                            docker rm -f test-container-${BUILD_NUMBER} || true
                            docker run -d --name test-container-${BUILD_NUMBER} ${IMAGE_NAME}:${IMAGE_TAG}
                            sleep 5
                            docker exec test-container-${BUILD_NUMBER} python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
                        """
                    } finally {
                        sh "docker stop test-container-${BUILD_NUMBER} || true"
                        sh "docker rm test-container-${BUILD_NUMBER} || true"
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDS_PSW" | docker login -u "$DOCKERHUB_CREDS_USR" --password-stdin
                    docker push "$IMAGE_NAME:$IMAGE_TAG"
                    docker push "$IMAGE_NAME:latest"
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_HOST} '
                            docker pull ${IMAGE_NAME}:${IMAGE_TAG} &&
                            docker stop mini-app || true &&
                            docker rm mini-app || true &&
                            docker run -d --name mini-app --restart unless-stopped -p 5000:5000 ${IMAGE_NAME}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh "sleep 5"
                sh "curl -f http://3.81.118.187/health"
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded — deployed ${IMAGE_NAME}:${IMAGE_TAG} to EC2"
        }
        failure {
            echo "Pipeline failed — check logs above"
        }
        always {
            sh "docker logout || true"
        }
    }
}
