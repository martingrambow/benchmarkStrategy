echo "init tsbs start"

gcloud compute instances create tsbs --source-instance-template="microbench-standard-2" --zone="europe-west3-c"
sleep 1m

gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt-get install -y language-pack-de'
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt upgrade -y'

#install git, docker, etc.
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt-get install -y git'
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt install -y golang-go'
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh tsbs --zone europe-west3-c -- 'sudo apt upgrade -y'

#install benchmarking client
gcloud compute ssh tsbs --zone europe-west3-c -- 'go get github.com/influxdata/influxdb-comparisons/cmd/bulk_data_gen github.com/influxdata/influxdb-comparisons/cmd/bulk_load_influx'
gcloud compute ssh tsbs --zone europe-west3-c -- 'go get github.com/influxdata/influxdb-comparisons/cmd/bulk_query_gen github.com/influxdata/influxdb-comparisons/cmd/query_benchmarker_influxdb'

echo "2/4 TSBS init done."

exit 0
