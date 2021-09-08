#!/bin/bash
#
instanceName=tsbs-data
zone=--zone=europe-west3-c

#gcloud config set project microbenchmarkevaluation
echo "creating instance $instanceName..."

# cannot attach disk to the instance created from template(probably a bug), use template with an empty disk of 20GB
gcloud compute instances create $instanceName --source-instance-template microbench-standard-disk $zone \
     --metadata-from-file startup-script=scripts/1_initTsbs.sh






./utils/waitForInstance.sh $instanceName $zone
gcloud compute instances get-serial-port-output $instanceName $zone | grep "startup-script:" > start_$instanceName.log
# must wait a little(until all data is written to disk), after script is ready, otherwise snapshot will be corrupted
sleep 90s

gcloud compute images create tsbs-inserts \
    --source-disk=$instanceName-1 \
    --source-disk-zone=europe-west3-c \
    --storage-location=europe-west3 \
    --force
gcloud compute instances delete -q $instanceName $zone
