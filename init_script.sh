#!/bin/sh
# This script will write all of your configurations to /opt/livekit.
# It'll also install LiveKit as a systemd service that will run at startup
# LiveKit will be started automatically at machine startup.

# create directories for LiveKit
mkdir -p /opt/livekit/caddy_data
mkdir -p /usr/local/bin

# Docker & Docker Compose will need to be installed on the machine
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose

sudo systemctl enable docker

# livekit config
cat << EOF > /opt/livekit/livekit.yaml
port: 7880
bind_addresses:
    - ""
rtc:
    tcp_port: 7881
    port_range_start: 50000
    port_range_end: 60000
    use_external_ip: true
    enable_loopback_candidate: false
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
turn:
    enabled: true
    domain: livekit-turn.myhost.com
    tls_port: 5349
    udp_port: 3478
    external_tls: true
ingress:
    rtmp_base_url: rtmp://livekit.myhost.com:1935/x
    whip_base_url: https://livekit-whip.myhost.com/w
keys:
    APIVg6jLoiMwFHp: O7CKx1ptmrBOtM6bMePQq0derknyE5jbjnYXlRm4oG0


EOF

# caddy config
cat << EOF > /opt/livekit/caddy.yaml
logging:
  logs:
    default:
      level: INFO
storage:
  "module": "file_system"
  "root": "/data"
apps:
  tls:
    certificates:
      automate:
        - "*.myhost.com"
    automation:
      policies:
        - issuers:
            - module: acme
              challenges:
                dns:
                  provider:
                    name: acmedns
                    config_file_path: /etc/acme-dns-cred.json
  layer4:
    servers:
      main:
        listen: [":443"]
        routes:
          - match:
            - tls:
                sni:
                  - "livekit-turn.myhost.com"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:5349"]
          - match:
              - tls:
                  sni:
                    - "livekit.myhost.com"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: ["http/1.1"]
              - handler: proxy
                upstreams:
                  - dial: ["localhost:7880"]
          - match:
              - tls:
                  sni:
                    - "livekit-whip.myhost.com"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: ["http/1.1"]
              - handler: proxy
                upstreams:
                  - dial: ["localhost:8080"]


EOF

# update ip script
cat << "EOF" > /opt/livekit/update_ip.sh
#!/usr/bin/env bash
ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
sed -i.orig -r "s/\\\"(.+)(\:5349)/\\\"$ip\2/" /opt/livekit/caddy.yaml


EOF

# docker compose
cat << EOF > /opt/livekit/docker-compose.yaml
# This docker-compose requires host networking, which is only available on Linux
# This compose will not function correctly on Mac or Windows
services:
  caddy:
    image: anguzo/caddyl4-acmedns:2.6.4
    command: run --config /etc/caddy.yaml --adapter yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml
      - ./caddy_data:/data
      - ./acme-dns-cred.json:/etc/acme-dns-cred.json
  livekit:
    image: livekit/livekit-server:latest
    command: --config /etc/livekit.yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml
  redis:
    image: redis:7-alpine
    command: redis-server /etc/redis.conf
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./redis.conf:/etc/redis.conf
  ingress:
    image: livekit/ingress:latest
    restart: unless-stopped
    environment:
      - INGRESS_CONFIG_FILE=/etc/ingress.yaml
    network_mode: "host"
    volumes:
      - ./ingress.yaml:/etc/ingress.yaml


EOF

# systemd file
cat << EOF > /etc/systemd/system/livekit-docker.service
[Unit]
Description=LiveKit Server Container
After=docker.service
Requires=docker.service

[Service]
LimitNOFILE=500000
Restart=always
WorkingDirectory=/opt/livekit
# Shutdown container (if running) when unit is started
ExecStartPre=/usr/local/bin/docker-compose -f docker-compose.yaml down
ExecStart=/usr/local/bin/docker-compose -f docker-compose.yaml up
ExecStop=/usr/local/bin/docker-compose -f docker-compose.yaml down

[Install]
WantedBy=multi-user.target


EOF
# redis config
cat << EOF > /opt/livekit/redis.conf
bind 127.0.0.1 ::1
protected-mode yes
port 6379
timeout 0
tcp-keepalive 300


EOF
# ingress config
cat << EOF > /opt/livekit/ingress.yaml
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
api_key: APIVg6jLoiMwFHp
api_secret: O7CKx1ptmrBOtM6bMePQq0derknyE5jbjnYXlRm4oG0
ws_url: wss://livekit.myhost.com
rtmp_port: 1935
whip_port: 8080
http_relay_port: 9090
logging:
    json: false
    level: ""
development: false
rtc_config:
    udp_port: 7885
    use_external_ip: true
    enable_loopback_candidate: false


EOF
# acme-dns credentials
cat << EOF > /opt/livekit/acme-dns-cred.json
{
  "myhost.com": {
    "username": "<username>",
    "password": "<password>",
    "fulldomain": "<full domain from registration response>",
    "subdomain": "<subdomain>",
    "server_url": "<server URL>"
  }
}


EOF

chmod 755 /opt/livekit/update_ip.sh
/opt/livekit/update_ip.sh

systemctl enable livekit-docker
systemctl start livekit-docker
