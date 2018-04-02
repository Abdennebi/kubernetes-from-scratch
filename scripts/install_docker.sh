#!/bin/bash
set -e
set -o pipefail

DOCKER_VERSION="17.03.2"
BIN_DIR=/usr/local/bin

install_docker() {
    local download_url="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION-ce.tgz"

    wget -qO- $download_url | tar -xvz -C $BIN_DIR --strip-components=1

    local TEMPLATE=/etc/systemd/system/docker.service
    if [ ! -f $TEMPLATE ]; then
        echo "TEMPLATE: $TEMPLATE"
        cat << EOF > $TEMPLATE
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com/engine/reference/commandline/dockerd/

[Service]
ExecStart=/usr/local/bin/dockerd --iptables=false
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    fi
    # Enable and start the service
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker

    # Show status
    systemctl status docker --no-pager
    docker info

}

uninstall_docker() {
    systemctl stop docker
    systemctl daemon-reload
    rm /etc/systemd/system/docker.service
    rm $BIN_DIR/docker*
}

install_docker


