#!/bin/bash

echo "init tsbs start"

sudo apt-get update

#install git, go, etc.
sudo apt-get install -y git golang-go make
mkdir -p /usr/local/tsbs/go
mkdir -p /usr/local/tsbs/data
mkdir -p /usr/local/tsbs/caches/go-build

export TSBS_PATH=/usr/local/tsbs
export GOPATH=/usr/local/tsbs/go
export PATH=$PATH:$GOPATH/bin
export GOCACHE=/usr/local/tsbs/caches/go-build


echo "PATH=$PATH" | sudo tee -a /etc/environment
echo "GOPATH=$GOPATH" | sudo tee -a /etc/environment
echo "GOCACHE=$GOCACHE" | sudo tee -a /etc/environment
echo "TSBS_PATH=$TSBS_PATH" | sudo tee -a /etc/environment




#install benchmarking client
go get -v -d github.com/timescale/tsbs

cd $GOPATH/src/github.com/timescale/tsbs/cmd
# later versions are broken
git reset --hard 45b63214a5e3fdd90f4fdde0a8233b7e766a3b0f
cd tsbs_generate_data && go install
cd ../tsbs_generate_queries && go install

#mount disk
MOUNT_DIR=/mnt/disks/tsbs-inserts
DEVICE_NAME=/dev/sdb
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $DEVICE_NAME

sudo mkdir -p $MOUNT_DIR
sudo mount -o discard,defaults $DEVICE_NAME $MOUNT_DIR
sudo chmod a+rw $MOUNT_DIR

########################################################
### Generate Load ######################################
########################################################

#Generate load (inserts) for the devops use case
# 300 servers(time series) in server farm (scale-var)
# each server generates a data point (includes 10 metrics) each 30 seconds (log-interval)
# simulate 3 days (timestamp-start and timestamp-end)
# increased density of metrics comparing to influxDB

DATA_PATH=$MOUNT_DIR/data
echo "DATA_PATH=$DATA_PATH" | sudo tee -a /etc/environment

mkdir -p $DATA_PATH
echo "Generate inserts..."
tsbs_generate_data --use-case=devops \
		--seed=123 --scale=800 \
   --timestamp-start='2021-06-01T00:00:00Z' \
   --timestamp-end='2021-06-02T12:00:00Z' \
   --log-interval='60s' --format=victoriametrics> $DATA_PATH/inserts1.txt

tsbs_generate_data --use-case=devops \
		--seed=123 --scale=800 \
  --timestamp-start='2021-06-02T12:00:01Z' \
  --timestamp-end='2021-06-04T00:00:00Z' \
  --log-interval='60s' --format=victoriametrics> $DATA_PATH/inserts2.txt

echo "Done."


#8640 = two queries per min for 3 days (2*60*24*3)
echo "Generate queries..."
tsbs_generate_queries --use-case=devops \
		--seed=123 --scale=800 \
   --timestamp-start='2021-06-01T00:00:00Z' \
   --timestamp-end='2021-06-04T00:00:01Z' \
   --queries=8640 --query-type=cpu-max-all-8  --format=victoriametrics > $DATA_PATH/queries1.txt


#1440 = one query per 3 minutes for 3 days (20*24*3)
echo "Generate queries..."
tsbs_generate_queries --use-case=devops \
		--seed=123 --scale=800 \
   --timestamp-start='2021-06-01T00:00:00Z' \
   --timestamp-end='2021-06-04T00:00:01Z' \
   --queries=1440 --query-type=double-groupby-all --format=victoriametrics > $DATA_PATH/queries2.txt

sudo du -h $DATA_PATH

touch /etc/startup_script_finished
echo "2/4 TSBS init done."

exit 0
