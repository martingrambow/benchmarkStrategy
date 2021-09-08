#gcloud config set project microbenchmarkevaluation

run=$1
number=$2
oldCommit=$3
newCommit=$4
echo "Init old Influx ...(commit is "$oldCommit")"
instanceName="influx-r"$run"n"$number

#create and get $instanceName instance
gcloud compute instances create $instanceName --source-instance-template="microbench-standard-2" --zone="europe-west3-c"
sleep 40s

#Get and Save IP
IP="$(gcloud compute instances describe $instanceName --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $IP


#install git, docker, etc.
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q language-pack-de'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt install -y -q apt-transport-https ca-certificates curl software-properties-common'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt install -y -q docker-ce'

#Start docker
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo service docker start'

#Clone and reset influxdb
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mv influxdb influxdbOld'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbOld; git checkout 2.0'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mkdir sharedOld'

#Reset branch to old commit hash
cmd="cd influxdbOld; git reset --hard $oldCommit"
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd


#increase yarn network-timeout 
makeline="$(gcloud compute ssh $instanceName --zone europe-west3-c -- 'grep -nr "RUN make" influxdbOld/Dockerfile')"
makeline=$(echo $makeline | cut -d: -f1)
echo $makeline

cmd='sed -i '\'${makeline}'i RUN yarn config set network-timeout 300000'\'' influxdbOld/Dockerfile'
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

#Increase Javascript heap memory
makeline=$((makeline+1))
cmd='sed -i '\'${makeline}'i ENV NODE_OPTIONS=--max_old_space_size=4096'\'' influxdbOld/Dockerfile'
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

echo "################################################"
#Print new dockerfile
echo "new Dockerfile:"
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cat influxdbOld/Dockerfile'
echo "################################################"

#Build Dockerfile (target in Dockerfile is influx)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbOld; sudo docker build -f Dockerfile --target influx -t influxdb-old /home/pi/influxdbOld/'

echo "######################################"
echo "Init old influx (" $oldCommit ") done."
echo "######################################"

#Clone and reset influxdb
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mv influxdb influxdbNew'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbNew; git checkout 2.0'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'mkdir sharedNew'

#Reset branch to old commit hash
cmd="cd influxdbNew; git reset --hard $newCommit"
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd


#increase yarn network-timeout 
makeline="$(gcloud compute ssh $instanceName --zone europe-west3-c -- 'grep -nr "RUN make" influxdbNew/Dockerfile')"
makeline=$(echo $makeline | cut -d: -f1)
echo $makeline

cmd='sed -i '\'${makeline}'i RUN yarn config set network-timeout 300000'\'' influxdbNew/Dockerfile'
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

#Increase Javascript heap memory
makeline=$((makeline+1))
cmd='sed -i '\'${makeline}'i ENV NODE_OPTIONS=--max_old_space_size=4096'\'' influxdbNew/Dockerfile'
echo $cmd
gcloud compute ssh $instanceName --zone europe-west3-c -- $cmd

echo "################################################"
#Print new dockerfile
echo "new Dockerfile:"
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cat influxdbNew/Dockerfile'
echo "################################################"

#Build Dockerfile (target in Dockerfile is influx)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'cd influxdbNew; sudo docker build -f Dockerfile --target influx -t influxdb-new /home/pi/influxdbNew/'


echo "######################################"
echo "Init new influx (" $newCommit ") done."
echo "######################################"

echo "1/4 Influx init done."
exit 0