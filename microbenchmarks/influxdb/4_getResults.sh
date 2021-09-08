run=$1
number=$2
resultPath=$3
instanceName="influx-micro-r"$run"n"$number

SUT_IP="$(gcloud compute instances describe $SUTinstanceName --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $SUT_IP

#Copy logs to result folder

gcloud compute scp $instanceName:~/microbenchResults.csv $resultPath/microbenchResults.csv --zone europe-west3-c 
gcloud compute scp $instanceName:~/abs.log $resultPath/abs.log --zone europe-west3-c 

echo "4/4 getResults done."

echo "Shut down instance..."

gcloud compute instances delete $instanceName --zone="europe-west3-c" --delete-disks="all" --quiet

echo "experiment done."
exit 0