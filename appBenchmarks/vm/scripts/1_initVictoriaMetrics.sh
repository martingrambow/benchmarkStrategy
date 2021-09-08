#!/bin/bash

#gcloud config set project microbenchmarkevaluation


echo "installing software..."
#install git, docker, etc.
sudo apt-get update
sudo apt-get install -y git make
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update; sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# increase number of open files
echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#Start docker
sudo service docker start

echo "checking out repository..."
repository_name='VictoriaMetrics'

#Clone and reset influxdb
git clone https://github.com/VictoriaMetrics/VictoriaMetrics.git


# build docker image for old commit
oldVersionCommit=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/oldVersionCommit -H "Metadata-Flavor: Google")
git -C ./$repository_name reset --hard $oldVersionCommit
sudo PKG_TAG=old_version make -C $repository_name package-victoria-metrics

#build docker image for new commit
newVersionCommit=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/newVersionCommit -H "Metadata-Flavor: Google")
git -C ./$repository_name reset --hard $newVersionCommit
sudo PKG_TAG=new_version make -C $repository_name package-victoria-metrics


sudo docker images
touch /etc/startup_script_finished
echo "1/4 init VictoriaMetrics done."
exit 0
