pipeline {
    agent { label 'important' } // Your existing agent label

    stages {
        stage('Build') {
            steps {
                script {
                    sh 'sudo docker build -t dojo .'
                }
            }
        }
        stage('push') {
            steps {
                script {
                    sh '''aws ecr get-login-password --profile "branch" | docker login --username AWS --password-stdin 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork
                    docker tag dojo:latest 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest
                    docker push 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest'''
                }
            }
        }
        // New stage for Trivy scanning
        stage('Scan with Trivy') {
            steps {
                script {
                   sh 'trivy image dojo'
                }
            }
       
        stage('testing') {
            steps {
                echo 'bravo'
            }
        }
    }
}
