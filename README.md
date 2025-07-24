# Jenkins CI/CD Pipeline: Docker Image Build, ECR Push, and Trivy Scan
The core idea is to automate the process of containerizing an application, securing it by scanning for known vulnerabilities, and publishing it to a cloud-based container registry. This setup is ideal for development and lab environments where rapid iteration and security checks are crucial.




## Architecture

* **Jenkins Server:** Orchestrates the build and deployment process.
* **Jenkins Agent:** Executes the Docker build, ECR push, and Trivy scan commands.
* **AWS ECR:** Securely stores the Docker images.
* **Trivy:** Open-source vulnerability scanner for container images.

## Workthrough Step by psk
### 1. Launch Jenkins Server Instance

* **Instance Type:** `t2.small`
* **Operating System:** i use `Ubuntu`
* **Security Group:** Configure inbound rules to allow allow ports `22` (SSH) and `8080` (Jenkins UI).

### 2. Launch Jenkins Agent Instance

* **Instance Type:** `t2.medium`
* **Operating System:** i use `Ubuntu`
* **Security Group:** Configure inbound rules to allow ports `22` (SSH).


### 3. Install Java and Jenkins

**On Jenkins Server and Jenkins Agent:**

* **Install Java:** `sudo apt update
sudo apt install fontconfig openjdk-21-jre`
* **Install Jenkins:** `sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins`


### 5. Access Jenkins and Install Recommended Plugins
Open your web browser and navigate to http://<Jenkins_Server_Public_IP>:8080.
Follow the on-screen instructions to unlock Jenkins (retrieve the initial admin password from /var/lib/jenkins/secrets/initialAdminPassword on the Jenkins server).

Choose "Install suggested plugins."

* **On Jenkins Agent:** Generate an SSH key pair `ssh-keygen`
- navigate to /home/ubuntu/secrets/.ssh/<your key>
- copy the public key and paste into authorized key.
- copy the private key.

* **In Jenkins UI:**
- Navigate to Dashboard -> Manage Jenkins -> Manage Credentials.
- Click on (global) -> Add Credentials.
- Select Kind: SSH Username with private key.
- Set Scope: Global.
- Enter the Username: of the user on your Jenkins agent, for me `ubuntu`.
- For Private Key: Select Enter directly and paste the private key copied from the agent.
- Click OK.

### 6. Add Jenkins Agent Node
Now, connect your agent to the Jenkins server.
- Manage Jenkins -> Manage Nodes and Clouds.
- Click New Node.
- *Enter a Node name:* jenkins-agent-1 (or a descriptive name).
- Select Permanent Agent and click OK.

* **Configure the node details:**
- *Number of executors:* 1 
- *Remote root directory:* `/home/ubuntu/jenkins_workspace`
- *Labels:* I use `important` (This label is crucial as it will be used in your Jenkinsfile).
- *Launch method:* Launch agents via SSH.
- *Host:* Enter the Private IP address of your Jenkins Agent instance.
- *Credentials:* Select the SSH credential you created in the previous step (jenkins-agent-ssh).
- Host Key Verification Strategy: For a lab environment, select Non verifying Verification Strategy.
Click Save.

### 7. Install unzip, awscli2 on Jenkins Agent and Assign iam Role to EC2
The agent needs the AWS CLI to interact with ECR and unzip to install it.

* **On Jenkins Agent:**

*Installing unzip:* `sudo apt install unzip -y`
*Installing AWS CLI:* Use this command one by one `curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws`

* **Create an IAM Policy:**

- Navigate to Policies -> Create policy.
- Choose the JSON tab and paste the [policy](      github repo link)
- Name the policy (e.g., JenkinsECRFullAccessPolicy) and create it.

* **Create an IAM Role:**

- Go to Roles -> Create role.
- For Trusted entity type, select `AWS service`
- For Use case, select EC2, then click Next.
- In the Add permissions section, search for and attach the JenkinsECRFullAccessPolicy you just created. 
- Name the role (e.g., JenkinsAgentECRRole) and create it.

* **Attach the IAM Role to your Jenkins Agent EC2 Instance:**

- Go to the EC2 console.
- Select your running Jenkins Agent instance.
- Choose Actions -> Security -> Modify IAM role.
- Select the JenkinsAgentECRRole from the dropdown list.
- Click Update IAM role.

Groovy

pipeline {
    agent { label 'docker-builder' } // Use the label we defined for the agent

    environment {
        AWS_ACCOUNT_ID = '<YOUR_AWS_ACCOUNT_ID>'
        AWS_REGION = '<YOUR_AWS_REGION>'
        ECR_REPO_NAME = '<YOUR_ECR_REPO_NAME>'
        DOCKER_IMAGE_NAME = '<YOUR_DOCKER_IMAGE_NAME>'
        DOCKER_IMAGE_TAG = 'latest'
        ECR_REPO_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}[.amazonaws.com/$](https://.amazonaws.com/$){ECR_REPO_NAME}"
        TRIVY_REPORT_FILE = 'trivy_scan_report.txt'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: '[https://github.com/your-username/your-repo.git](https://github.com/your-username/your-repo.git)' // Replace with your repo
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
                    echo "Docker image built: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    echo "Logged into ECR."
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${ECR_REPO_URI}:${DOCKER_IMAGE_TAG}"
                    echo "Docker image tagged: ${ECR_REPO_URI}:${DOCKER_IMAGE_TAG}"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh "docker push ${ECR_REPO_URI}:${DOCKER_IMAGE_TAG}"
                    echo "Docker image pushed to ECR: ${ECR_REPO_URI}:${DOCKER_IMAGE_TAG}"
                }
            }
        }

        stage('Scan with Trivy') {
            steps {
                script {
                    // Install Trivy if not already installed (this ensures the agent always has Trivy)
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Trivy not found, installing..."
                            sudo apt-get update
                            sudo apt-get install -y wget apt-transport-https gnupg
                            wget -qO - [https://aquasecurity.github.io/trivy-repo/deb/public.key](https://aquasecurity.github.io/trivy-repo/deb/public.key) | sudo apt-key add -
                            echo deb [https://aquasecurity.github.io/trivy-repo/deb](https://aquasecurity.github.io/trivy-repo/deb) stable main | sudo tee /etc/apt/sources.list.d/trivy.list
                            sudo apt-get update
                            sudo apt-get install -y trivy
                        else
                            echo "Trivy is already installed."
                        fi
                    '''
                    // Perform the scan and save output to a file
                    sh "trivy image --severity HIGH,CRITICAL --format json ${ECR_REPO_URI}:${DOCKER_IMAGE_TAG} > ${TRIVY_REPORT_FILE}"
                    echo "Trivy scan completed. Report saved to ${TRIVY_REPORT_FILE}"
                }
            }
        }

        stage('Process Trivy Report') {
            steps {
                script {
                    def trivyOutput = sh(script: "cat ${TRIVY_REPORT_FILE}", returnStdout: true).trim()

                    // For direct display in README, we'll output the raw JSON.
                    // In a production setup, you might parse this into a more readable Markdown table.
                    writeFile file: 'trivy_report_for_readme.md', text: """
### Trivy Scan Results for Image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

\`\`\`json
${trivyOutput}
\`\`\`
"""
                    echo "Trivy scan report for README.md generated."
                }
            }
            post {
                always {
                    // Archive the Trivy report for later inspection
                    archiveArtifacts artifacts: "${TRIVY_REPORT_FILE}"
                    // This will also make the trivy_report_for_readme.md available for download from Jenkins
                    archiveArtifacts artifacts: "trivy_report_for_readme.md"
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Clean up workspace after build
        }
        success {
            echo 'Pipeline finished successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
10. Set Up a New Jenkins Item
Configure Jenkins to use your Jenkinsfile from GitHub.

Go to Dashboard -> New Item.

Enter an Item name (e.g., Docker-ECR-Trivy-Pipeline).

Select Pipeline and click OK.

In the pipeline configuration:

Definition: Pipeline script from SCM

SCM: Git

Repository URL: Your GitHub repository URL (e.g., https://github.com/your-username/your-repo.git)

Credentials: If your repo is private, add GitHub credentials.

Branches to build: */main (ensure you use main if that's your default branch, rather than master).

Script Path: Jenkinsfile (assuming your Jenkinsfile is in the root of your repository).

Click Save.

11. Trigger the Build!
Now, kick off your pipeline and watch the magic happen.

On the Jenkins item page for your pipeline, click Build Now in the left sidebar.

Monitor the build progress in the Build History.

Click on a specific build number, then Console Output to see the detailed logs, including the raw Trivy scan results. You can also check the Artifacts section for the generated trivy_report_for_readme.md file.

Trivy Scan Output
This section will display the vulnerability scan results for your Docker image. After a successful Jenkins build, copy the content from the trivy_report_for_readme.md artifact (or directly from the Jenkins console output in the "Process Trivy Report" stage) and paste it here.

JSON

{
  "SchemaVersion": 2,
  "ArtifactName": "YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_AWS_[REGION.amazonaws.com/YOUR_ECR_REPO_NAME:latest](https://REGION.amazonaws.com/YOUR_ECR_REPO_NAME:latest)",
  "ArtifactType": "container_image",
  "Metadata": {
    "ImageID": "sha256:...",
    "OS": {
      "Family": "ubuntu",
      "Name": "22.04"
    }
  },
  "Results": [
    {
      "Target": "your_image_layer",
      "Class": "os-package",
      "Type": "debian",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-XXXX-XXXX",
          "PkgName": "libssl3",
          "InstalledVersion": "3.0.x-y",
          "FixedVersion": "3.0.x-z",
          "Severity": "HIGH",
          "Description": "OpenSSL vulnerability...",
          "References": [
            "[https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXX](https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXX)"
          ]
        },
        {
          "VulnerabilityID": "CVE-YYYY-YYYY",
          "PkgName": "curl",
          "InstalledVersion": "7.81.0-1ubuntu1.11",
          "FixedVersion": "7.81.0-1ubuntu1.12",
          "Severity": "CRITICAL",
          "Description": "Curl vulnerability...",
          "References": [
            "[https://nvd.nist.gov/vuln/detail/CVE-YYYY-YYYY](https://nvd.nist.gov/vuln/detail/CVE-YYYY-YYYY)"
          ]
        }
      ]
    }
    // ... more scan results will appear here ...
  ]
}
Next Steps
Implement Webhooks: Configure a GitHub webhook to automatically trigger Jenkins builds whenever code is pushed to your repository.

Notifications: Set up email or Slack notifications for build status changes (success/failure).

Automated README Update: Explore ways to automate the update of this README.md with the latest Trivy scan results directly from the Jenkins pipeline (e.g., using GitHub API).

Security Best Practices:

Transition from direct AWS credentials to IAM roles for EC2 instances for enhanced security.

Restrict security group inbound rules to the absolute minimum necessary for your environment.

Regularly update Jenkins, its plugins, and all software installed on both the server and agent.

Implement Trivy policies to fail builds if critical vulnerabilities are discovered, enforcing a secure pipeline.

Clean Up: Remember to terminate your EC2 instances 
