#!/bin/bash

DOCKER_VERSION="17.03.2"
BIN_DIR=/usr/local/bin
DOCKER_SERVICE=/etc/systemd/system/docker.service

install_docker() {
    local download_url="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION-ce.tgz"

    wget -qO- $download_url | tar -xvz -C $BIN_DIR --strip-components=1

    cat << EOF > ${DOCKER_SERVICE}
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

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker

    # Show status
    systemctl status docker --no-pager
    docker info

}

uninstall_docker() {
    if [ -f ${DOCKER_SERVICE} ]; then
        systemctl stop docker
        systemctl daemon-reload
        rm /etc/systemd/system/docker.service
    fi
    rm -fr /var/run/docker/
    rm -fr /var/lib/docker/
    rm -f $BIN_DIR/docker*
}



