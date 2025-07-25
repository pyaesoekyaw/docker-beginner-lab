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

* **Install Java:** `sudo apt update`
                    `sudo apt install fontconfig openjdk-21-jre`
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

**On Jenkins Agent:** Generate an SSH key pair `ssh-keygen`
- navigate to /home/ubuntu/secrets/.ssh/<your key>
- copy the public key and paste into authorized key.
- copy the private key.

**In Jenkins UI:**
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
**Configure the node details:**
- *Number of executors:* 1 
- *Remote root directory:* `/home/ubuntu/jenkins_workspace`
- *Labels:* I use `important` (This label is crucial as it will be used in your Jenkinsfile).
- *Launch method:* Launch agents via SSH.
- *Host:* Enter the Private IP address of your Jenkins Agent instance.
- *Credentials:* Select the SSH credential you created in the previous step (jenkins-agent-ssh).
- Host Key Verification Strategy: For a lab environment, select Non verifying Verification Strategy.
Click Save.

### 7. Install unzip, awscli2, Trivy on Jenkins Agent and Assign iam Role to EC2
The agent needs the AWS CLI to interact with ECR and unzip to install it.

**On Jenkins Agent:**

*Installing unzip:* `sudo apt install unzip -y`
*Installing AWS CLI:* Use this command one by one `curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws`

**Install Trivy:**
`sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy`


**Create an IAM Policy:**

- Navigate to *Policies* -> Create policy.
- Choose the JSON tab and paste the [policy](      github repo link)
- Name the policy (e.g., JenkinsECRFullAccessPolicy) and create it.

**Create an IAM Role:**

- Go to Roles -> Create role.
- For Trusted entity type, select `AWS service`
- For Use case, select EC2, then click Next.
- In the Add permissions section, search for and attach the JenkinsECRFullAccessPolicy you just created. 
- Name the role (e.g., JenkinsAgentECRRole) and create it.

**Attach the IAM Role to your Jenkins Agent EC2 Instance:**

- Go to the EC2 console.
- Select your running Jenkins Agent instance.
- Choose **Actions -> Security -> Modify IAM role.**
- Select the **JenkinsAgentECRRole** from the dropdown list.
- Click **Update IAM role**.


### 8. Set Up a New Jenkins Item
- Configure Jenkins to use your Jenkinsfile from GitHub.
- Go to Dashboard -> **New Item.**
- Enter an Item name (e.g., DockerPipeline).
- Select Pipeline and click OK.
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: https://github.com/your-username/your-repo.git
- Branches to build: */main 
- Script Path: Jenkinsfile 
**Click Save.**

11. Trigger the Build!
Now, kick off your pipeline and watch the magic happen.

On the Jenkins item page for your pipeline, click Build Now in the left sidebar.

Monitor the build progress in the Build History.


