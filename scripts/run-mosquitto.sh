#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/mqtt-broker"

MQTT_USERNAME="comp3310"
MQTT_PASSWORD="comp3310"

echo "Preparing Mosquitto folders..."

sudo mkdir -p "$APP_DIR/mosquitto/config"
sudo mkdir -p "$APP_DIR/mosquitto/data"
sudo mkdir -p "$APP_DIR/mosquitto/log"

echo "Writing Mosquitto config..."

sudo tee "$APP_DIR/mosquitto/config/mosquitto.conf" >/dev/null <<'EOF'
persistence true
persistence_location /mosquitto/data/

log_dest stdout

listener 1883
allow_anonymous false
password_file /mosquitto/config/passwords
EOF

echo "Writing docker-compose.yml..."

sudo tee "$APP_DIR/docker-compose.yml" >/dev/null <<'EOF'
services:
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: mosquitto
    restart: unless-stopped
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
EOF

echo "Creating/updating Mosquitto password file..."

sudo rm -f "$APP_DIR/mosquitto/config/passwords"

sudo docker run --rm \
  --user root \
  -v "$APP_DIR/mosquitto/config:/mosquitto/config" \
  eclipse-mosquitto:2 \
  mosquitto_passwd -b -c /mosquitto/config/passwords "$MQTT_USERNAME" "$MQTT_PASSWORD"

echo "Fixing Mosquitto permissions..."

sudo chown -R 1883:1883 "$APP_DIR/mosquitto/data"
sudo chown -R 1883:1883 "$APP_DIR/mosquitto/log"

sudo chmod 644 "$APP_DIR/mosquitto/config/mosquitto.conf"
sudo chmod 644 "$APP_DIR/mosquitto/config/passwords"

echo "Starting Mosquitto..."

cd "$APP_DIR"

sudo docker compose pull
sudo docker compose down || true
sudo docker compose up -d

echo "Mosquitto status:"
sudo docker ps

echo "Mosquitto logs:"
sudo docker logs mosquitto --tail 50