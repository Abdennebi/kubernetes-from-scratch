#!/bin/bash
set -e
set -o pipefail

KUBERNETES_VERSION="v1.12.2"
BIN_DIR=/usr/local/bin
ETCD_SERVERS=https://localhost:2379
API_SERVER_URL=https://127.0.0.1:6443
SERVICE_CLUSTER_IP_RANGE=10.10.0.0/16
POD_CLUSTER_IP_RANGE=172.16.0.0/16
API_SERVER_SERVICE=/etc/systemd/system/kube-apiserver.service
CONTROLLER_MANAGER_SERVICE=/etc/systemd/system/kube-controller-manager.service
SCHEDULER_SERVICE=/etc/systemd/system/kube-scheduler.service

download_components(){
    local download_uri="https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64"

    wget -q -nc "${download_uri}/kube-apiserver" -P ${BIN_DIR}
    wget -q -nc "${download_uri}/kube-controller-manager" -P ${BIN_DIR}
    wget -q -nc "${download_uri}/kube-scheduler" -P ${BIN_DIR}
    wget -q -nc "${download_uri}/kubectl" -P ${BIN_DIR}

    chmod +x ${BIN_DIR}/kube*
}

copy_config_files(){
    mkdir -p /etc/kubernetes/config/
    cp templates/etc/kubernetes/config/* /etc/kubernetes/config/
    cp templates/var/lib/kubernetes/* /var/lib/kubernetes/
}
install_api_server(){
    
    BIN_DIR=${BIN_DIR} \
    ETCD_SERVERS=${ETCD_SERVERS} \
    SERVICE_CLUSTER_IP_RANGE=${SERVICE_CLUSTER_IP_RANGE} \
    envsubst < templates${API_SERVER_SERVICE} > ${API_SERVER_SERVICE}

    systemctl daemon-reload
    systemctl enable kube-apiserver
    systemctl start kube-apiserver

    systemctl status kube-apiserver --no-pager
}

install_controller_manager(){
    BIN_DIR=${BIN_DIR} \
    API_SERVER_URL=${API_SERVER_URL} \
    POD_CLUSTER_IP_RANGE=${POD_CLUSTER_IP_RANGE} \
    SERVICE_CLUSTER_IP_RANGE=${SERVICE_CLUSTER_IP_RANGE} \
    SERVICE_ACCOUNT_KEY=${SERVICE_ACCOUNT_KEY} \
    envsubst < templates${CONTROLLER_MANAGER_SERVICE} > ${CONTROLLER_MANAGER_SERVICE}

    systemctl daemon-reload
    systemctl enable kube-controller-manager
    systemctl start kube-controller-manager

    systemctl status kube-controller-manager --no-pager
}

install_scheduler(){
    BIN_DIR=${BIN_DIR} \
    API_SERVER_URL=${API_SERVER_URL} \
    envsubst < templates${SCHEDULER_SERVICE} > ${SCHEDULER_SERVICE}
    
    systemctl daemon-reload
    systemctl enable kube-scheduler
    systemctl start kube-scheduler

    systemctl status kube-scheduler --no-pager
}

install_master_components() {
    #download_components
    copy_config_files
    #install_service_account_private_key
    install_api_server
    install_controller_manager
    install_scheduler
}

uninstall_master_components(){

    if [ -f ${API_SERVER_SERVICE} ]; then
        systemctl stop kube-apiserver
        rm ${API_SERVER_SERVICE}
    fi

    if [ -f ${CONTROLLER_MANAGER_SERVICE} ]; then
        systemctl stop kube-controller-manager
        rm ${CONTROLLER_MANAGER_SERVICE}
    fi

    if [ -f ${SCHEDULER_SERVICE} ]; then
        systemctl stop kube-scheduler
        rm ${SCHEDULER_SERVICE}
    fi

    systemctl daemon-reload

    rm -f ${SERVICE_ACCOUNT_KEY}

    rm -f ${BIN_DIR}/kube-apiserver
    rm -f ${BIN_DIR}/kube-controller-manager
    rm -f ${BIN_DIR}/kube-scheduler
    rm -f ${BIN_DIR}/kubectl
}

