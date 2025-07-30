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
                    sh ''' // Get the ECR login password. When an IAM role is attached to the EC2 instance,
                    // the AWS CLI automatically uses the credentials from that role.
                    // No need for --profile or explicit credentials.
                    def ecrPassword = sh(script: 'aws ecr get-login-password', returnStdout: true).trim()

                    // Use the obtained password to perform a non-interactive docker login.
                    // This is robust against "non TTY device" errors.
                    sh "echo '${ecrPassword}' | docker login --username AWS --password-stdin 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork"

                    // Tag the locally built Docker image with the ECR repository URI.
                    sh "docker tag dojo:latest 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest"

                    // Push the tagged Docker image to the ECR repository.
                    sh "docker push 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest"'''
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
        }
        stage('testing') {
            steps {
                echo 'bravo'
            }
        }
    }
}
