#!/bin/bash

echo "init tsbs start"

sudo apt-get update

#install git, go, etc.
sudo apt-get install -y git golang-go make
mkdir -p /usr/local/tsbs/go
mkdir -p /usr/local/tsbs/data
mkdir -p /usr/local/tsbs/caches/go-build


#install benchmarking client
export TSBS_PATH=/usr/local/tsbs
export GOPATH=/usr/local/tsbs/go
export PATH=$PATH:$GOPATH/bin
export GOCACHE=/usr/local/tsbs/caches/go-build


echo "PATH=$PATH" | sudo tee -a /etc/environment
echo "GOPATH=$GOPATH" | sudo tee -a /etc/environment
echo "GOCACHE=$GOCACHE" | sudo tee -a /etc/environment
echo "TSBS_PATH=$TSBS_PATH" | sudo tee -a /etc/environment




#install benchmarking client
go get -v -d github.com/loposkin/tsbs

cd $GOPATH/src/github.com/loposkin/tsbs/cmd
cd tsbs_load_victoriametrics && go install
cd ../tsbs_run_queries_victoriametrics && go install

#mount disk
MOUNT_DIR=/mnt/disks/tsbs-inserts
DEVICE_NAME=/dev/sdb

sudo mkdir -p $MOUNT_DIR
sudo mount -o discard,defaults $DEVICE_NAME $MOUNT_DIR
sudo chmod a+rw $MOUNT_DIR
DATA_PATH=$MOUNT_DIR/data
export DATA_PATH=$DATA_PATH
echo "DATA_PATH=$DATA_PATH" | sudo tee -a /etc/environment


touch /etc/startup_script_finished
echo "2/4 TSBS init done."

exit 0
