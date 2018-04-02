#!/bin/bash
set -e
set -o pipefail

KUBERNETES_VERSION="v1.10.0"
CNI_VERSION="v0.6.0"
BIN_DIR="/usr/local/bin"
KUBE_CONFIG="/var/lib/kubelet/kubeconfig"
POD_CLUSTER_IP_RANGE="10.200.0.0/16"
API_SERVER_URL="http://127.0.0.1:8080"
CNI_BIN_DIR="/opt/cni/bin"
KUBELET_SERVICE=/etc/systemd/system/kubelet.service
KUBE_PROXY_SERVICE=/etc/systemd/system/kube-proxy.service

download_worker_components(){
    local download_uri="https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64"

    wget "${download_uri}/kubelet" -P ${BIN_DIR}
    wget "${download_uri}/kube-proxy" -P ${BIN_DIR}

    chmod +x ${BIN_DIR}/kube-proxy ${BIN_DIR}/kubelet
}

create_kubeconfig(){
    mkdir -p $(dirname ${KUBE_CONFIG})
    cat << EOF > ${KUBE_CONFIG}
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: ${API_SERVER_URL}
  name: kubernetes-from-scratch
contexts:
- context:
    cluster: kubernetes-from-scratch
    user: ""
  name: default
current-context: default
preferences: {}
users: []
EOF
}

install_kube_proxy(){
    cat << EOF > ${KUBE_PROXY_SERVICE}
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://kubernetes.io/docs/reference/generated/kube-proxy/

[Service]
ExecStart=${BIN_DIR}//kube-proxy \
--master=${API_SERVER_URL} \
--proxy-mode=iptables \
--cluster-cidr=${POD_CLUSTER_IP_RANGE}

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable kube-proxy
    systemctl start kube-proxy

    systemctl status kube-proxy --no-pager
}

install_kubelet(){
    cat << EOF > ${KUBELET_SERVICE}
[Unit]
Description=Kubernetes Kubelet
Documentation=https://kubernetes.io/docs/reference/generated/kubelet/
After=docker.service
Requires=docker.service

[Service]
ExecStart=${BIN_DIR}/kubelet \
--network-plugin=kubenet \
--kubeconfig=${KUBE_CONFIG}

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kubelet
    systemctl start kubelet

    systemctl status kubelet --no-pager
}

uninstall_worker_components(){
    if [ -f ${KUBELET_SERVICE} ]; then
        systemctl stop kubelet
        rm ${KUBELET_SERVICE}
    fi
    if [ -f ${KUBE_PROXY_SERVICE} ]; then
        systemctl stop kube-proxy
        rm ${KUBE_PROXY_SERVICE}
    fi
    systemctl daemon-reload

    rm -fr /var/lib/kubelet/

    rm -f ${BIN_DIR}/kubelet
    rm -f ${BIN_DIR}/kube-proxy

    rm -fr ${CNI_BIN_DIR}
    rm -fr ${KUBE_CONFIG}
}

install_cni() {
    local download_url="https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz"
    mkdir -p ${CNI_BIN_DIR}
    wget -qO- $download_url | tar -xvz -C ${CNI_BIN_DIR}
}

install_worker_components(){
    create_kubeconfig
    download_worker_components
    install_cni
    install_kube_proxy
    install_kubelet
}

