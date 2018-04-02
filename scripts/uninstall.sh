#!/bin/bash

. docker.sh 
. etcd.sh
. master.sh
. worker.sh

uninstall_docker
uninstall_etcd
uninstall_master_components
uninstall_worker_components
