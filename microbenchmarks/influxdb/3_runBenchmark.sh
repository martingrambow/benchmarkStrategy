echo "run Microbenchmark"

run=$1
number=$2
instanceName="influx-micro-r"$run"n"$number

#Run suite(s)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; go env'

#Copy benchmark script zo instanceName
gcloud compute scp $PWD/runAsyncBenchmark.sh $instanceName:~/runAsyncBenchmark.sh --zone europe-west3-c 

#Start script
gcloud compute ssh $instanceName --zone europe-west3-c -- "tmux new -d './runAsyncBenchmark.sh'"

#Check done.txt file every 5 mins 
complete=0
while [ $complete -eq 0 ]
do
	sleep 5m
	result="$(gcloud compute ssh $instanceName --zone=europe-west3-c -- 'cat done.txt')"
	if [[ $result == *"Done"* ]]; then
	  complete=1
	fi	
done


echo "3/4 Microbenchmark done."
exit 0