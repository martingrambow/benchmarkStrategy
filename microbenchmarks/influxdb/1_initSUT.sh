#gcloud config set project microbenchmarkevaluation

run=$1
number=$2
oldCommit=$3
newCommit=$4
echo "Init old Influx ...(commit is "$oldCommit")"
instanceName="influx-micro-r"$run"n"$number

#create and get $instanceName instance
gcloud compute instances create $instanceName --source-instance-template="microbench-standard-2" --zone="europe-west3-c"
sleep 40s

#Get and Save IP
IP="$(gcloud compute instances describe $instanceName --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $IP


#install git, etc.
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q language-pack-de'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q clang pkg-config'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q gcc'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt install -y -q apt-transport-https ca-certificates curl software-properties-common'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'curl https://sh.rustup.rs -sSf | sh -s -- -y'

gcloud compute ssh $instanceName --zone europe-west3-c -- 'wget https://dl.google.com/go/go1.16.4.linux-amd64.tar.gz'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo tar -xvf go1.16.4.linux-amd64.tar.gz'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo mv go /usr/local'

gcloud compute ssh $instanceName --zone europe-west3-c -- 'mkdir go'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export GOROOT=/usr/local/go" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export GOPATH=\$HOME/go" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export PATH=\$HOME/go/bin:/usr/local/go/bin:\$PATH" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; go env'

gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo mkdir /pkg'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo chmod 777 /pkg'


gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'

#Clone and reset influxdb (old version)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mv influxdb influxdbOld'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbOld; git checkout 2.0'

#Reset branch to old commit hash
cmd="cd influxdbOld; git reset --hard $oldCommit"
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd influxdbOld; go build -o ~/go/bin/ github.com/influxdata/pkg-config'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd influxdbOld; ./env go build'

echo "######################################"
echo "Init old influx (" $oldCommit ") done."
echo "######################################"

#Clone and reset influxdb (new version)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mv influxdb influxdbNew'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbNew; git checkout 2.0'

#Reset branch to old commit hash
cmd="cd influxdbNew; git reset --hard $newCommit"
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd influxdbNew; ./env go build'

echo "######################################"
echo "Init new influx (" $newCommit ") done."
echo "######################################"

sleep 60s

echo "1/4 Influx init done."
exit 0