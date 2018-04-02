#!/bin/bash

. docker.sh
. etcd.sh
. master.sh
. worker.sh

install_etcd
install_master_components
install_docker
install_worker_components
