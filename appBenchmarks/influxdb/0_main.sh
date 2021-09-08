#!/bin/bash

commitTable="commitTable.csv"

startNum=$1
endNum=$2
run=$3

change=true

while [ "$change" == true ]
do
	change=false
	#Parse commit table
	while IFS=";" read -r number newHash oldHash date message
	do
		#only run benchmark for numbers between startNum (incl.) and endNum (excl.)
		if [ $number -ge $startNum ] && [ $number -lt $endNum ]
		then			
			#Create folder /result/run$run/$number/ (abort if folder already exists)
			resultPath="results/run$run/$number/"
			if [[ -d "$resultPath" ]]
			then
				tmp=0
				#echo "$resultPath already exists, skip."
			else
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
							
				#Init both influx DBs on the same instance (and write log to $resultPath/initInflux.txt)
				echo "Init Influx instance"
				./1_initInflux.sh $run $number $oldHash $newHash > $resultPath/initInflux.log 2>&1
				
				#Init Tsbs in the client instance (and write log to $resultPath/initTsbs.txt)
				echo "Init Tsbs instance"
				./2_initTsbs.sh $run $number > $resultPath/initTsbs.log 2>&1
				
				#Run application benchmark using Duet Benchmarking (and write log to $resultPath/benchmarklog.txt)
				echo "Run benchmark"
				./3_runBenchmark.sh $run $number > $resultPath/benchmark.log 2>&1
				
				#Download result files for both versions (oldHashResult.txt and newHashResult.txt)
				# AND Shutdown SUT and client instance
				echo "Get results and shut down instances"
				./4_getResults.sh $run $number $resultPath > $resultPath/getResults.log 2>&1
				
				echo "Experiment done."
				change=true
			fi
		fi  
	done < <(tail -n +1 $commitTable)
	echo "end of parsing commit table"
done
echo "main done."