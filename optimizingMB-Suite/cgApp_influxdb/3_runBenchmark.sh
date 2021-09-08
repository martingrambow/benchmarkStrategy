########################################################
### SETUP SUT ##########################################
########################################################


#Run InfluxDB Container		
echo "Start InfluxDB..."								

cmd="sudo docker run -d -v /home/pi/influxdata:/var/lib/influxdb \
						-v /home/pi/influxdb/:/root/go/src/github.com/influxdata/influxdb \
						-v /home/pi/shared/:/shared \
						-p 8086:8086 -p 80:80 \
						influxdb-builder"
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd	
echo "Container started"
lines="$(gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo docker container ls | grep influx')"
echo $lines 
container=$(echo $lines | cut -f 1 -d " ")
echo "Container id is " $container

SUT_IP="$(gcloud compute instances describe influx1 --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $SUT_IP

echo "Will benchmark "$SUT_IP

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
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd	

echo "Initialization done."

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
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd
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
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd
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
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd

echo "Done."

########################################################
### Run Benchmark ######################################
########################################################


echo "run inserts..."
cmd="./go/bin/bulk_load_influx \
	-batch-size=60 \
	-file=inserts.txt \
	-urls='http://$SUT_IP:8086' \
	-token='my-super-secret-auth-token' \
	-db='$dbName' \
	-organization='benchmark' \
	-do-abort-on-exist=false \
	-do-db-create=true \
	-workers=10"
echo $cmd
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd
echo "Done."


echo "Run queries..."
cmd="./go/bin/query_benchmarker_influxdb \
	-file=queries1.txt \
	-token='my-super-secret-auth-token' \
	-urls='http://$SUT_IP:8086' \
	-organization='benchmark' \
	-workers=10"	
echo $cmd
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd
cmd="./go/bin/query_benchmarker_influxdb \
	-file=queries2.txt \
	-token='my-super-secret-auth-token' \
	-urls='http://$SUT_IP:8086' \
	-organization='benchmark' \
	-workers=10"	
echo $cmd
gcloud compute ssh tsbs --zone europe-west3-c -- $cmd
echo "Done."

#Stop influxdb container

cmd="sudo docker container stop ${container}"
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd

echo "3/4 Benchmark done."
exit 0