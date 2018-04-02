#!/bin/bash

. docker.sh 
. etcd.sh
. master.sh
. worker.sh

install_docker
install_etcd
install_master_components
install_worker_components
