#gcloud config set project microbenchmarkevaluation



#install git, etc.
sudo apt update
sudo apt-get install -y git clang pkg-config gcc apt-transport-https ca-certificates curl software-properties-common

wget -nv https://dl.google.com/go/go1.16.4.linux-amd64.tar.gz
sudo tar -xvf go1.16.4.linux-amd64.tar.gz
sudo mv go /usr/local

oldVersionCommit=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/oldVersionCommit -H "Metadata-Flavor: Google")
newVersionCommit=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/newVersionCommit -H "Metadata-Flavor: Google")
homePath=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/homePath -H "Metadata-Flavor: Google")

mkdir -p $homePath
mkdir -p $homePath/go
mkdir -p $homePath/caches/go-build


#install benchmarking client

export GOPATH=$homePath/go
export GOCACHE=$homePath/caches/go-build
export GOROOT=/usr/local/go
export PATH=${PATH}:/usr/local/go/bin:${homePath}/go/bin

echo "GOPATH=$GOPATH" | sudo tee -a /etc/environment
echo "PATH=$PATH" | sudo tee -a /etc/environment
echo "GOCACHE=$GOCACHE" | sudo tee -a /etc/environment
echo "GOROOT=$GOROOT" | sudo tee -a /etc/environment
sudo mkdir /pkg
sudo chmod 777 /pkg

echo "Downloading VM..."
#Clone and reset influxdb (old version)
git clone https://github.com/VictoriaMetrics/VictoriaMetrics.git $homePath/vmOld
cp -r $homePath/vmOld $homePath/vmNew

#Reset branch to old commit hash
git -C $homePath/vmOld reset --hard $oldVersionCommit
git -C $homePath/vmNew reset --hard $newVersionCommit
echo "Done."

echo "Installing benchmarking tool..."
#Clone tool
git clone https://github.com/martingrambow/GoABS.git $homePath/GoABS

#Install tool
cd /$homePath/GoABS && go install

echo "Done."

touch /etc/startup_script_finished
echo "1/4 Influx init done."
exit 0
