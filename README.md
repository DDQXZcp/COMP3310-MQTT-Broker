# COMP3310-MQTT-Broker

## Step-by-step Guide to Host MQTT Broker in AWS

### Step 1 - Prepare an EC2 Instance

Launch an EC2 instance 

- OS: Ubuntu 24.04 LTS
- Architecture: ARM
- Instance Type: t4g.small
- Disk: 20GB

You may also need to
- place the instance in a public subnet
- Create/use an SSH Key to access your instance via GitHub CI/CD. (Refer to Step 3)

### Step 2 - Install Docker in EC2 Instance

Install docker in EC2 instance following the official guide. [Docker Installation in Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

You may need to grant docker permission to access API.
```
sudo usermod -aG docker ubuntu
newgrp docker
```

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

You may need to update deploy.yml with your own settings.

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
