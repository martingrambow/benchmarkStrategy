########################################################
### SETUP SUTs #########################################
########################################################

run=$1
number=$2
SUTinstanceName="influx-r"$run"n"$number
TSBSinstanceName="tsbs-r"$run"n"$number

SUT_IP="$(gcloud compute instances describe $SUTinstanceName --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $SUT_IP

#Run Old InfluxDB Container		
echo "Start InfluxDB..."								

cmd="sudo docker run -d -v /home/pi/influxdataOld:/var/lib/influxdb \
						-v /home/pi/influxdbOld/:/root/go/src/github.com/influxdata/influxdb \
						-v /home/pi/sharedOld/:/shared \
						-p 8086:8086 -p 80:80 \
						influxdb-old"
echo $cmd
gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- $cmd	
echo "Container started (old version) on port 8086"
lines="$(gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- 'sudo docker container ls | grep influxdb-old')"
echo $lines 
container=$(echo $lines | cut -f 1 -d " ")
echo "Container id (old version) is " $container

sleep 10s

echo "Init influx.."
cmd="sudo docker exec $container influx setup \
						--username my-user \
						--password my-password \
						--org benchmark \
						--bucket my-bucket \
						--token my-super-secret-auth-token \
						--force"
						
echo $cmd
gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- $cmd	

echo "Initialization of old version done."

#Run New InfluxDB Container		
echo "Start InfluxDB..."								

cmd="sudo docker run -d -v /home/pi/influxdataNew:/var/lib/influxdb \
						-v /home/pi/influxdbNew/:/root/go/src/github.com/influxdata/influxdb \
						-v /home/pi/sharedNew/:/shared \
						-p 8087:8086 -p 81:80 \
						influxdb-new"
echo $cmd
gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- $cmd	
echo "Container started (new version) on port 8087"
lines="$(gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- 'sudo docker container ls | grep influxdb-new')"
echo $lines 
container=$(echo $lines | cut -f 1 -d " ")
echo "Container id (new version) is " $container

sleep 10s

echo "Init influx.."
cmd="sudo docker exec $container influx setup \
						--username my-user \
						--password my-password \
						--org benchmark \
						--bucket my-bucket \
						--token my-super-secret-auth-token \
						--force"
						
echo $cmd
gcloud compute ssh $SUTinstanceName --zone europe-west3-c -- $cmd	

echo "Initialization of new version done."

sleep 10s

########################################################
### Generate Load ######################################
########################################################

dbName=benchmark_db


#Generate load (inserts) for the devops use case
# 100 servers in server farm (scale-var)
# each server generates a data point (including measurements and tags) each 10 seconds (sampling-interval)
# simulate 1 days (timestamp-start and timestamp-end)
echo "Generate inserts..."
cmd="./go/bin/bulk_data_gen \
	-format influx-bulk \
	-use-case='devops' \
	-seed=1337 \
	-scale-var=100 \
	-sampling-interval='60s' \
	-timestamp-start='2021-05-01T00:00:00Z' \
	-timestamp-end='2021-05-08T00:00:00Z' > inserts.txt"
echo $cmd
gcloud compute ssh $TSBSinstanceName --zone europe-west3-c -- $cmd
echo "Done."

#1008 = one query per 10min for 7 days (1*6*24*7)
echo "Generate queries..."
cmd="./go/bin/bulk_query_gen \
	-db='$dbName' \
	-format='influx-flux-http' \
	-queries=1008 \
	-query-interval-type='window' \
	-query-type='1-host-12-hr' \
	-scale-var=100 \
	-seed=1337 \
	-use-case='devops' \
	-query-interval=6h0m0s \
	-timestamp-start='2021-05-01T00:00:00Z' \
	-timestamp-end='2021-05-08T00:00:00Z' > queries1.txt"
echo $cmd
gcloud compute ssh $TSBSinstanceName --zone europe-west3-c -- $cmd
#168 = one query per hour for 7 days (1*24*7)
cmd="./go/bin/bulk_query_gen \
	-db='$dbName' \
	-format='influx-flux-http' \
	-queries=168 \
	-query-interval-type='window' \
	-query-type='groupby' \
	-scale-var=100 \
	-seed=1337 \
	-use-case='devops' \
	-query-interval=6h0m0s \
	-timestamp-start='2021-05-01T00:00:00Z' \
	-timestamp-end='2021-05-08T00:00:00Z' > queries2.txt"
echo $cmd
gcloud compute ssh $TSBSinstanceName --zone europe-west3-c -- $cmd

echo "Done."

########################################################
### Run Duet Benchmark #################################
########################################################

#Copy benchmark script to tsdb instance
gcloud compute scp $PWD/duetBenchmark.sh $TSBSinstanceName:~/duetBenchmark.sh --zone europe-west3-c 

#Run duet benchmark script
cmd="./duetBenchmark.sh "$SUT_IP":8086 "$SUT_IP":8087"
echo $cmd
gcloud compute ssh $TSBSinstanceName --zone europe-west3-c -- $cmd
echo "3/4 Benchmark done."
exit 0