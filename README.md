# COMP3310-MQTT-Broker

## Quick Guide to Spin Up MQTT Broker in AWS

### Step 1 - Create a VPC with a Public Subnet

Go to VPC Page, and create a VPC with one Public Subnet.

- Number of AZ = 1
- Number of Public Subnet = 1
- IPv6 (No need)
- Private Subnet (No need) 
- NAT Gateway (No need)

### Step 2 - Prepare an EC2 Instance

**Step 2.1 - Launch an EC2 instance 

- OS: Ubuntu 24.04 LTS
- Architecture: ARM
- Instance Type: t3.micro
- Disk: 20GB

You may also need to
- place the instance in a public subnet
- Create/use an SSH Key to access your instance.

Put this into user data script
```
#!/bin/bash
# Update the package repository
sudo apt-get update -y

# Install necessary packages for Docker
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update the package repository again
sudo apt-get update -y

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the ubuntu user to the docker group to allow non-root usage
sudo usermod -aG docker ubuntu

# Restart the Docker service to apply group changes
sudo systemctl restart docker

# Pull the Mosquitto Docker image
sudo docker pull eclipse-mosquitto:latest

# Create a Mosquitto configuration directory
sudo mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log

# Create a default Mosquitto configuration file
cat <<EOF | sudo tee /mosquitto/config/mosquitto.conf
# Default Mosquitto configuration
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

# Run the Mosquitto container
sudo docker run -d --name mosquitto \
  -p 1883:1883 -p 9001:9001 \
  -v /mosquitto/config:/mosquitto/config \
  -v /mosquitto/data:/mosquitto/data \
  -v /mosquitto/log:/mosquitto/log \
  eclipse-mosquitto:latest

# Ensure the Docker container restarts automatically on reboot
sudo docker update --restart always mosquitto
```

Now you should be able to check if the mosquitto broker is running by
```
docker ps
```

## Advanced Configuration (Optional)

### Step 2 - Install Docker in EC2 Instance

If anything failed in previous steps or you wish to install docker manually. Please follow the official installation guide. [Docker Installation in Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

You may need to grant docker permission to access API.
```
sudo usermod -aG docker ubuntu
newgrp docker
```
If you see anything wrong such as docker not running or docker permission error, it might be because the script is still running. Log out, Wait for a while and log back in again.

### Step 3 - Upload EC2 SSH Key to Github Secret

In this repository I use GitHub Secret to store my SSH Key

1. Go to **Settings --> Secrets and Variables --> Actions --> Repository secrets**
2. Create a secret **"EC2_SSH_KEY"** and copy-paste the key content to the value part.

The content is in this format, make sure you copy everything.
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

### Step 4 - Deploy Mosquitto Broker in EC2 Instance

You may need to update deploy.yml with your own settings. The code also specify the username and password.

```
env:
  EC2_HOST: 52.63.194.183 # Replace with your EC2 instance's public IP or hostname
  EC2_USER: ubuntu
  REMOTE_SCRIPT_PATH: /tmp/run-mosquitto.sh
```
When you modify this file and push to the remote repo, this CI/CD workflow will trigger automatically and deploy to the EC2 instance.

If the broker is launched successfully, it should looks like this
```
ubuntu@ip-10-0-6-102:~$ docker ps
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS              PORTS                                         NAMES
5dbc46d678b8   eclipse-mosquitto:2   "/docker-entrypoint.…"   15 minutes ago   Up About a minute   0.0.0.0:1883->1883/tcp, [::]:1883->1883/tcp   mosquitto
```

### Step 5 - Connect to the Broker

Try to connect to the broker by specifying

- Public IP address: 52.63.194.183
- Port: 1883
- Username: comp3310
- Password: comp3310

## Scaling Option

### t4g.small

- Connected clients: 500–2,000 clients
- Light traffic: 1,000–5,000 messages/second

## Connect to the broker using pytho script

### Step 1 - Create a virtual environment

```
python3 -m venv mqtt_env
source mqtt_env/bin/activate
pip install paho-mqtt
```

### Step 2 - Run the test python script

```
python publisher.py
```

### Step 3 - Monitor the result in MQTT-Explorer
