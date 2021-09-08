########################################################
### SETUP SUTs #########################################
########################################################

oldSutIpAndPort=$1
newSutIpAndPort=$2
dbName=benchmark_db

########################################################
### Run Duet Benchmark #################################
########################################################
./go/bin/bulk_load_influx -h
./go/bin/query_benchmarker_influxdb -h

echo "run inserts..."
./go/bin/bulk_load_influx \
	-batch-size=60 \
	-file=inserts.txt \
	-urls="http://$oldSutIpAndPort" \
	-token='my-super-secret-auth-token' \
	-db="$dbName" \
	-organization='benchmark' \
	-do-abort-on-exist=false \
	-do-db-create=true \
	-workers=10 \
	-print-interval=1000 \
	-progress-interval=60s \
	-telemetry-stderr \
	-latenciesFile=latenciesInsertsOld.csv > logInsertsOld.log &
	
./go/bin/bulk_load_influx \
	-batch-size=60 \
	-file=inserts.txt \
	-urls="http://$newSutIpAndPort" \
	-token='my-super-secret-auth-token' \
	-db="$dbName" \
	-organization='benchmark' \
	-do-abort-on-exist=false \
	-do-db-create=true \
	-workers=10 \
	-print-interval=1000 \
	-progress-interval=60s \
	-telemetry-stderr \
	-latenciesFile=latenciesInsertsNew.csv > logInsertsNew.log &
	
wait	
echo "Done."


echo "Run queries..."
./go/bin/query_benchmarker_influxdb \
	-file=queries1.txt \
	-token='my-super-secret-auth-token' \
	-urls="http://$oldSutIpAndPort" \
	-organization='benchmark' \
	-workers=10 \
	-print-interval=100 \
	-telemetry-stderr \
	-latenciesFile=latenciesQueries1Old.csv > logQueries1Old.log &
	
./go/bin/query_benchmarker_influxdb \
	-file=queries1.txt \
	-token='my-super-secret-auth-token' \
	-urls="http://$newSutIpAndPort" \
	-organization='benchmark' \
	-workers=10 \
	-print-interval=100 \
	-telemetry-stderr \
	-latenciesFile=latenciesQueries1New.csv > logQueries1New.log &

wait
	
./go/bin/query_benchmarker_influxdb \
	-file=queries2.txt \
	-token='my-super-secret-auth-token' \
	-urls="http://$oldSutIpAndPort" \
	-organization='benchmark' \
	-workers=10 \
	-print-interval=100 \
	-telemetry-stderr \
	-latenciesFile=latenciesQueries2Old.csv > logQueries2Old.log &

./go/bin/query_benchmarker_influxdb \
	-file=queries2.txt \
	-token='my-super-secret-auth-token' \
	-urls="http://$newSutIpAndPort" \
	-organization='benchmark' \
	-workers=10 \
	-print-interval=100 \
	-telemetry-stderr \
	-latenciesFile=latenciesQueries2New.csv > logQueries2New.log &
	
wait
	
echo "Done."