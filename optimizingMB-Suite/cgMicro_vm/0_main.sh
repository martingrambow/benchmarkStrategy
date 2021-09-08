#!/bin/bash

commitTable="commitTable.csv"

startNum=$1
endNum=$2
run=$3

basename="vm-micro-cg"
zone=--zone="europe-west3-c"

initSUT() {
	oldVersionCommit=$1
	newVersionCommit=$2
	instanceName=$3

	echo "creating instance $instanceName"
  gcloud compute instances create $instanceName --source-instance-template="microbench-standard-2" $zone \
      --metadata homePath=${HOME},oldVersionCommit=${oldVersionCommit},newVersionCommit=${newVersionCommit} \
			--metadata-from-file startup-script=scripts/1_initSUT.sh
}

waitForInstance() {
	instance=$1
	resultPath=$2

  ./utils/waitForInstance.sh $instance $zone
  gcloud compute instances get-serial-port-output $instance $zone | grep "startup-script:" > $resultPath'/startup-script'.log
}

runBenchmark() {
	echo "running benchmark..."
	instance=$1
	resultPath=$2

	gcloud compute scp "$PWD/abs_config.json" $instance:~/  $zone
	gcloud compute ssh $instance $zone -- 'sudo chown -R $USER:$USER . ; mkdir -p results/profiles; goabs -c abs_config.json -d -o results/microbenchResults.csv'
}

getResults() {
	instance=$1
	resultPath=$2

	gcloud compute scp $instanceName:~/results/* --recurse $resultPath $zone
}

teardown() {
	echo "teardown..."
	instance=$1
  gcloud compute instances delete -q $instance $zone
}

#Parse commit table
while IFS=";" read -u 9 -r number newHash oldHash date message
do
	#only run benchmark for numbers between startNum (incl.) and endNum (excl.)
	if [ $number -ge $startNum ] && [ $number -lt $endNum ]
	then
		#Create folder /result/run$run/$number/ (abort if folder already exists)
		resultPath="resultsMicro/run$run/$number/"

		if [[ ! -d "$resultPath" ]]
		then
			echo "Run: $run ; number: $number ; oldHash: $oldHash ; newHash: $newHash ; date: $date ; message: $message"
			echo "Will create $resultPath"
			mkdir -p $resultPath
			#Write info file
			echo "Run: $run" > "$resultPath/info.txt"
			echo "Number: $number" >> "$resultPath/info.txt"
			echo "OldHash: $oldHash" >> "$resultPath/info.txt"
			echo "NewHash: $newHash" >> "$resultPath/info.txt"
			echo "Date (newHash): $date" >> "$resultPath/info.txt"
			echo "Message (newHash): $message" >> "$resultPath/info.txt"

			#Init both vm DBs on the same instance (and write log to $resultPath/initVM.log)
			echo "Init VM instance"
			instanceName="${basename}-r${run}n${number}"

			initSUT $oldHash $newHash $instanceName 2>&1 | tee $resultPath/initSUT.log
			waitForInstance $instanceName $resultPath
			runBenchmark $instanceName $resultPath 2>&1 | tee $resultPath/runBenchmark.log
			getResults $instanceName $resultPath 2>&1 | tee $resultPath/getResults.log
			teardown $instanceName 2>&1 | tee $resultPath/teardown.log

			echo "Experiment done."
		fi
	fi
done 9< <(tail -n +2 $commitTable | shuf)
echo "end of parsing commit table"

echo "main done."
