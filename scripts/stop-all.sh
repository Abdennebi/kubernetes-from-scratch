#!/bin/bash

systemctl stop kube-scheduler
systemctl stop kube-controller-manager
systemctl stop kube-apiserver
systemctl stop etcd