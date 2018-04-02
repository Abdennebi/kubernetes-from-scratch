#!/bin/bash

. docker.sh
. etcd.sh
. master.sh
. worker.sh

uninstall_worker_components
uninstall_docker
uninstall_master_components
uninstall_etcd
