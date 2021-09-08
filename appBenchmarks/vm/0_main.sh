#!/bin/bash
# [START GLOBAL_VARIABLES]
commitTable="commitTable.csv"

startNum=$1
endNum=$2
run=$3




vmInstanceNameBase="vm"
tsbsInstanceNameBase="tsbs"
zone=--zone="europe-west3-c"
# [END GLOBAL_VARIABLES]


# [START FUNCTIONS]
startVMInstance() {
	oldVersionCommit=$1
	newVersionCommit=$2
	instanceName=$3
  echo "creating instance $instanceName"
  gcloud compute instances create $instanceName --source-instance-template="microbench-standard-2" $zone \
      --metadata oldVersionCommit=$oldVersionCommit,newVersionCommit=$newVersionCommit \
			--metadata-from-file startup-script=scripts/1_initVictoriaMetrics.sh
}

startTSBSInstance() {
	instanceName=$1
  echo "creating instance $instanceName..."
  gcloud compute instances create $instanceName --source-instance-template="microbench-standard-image" $zone \
       --metadata-from-file=startup-script=scripts/2_initTsbs.sh
}

waitForInstances() {
	instance1=$1
	instance2=$2
	resultPath=$3
  ./utils/waitForInstance.sh $instance1 $zone
  gcloud compute instances get-serial-port-output $instance1 $zone | grep "startup-script:" > $resultPath'/start_'$instance1.log
  ./utils/waitForInstance.sh $instance2 $zone
  gcloud compute instances get-serial-port-output $instance2 $zone | grep "startup-script:" >$resultPath'/start_'$instance2.log
}





createContainer() {
	echo "Create VM container..."
	vmInstanceName=$1
	tag=$2
	port=$3


	cmd="sudo docker container create --cpus=1 -e GOMAXPROCS=2 --name $tag -v "'$HOME'"/vm-$tag:/victoria-metrics-data \
			-p $port:8428 victoriametrics/victoria-metrics:$tag -retentionPeriod=2"

	echo $cmd
	gcloud compute ssh $vmInstanceName $zone -- $cmd

	echo "$tag-container created"
}

startContainer() {
	echo "Start VM container..."
	vmInstanceName=$1
	tag=$2

	cmd="sudo docker start $tag"

	echo $cmd
	gcloud compute ssh $vmInstanceName $zone -- $cmd
	sleep 10s
	echo "$tag-container started"
}

stopContainer() {
	echo "Stop VM container..."
	vmInstanceName=$1
	tag=$2

	cmd="sudo docker stop $tag"

	echo $cmd
	gcloud compute ssh $vmInstanceName $zone -- $cmd

	echo "$tag-container stopped"
}

runBenchmark() {
	vmInstanceName=$1
	tsbsInstanceName=$2
	gcloud compute ssh $tsbsInstanceName $zone -- 'mkdir -p scripts results'
	gcloud compute scp "$PWD/scripts/3_runInserts.sh" $tsbsInstanceName:~/scripts  $zone
	gcloud compute scp "$PWD/scripts/4_runQueries.sh" $tsbsInstanceName:~/scripts  $zone
	gcloud compute ssh $tsbsInstanceName $zone -- "chmod +x ./scripts/*"
	createContainer $vmInstanceName "old_version" "8428"
	createContainer $vmInstanceName "new_version" "8429"
	SUT_IP="$(gcloud compute instances describe $vmInstanceName $zone --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"

  echo "running benchmark..."

	startContainer $vmInstanceName "old_version"
	startContainer $vmInstanceName "new_version"
  	gcloud compute ssh $tsbsInstanceName $zone -- "./scripts/3_runInserts.sh $SUT_IP 1"
	sleep 20s
	stopContainer $vmInstanceName "old_version"
	stopContainer $vmInstanceName "new_version"

	gcloud compute ssh $vmInstanceName $zone -- "sudo rm -rf vm-new_version; sudo cp -r vm-old_version vm-new_version"

	startContainer $vmInstanceName "old_version"
	startContainer $vmInstanceName "new_version"
	gcloud compute ssh $tsbsInstanceName $zone -- "./scripts/3_runInserts.sh $SUT_IP 2"
	sleep 20s
	stopContainer $vmInstanceName "old_version"
	stopContainer $vmInstanceName "new_version"

	gcloud compute ssh $vmInstanceName $zone -- "sudo rm -rf vm-new_version; sudo cp -r vm-old_version vm-new_version"


	startContainer $vmInstanceName "old_version"
	startContainer $vmInstanceName "new_version"
	gcloud compute ssh $tsbsInstanceName $zone -- "./scripts/4_runQueries.sh $SUT_IP 1"

	gcloud compute ssh $tsbsInstanceName $zone -- "./scripts/4_runQueries.sh $SUT_IP 2"
}

getResults() {
	resultPath=$1
	tsbsInstanceName=$2
	gcloud compute scp  $tsbsInstanceName:~/results/* $PWD/$resultPath $zone
}

teardown() {
	echo "teardown..."
	vmInstanceName=$1
	tsbsInstanceName=$2
  gcloud compute instances delete -q $vmInstanceName $zone
  gcloud compute instances delete -q $tsbsInstanceName $zone
}
# [END FUNCTIONS]



main() {
	while IFS=";" read -u 9 -r number newHash oldHash date message
	do
		#only run benchmark for numbers between startNum (incl.) and endNum (excl.)
		if [ $number -ge $startNum ] && [ $number -lt $endNum ]
		then
			#Create folder /result/run$run/$number/ (abort if folder already exists)
			resultPath="results/run$run/$number/"
			if [[ ! -d "$resultPath" ]]
			then
				vmInstanceName=$vmInstanceNameBase'-r'$run'n'$number
				tsbsInstanceName=$tsbsInstanceNameBase'-r'$run'n'$number

				echo "Run: $run ; number: $number ; oldHash: $oldHash ; newHash: $newHash ; date: $date ; message: $message"
				echo "Will create $resultPath"
				mkdir -p $resultPath
				#Write info file
				echo "Run: $run" > "$resultPath/info.log"
				echo "Number: $number" >> "$resultPath/info.log"
				echo "OldHash: $oldHash" >> "$resultPath/info.log"
				echo "NewHash: $newHash" >> "$resultPath/info.log"
				echo "Date (newHash): $date" >> "$resultPath/info.log"
				echo "Message (newHash): $message" >> "$resultPath/info.log"

				echo "Starting instances..."
				startVMInstance $oldHash $newHash $vmInstanceName
				startTSBSInstance $tsbsInstanceName
				waitForInstances  $tsbsInstanceName $vmInstanceName $resultPath


				#Run application benchmark using Duet Benchmarking (and write log to $resultPath/benchmarklog.txt)
				echo "Run benchmark"
				runBenchmark $vmInstanceName $tsbsInstanceName 2>&1 | tee $resultPath/runBenchmark.log

				#Download result files for both versions (oldHashResult.txt and newHashResult.txt)
				# AND Shutdown SUT and client instance
				echo "Get results and clean up"
				getResults $resultPath $tsbsInstanceName 2>&1 | tee $resultPath/getResults.log

				teardown $vmInstanceName $tsbsInstanceName 2>&1 | tee $resultPath/teardown.log

				echo "Experiment done."

			fi
		fi
	done 9< <(tail -n +2 $commitTable | shuf)
	echo "end of parsing commit table"
	echo "main done."
}
main
