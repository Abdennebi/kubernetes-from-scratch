#!/bin/bash
set -e
set -o pipefail

ETCD_VERSION="v3.2.24"
BIN_DIR=/usr/local/bin/
ETCD_SERVICE=/etc/systemd/system/etcd.service
ETCD_DATA=/var/lib/etcd/

install_etcd() {

    mkdir -p /etc/etcd /var/lib/etcd
    cp templates/etc/etcd/* /etc/etcd/

    local download_url="https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz"

    # Download etcd distro then copy etcd and etcdctl to /usr/local/bin/
    wget -qO- $download_url | tar -xvz -C $BIN_DIR --wildcards  "etcd-${ETCD_VERSION}-linux-amd64/etcd*" --strip-components=1

    ETCD_DATA=${ETCD_DATA} \
    BIN_DIR=${BIN_DIR} \
    INTERNAL_IP=127.0.0.1 \
    envsubst < templates/etc/systemd/system/etcd.service > ${ETCD_SERVICE}

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable etcd
    systemctl start etcd

    # Show status
    systemctl status etcd --no-pager
    ETCDCTL_API=3 etcdctl  member list --cacert /etc/etcd/ca.pem
}

uninstall_etcd() {
    if [ -f ${ETCD_SERVICE} ]; then
        systemctl stop etcd
        systemctl daemon-reload
        rm ${ETCD_SERVICE}
    fi
    rm -fr ${ETCD_DATA}
    rm -f $BIN_DIR/etcd*
}

