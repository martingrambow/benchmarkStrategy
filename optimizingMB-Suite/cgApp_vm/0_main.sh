#!/bin/bash

# [START GLOBAL_VARIABLES]
commit=$1
vmInstanceName=$2
tsbsInstanceName=$3
zone=--zone="europe-west3-c"
# [END GLOBAL_VARIABLES]

# [START FUNCTIONS]
startVMInstance() {
  echo "creating instance $vmInstanceName..."
  gcloud compute instances create $vmInstanceName --source-instance-template="microbench-standard-2" $zone \
      --metadata=commit=$commit --metadata-from-file=startup-script=scripts/1_initVictoriaMetrics.sh
}

startTSBSInstance() {
  echo "creating instance $tsbsInstanceName..."
  gcloud compute instances create $tsbsInstanceName --source-instance-template="microbench-standard-image" $zone \
       --metadata-from-file=startup-script=scripts/2_initTsbs.sh
}

waitForInstances() {
  mkdir -p logs
  ./utils/waitForInstance.sh $tsbsInstanceName $zone
  gcloud compute instances get-serial-port-output $tsbsInstanceName $zone | grep "startup-script:" > logs/log_$tsbsInstanceName.log
  ./utils/waitForInstance.sh $vmInstanceName $zone
  gcloud compute instances get-serial-port-output $vmInstanceName $zone | grep "startup-script:" > logs/log_$vmInstanceName.log
}

runContainer() {
	echo "Create VM container..."
	tag=$1
	port=$2


	cmd="sudo docker run -d --cpus=1 -e GOMAXPROCS=2 --name $tag -v "'$HOME'"/vm-$tag:/victoria-metrics-data \
			-v "'$HOME'"/shared/:/shared -p $port:8428 victoriametrics/victoria-metrics:$tag -retentionPeriod=2"

	echo $cmd
	gcloud compute ssh $vmInstanceName $zone -- $cmd

	echo "$tag-container started"
}

stopContainer() {
	echo "Stop VM container..."
	tag=$1

	cmd="sudo docker stop $tag"

	echo $cmd
	gcloud compute ssh $vmInstanceName $zone -- $cmd

	echo "$tag-container stopped"
}

runBenchmark() {
	gcloud compute ssh $tsbsInstanceName $zone -- 'mkdir -p scripts results'
	gcloud compute scp "$PWD/scripts/3_runBenchmark.sh" $tsbsInstanceName:~/scripts  $zone
	gcloud compute ssh $tsbsInstanceName $zone -- "chmod +x ./scripts/*"
	runContainer "benchmark" "8428"
	SUT_IP="$(gcloud compute instances describe $vmInstanceName $zone --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"

  echo "running benchmark..."

  gcloud compute ssh $tsbsInstanceName $zone -- "./scripts/3_runBenchmark.sh $SUT_IP"
  stopContainer "benchmark"
}

extractAppBenchmark() {
  echo "Will extract graph..."
  resultPath="results/$commit/appBenchmark"
  mkdir -p $resultPath

  #Get pprof profile file
  gcloud compute scp $vmInstanceName:~/shared/cpuRaw.pprof "$PWD/$resultPath/$commit.pprof" $zone

  go tool pprof -nodecount=3000 --nodefraction=0.002 --edgefraction=0.0 -svg "$PWD/$resultPath/$commit.pprof" > "$PWD/$resultPath/$commit.svg"
  go tool pprof -nodecount=3000 --nodefraction=0.0 --edgefraction=0.0 -dot "$PWD/$resultPath/$commit.pprof" > "$PWD/$resultPath/$commit.dot"
  go tool pprof -nodecount=3000 --nodefraction=0.0 --edgefraction=0.0 -text "$PWD/$resultPath/$commit.pprof" > "$PWD/$resultPath/$commit.csv"
  echo "4/4 extract profile done."
}

teardown() {
  gcloud compute instances delete -q $vmInstanceName $zone
  gcloud compute instances delete -q $tsbsInstanceName $zone
}
# [END FUNCTIONS]

# [START MAIN]
main() {

  echo "running script for commit $commit"

  startVMInstance
  startTSBSInstance
  waitForInstances
  runBenchmark
  extractAppBenchmark
  teardown
}
# [END MAIN]

main
