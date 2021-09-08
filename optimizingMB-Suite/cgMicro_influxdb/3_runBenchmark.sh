echo "run benchmark start"

instanceName="influx-micro-cg"

#Run suite(s)
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; go env'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'source .profile; ./go/bin/goabs -c abs_config.json -d -o microbenchResults.csv'


echo "3/4 Microbenchmark done."
exit 0