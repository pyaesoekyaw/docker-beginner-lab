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
                    sh '''aws ecr get-login-password | docker login --username AWS --password-stdin 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork
                    docker tag dojo:latest 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest
                    docker push 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest'''
                }
            }
        }
        // New stage for Trivy scanning
        stage('Scan with Trivy') {
            steps {
                script {
                    // Define image details directly within this stage, based on your push stage
                    def ecrRepoUri = "842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest"
                    def trivyReportFile = 'trivy_scan_report.txt'

                    // Perform the Trivy scan.
                    // Assuming Trivy is manually installed on the agent.
                    // Scans the image that was just pushed to ECR.
                    // Output is in JSON format for easy parsing and includes HIGH and CRITICAL severities.
                    sh "trivy image --severity HIGH,CRITICAL --format json ${ecrRepoUri} > ${trivyReportFile}"
                    echo "Trivy scan completed. Report saved to ${trivyReportFile}"
                }
            }
            post {
                // This 'post' block runs after the 'Scan with Trivy' stage, regardless of success/failure.
                always {
                    // Archive the raw Trivy report for later inspection in Jenkins artifacts.
                    archiveArtifacts artifacts: trivyReportFile

                    // Generate a markdown-formatted report suitable for direct pasting into README.md.
                    // This reads the JSON output and wraps it in a Markdown code block.
                    writeFile file: 'trivy_report_for_readme.md', text: """
### Trivy Scan Results for Image: 842675988267.dkr.ecr.us-east-1.amazonaws.com/mywork:latest

\`\`\`json
${sh(script: "cat ${trivyReportFile}", returnStdout: true).trim()}
\`\`\`
"""
                    // Archive the markdown-formatted report as well.
                    archiveArtifacts artifacts: 'trivy_report_for_readme.md'
                    echo "Trivy scan report for README.md generated and archived."
                }
            }
        }
        stage('testing') {
            steps {
                echo 'bravo'
            }
        }
    }
    // Global post actions for the entire pipeline
    post {
        always {
            cleanWs() // Clean up the workspace on the agent after the build
        }
        success {
            echo 'Pipeline finished successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
