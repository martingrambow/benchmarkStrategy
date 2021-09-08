#gcloud config set project microbenchmarkevaluation

commit=$1
instanceName="influx-micro-cg"

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
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mkdir profiles'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export GOROOT=/usr/local/go" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export GOPATH=\$HOME/go" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'echo "export PATH=\$HOME/go/bin:/usr/local/go/bin:\$PATH" >> .profile'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; go env'

gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo mkdir /pkg'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo chmod 777 /pkg'


gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'

#Clone and reset influxdb
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdb; git checkout 2.0'

#Reset branch to commit hash
cmd="cd influxdb; git reset --hard $commit"
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd influxdb; go build -o ~/go/bin/ github.com/influxdata/pkg-config'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd influxdb; ./env go build'

echo "######################################"
echo "Init influx (" $commit ") done."
echo "######################################"

sleep 60s
echo "1/4 Influx init done."
exit 0