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

### 3. Configure Security Group Inbound Rules

* **For Lab Environment (All Traffic):**
    * **Type:** All Traffic
    * **Protocol:** All
    * **Port Range:** All
    * **Source:** 0.0.0.0/0 (for quick setup)
* **For Restricted Access:**
    * **SSH (Port 22):** For administrative access.
    * **Jenkins UI (Port 8080):** For accessing the Jenkins web interface on the server.
    * **Jenkins Agent (Port 8000 or 22):** Depending on your agent connection method (JNLP or SSH).

### 4. Install Java and Jenkins

**On Jenkins Server:**

```bash
# Example for Ubuntu
sudo apt update
sudo apt install openjdk-11-jdk -y
wget -q -O - [https://pkg.jenkins.io/debian-stable/jenkins.io.key](https://pkg.jenkins.io/debian-stable/jenkins.io.key) | sudo apt-key add -
sudo sh -c 'echo deb [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
