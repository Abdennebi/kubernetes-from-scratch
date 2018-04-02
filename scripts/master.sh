#!/bin/bash
set -e
set -o pipefail

KUBERNETES_VERSION="v1.10.0"
BIN_DIR=/usr/local/bin
ETCD_SERVERS=http://localhost:2379
API_SERVER_URL=http://127.0.0.1:8080
SERVICE_CLUSTER_IP_RANGE=10.32.0.0/24
POD_CLUSTER_IP_RANGE=10.200.0.0/16
SERVICE_ACCOUNT_KEY=/var/lib/kubernetes/kubernetes-key.pem
API_SERVER_SERVICE=/etc/systemd/system/kube-apiserver.service
CONTROLLER_MANAGER_SERVICE=/etc/systemd/system/kube-controller-manager.service
SCHEDULER_SERVICE=/etc/systemd/system/kube-scheduler.service


install_service_account_private_key(){
    mkdir -p $(dirname ${SERVICE_ACCOUNT_KEY})
    cat << EOF > ${SERVICE_ACCOUNT_KEY}
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAsP0tuSSOkzBUpbDvAf92XdgqDNBzD2XyKxhX2vKUdm7A5+RG
ZsEPRr6OrbFecqs9LEELqbU+Uh9zAzTEHdztRD1oj4DeYezx17ZtG7I86Mr03cjQ
1rNncWOTNeM6WfyLA7tfd8h1YQCMVPLdO0FF8ysBOsQZzf0wIa/FFKD3pS94QluO
KDb3Pmm+ZLCyxMSJk5qQyK1JHVvdhi0fpB9OHunmEgNLt4booLNsGTjgvrs88+xG
Z078hyam9lEzbv/TC0FfXE26bOEU6Nw1atIlxug2/kJlAOxP/dBxHjX2r62EJpZI
Do2JIEaZ4LN3Qcu2FX0ukb4T5CZxnrFQd1IXOQIDAQABAoIBAFohNA2afjiaXiDa
j3w2+bIkiJVp+Y4X3lDv3p2S9uOw1u/AIdHl8r+V/taZAn3mkgpdPXE46PmtJka1
skF65iDgHMUnXRgFL8soDTwTck0iPbxLrX4Icl8d1DOW+Xolzy0hWCaJoKy7OLtx
yhOI0/RXLBMfFfz+OGqPNg+hQTuOrc0PzEnc2KDrDkY50UBXT99lpAHry/Hcvxm4
5gF0E9iuMoMKIiZ5Sh6DrN7CdpR9LSIcXGXUPXhNpk+47xkNI5L6LL0cmRaC/6kD
fNrCer/0lmYZFb0kSUfDl6l6jCj5nZm/XZNh1XaltV1twiv355cxGLKB+vgK1upU
R7aG2QECgYEA4TYlXTUgUP1jb5fUU1DAbAoSLnffg6JUYQ9y6LfY1D4YR5ZNMXPL
neUfqPpseo2nPMMXfTm4gCsegeOfwGetiXRkkuDp7KI3LzUgEoSxjzjY5I1aKQLJ
a3BIw3HmqL92ztE3eKzXbkBxHqGDhkDjOs0xc9Y6uplnEDbuQ37u3PECgYEAyS9c
lIBzH3egbrsgJ5gn472+LNbbgL0pA80NhRGZmbx5mNQCxOqWc/TNQC3adPVDq0RR
iYp9YKI1qF5YySeZAYfIsEJuyWVB0hiInw3V7QPa9aLoitxLEYCfDC65dBxxwKUX
cpeEi9AtQ6A+MlBArpcw1kXqvNtTR0kV5K2IfskCgYEAsxMJzL5kjuGcgmw4wXLR
PlcXs+lPSez2qSLOnOsqt0EUrz9869iGTGuWrBdL0Hr4QqFh+Qm/gfJHVMK5ERWf
cE+jdQLwHl+x/5B/ixoF0btDAyC+UyPLIunqgbX80atEfhjvwb21ow4MpG2LFmJc
DDKCovfyRNObltIGzJaOuhECgYAaly3vWsLch90mhYkMcqnjCfMWzhcY/udq3zFI
Qzk//o87ydnL2Q2lqddvAiB7kOcuvcrhGPLVUNsys7WccKVidGXsFfu6lq2KbT+x
dgyuVPIdwThnEhLB73QWEh7k39WRFsDwnmIgcJVq+MT/tWe3K7iCuZ768yogo+JG
5UDDMQKBgQC3tBxmYbxkeAPZDpwhq9TtOnpoj20e5aye+Fh9UNvTJfROUMpXXuA4
9QbhbMnNYuFf8d9Yai1A0j35Ed8/pzyoQSMsCFT942Ws3sqxFTZuSJplQovqzUBz
a6/u5XSdmCIO5e+0tzZMZDBu3n90zGwj23p4anS7pt1ik2qVv2qS+g==
-----END RSA PRIVATE KEY-----
EOF
}

download_components(){
    local download_uri="https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64"

    wget "${download_uri}/kube-apiserver" -P ${BIN_DIR}
    wget "${download_uri}/kube-controller-manager" -P ${BIN_DIR}
    wget "${download_uri}/kube-scheduler" -P ${BIN_DIR}
    wget "${download_uri}/kubectl" -P ${BIN_DIR}

    chmod +x ${BIN_DIR}/kube*
}

install_api_server(){
    cat << EOF > ${CONTROLLER_MANAGER_SERVICE}
[Unit]
Description=Kubernetes API Server
Documentation=https://kubernetes.io/docs/reference/generated/kube-apiserver/

[Service]
ExecStart=${BIN_DIR}/kube-apiserver \
--etcd-servers=${ETCD_SERVERS} \
--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} \
--service-account-key-file=${SERVICE_ACCOUNT_KEY}

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable kube-apiserver
    systemctl start kube-apiserver

    systemctl status kube-apiserver --no-pager
}

install_controller_manager(){
    cat << EOF > ${CONTROLLER_MANAGER_SERVICE}
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://kubernetes.io/docs/reference/generated/kube-controller-manager/

[Service]

ExecStart=${BIN_DIR}/kube-controller-manager \
--master=${API_SERVER_URL} \
--allocate-node-cidrs=true \
--cluster-cidr=${POD_CLUSTER_IP_RANGE} \
--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} \
--service-account-private-key-file=${SERVICE_ACCOUNT_KEY}

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable kube-controller-manager
    systemctl start kube-controller-manager

    systemctl status kube-controller-manager --no-pager
}

install_scheduler(){
    cat << EOF > ${SCHEDULER_SERVICE}
[Unit]
Description=Kubernetes Scheduler
Documentation=https://kubernetes.io/docs/reference/generated/kube-scheduler/

[Service]
ExecStart=${BIN_DIR}/kube-scheduler \
--master=${API_SERVER_URL}

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable kube-scheduler
    systemctl start kube-scheduler

    systemctl status kube-scheduler --no-pager
}

install_master_components() {
    download_components
    install_service_account_private_key
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
        systemctl stop kube-kube-controller-manager
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

