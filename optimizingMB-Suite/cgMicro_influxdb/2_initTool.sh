echo "init tool start"

instanceName="influx-micro-cg"

#Clone tool
gcloud compute ssh $instanceName --zone europe-west3-c -- 'git clone https://github.com/martingrambow/GoABS.git'

#Install tool 
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; cd GoABS; go install'

#Copy abs_config to instance 
gcloud compute scp $PWD/abs_config.json $instanceName:~/abs_config.json --zone europe-west3-c 

echo "2/4 tool init done."
exit 0
