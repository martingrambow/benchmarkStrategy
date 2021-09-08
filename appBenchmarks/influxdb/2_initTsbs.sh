echo "init tsbs start"

run=$1
number=$2
instanceName="tsbs-r"$run"n"$number

gcloud compute instances create $instanceName --source-instance-template="microbench-standard-2" --zone="europe-west3-c"
sleep 1m

gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q language-pack-de'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'

#install git, docker, etc.
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt-get install -y -q git'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt install -y -q golang-go'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'sudo apt upgrade -y'

#install benchmarking client
gcloud compute ssh $instanceName --zone europe-west3-c -- 'go get github.com/martingrambow/influxdb-comparisons/cmd/bulk_data_gen github.com/martingrambow/influxdb-comparisons/cmd/bulk_load_influx'
gcloud compute ssh $instanceName --zone europe-west3-c -- 'go get github.com/martingrambow/influxdb-comparisons/cmd/bulk_query_gen github.com/martingrambow/influxdb-comparisons/cmd/query_benchmarker_influxdb'

echo "2/4 TSBS init done."
exit 0
