#!/bin/bash
set -e
set -o pipefail

ETCD_VERSION="v3.1.12"
BIN_DIR=/usr/local/bin/

install_etcd() {

    local download_url="https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz"

    # Download etcd distro then copy etcd and etcdctl to /usr/local/bin/
    wget -qO- $download_url | tar -xvz -C $BIN_DIR --wildcards  "etcd-${ETCD_VERSION}-linux-amd64/etcd*" --strip-components=1

    # Etcd's data directory
    mkdir -p /var/lib/etcd

    local TEMPLATE=/etc/systemd/system/etcd.service
    if [ ! -f $TEMPLATE ]; then
        echo "TEMPLATE: $TEMPLATE"
        cat << EOF > $TEMPLATE
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd

[Service]
ExecStart=$BIN_DIR/etcd \
	--data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    fi
    # Enable and start the service
    systemctl daemon-reload
	systemctl enable etcd
	systemctl start etcd

    # Show status
    systemctl status etcd --no-pager
    etcdctl cluster-health
}

uninstall_etcd() {
    systemctl stop etcd
    systemctl daemon-reload
    rm /etc/systemd/system/etcd.service
    rm $BIN_DIR/etcd*
}

install_etcd
