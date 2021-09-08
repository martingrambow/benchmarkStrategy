runQueries() {
	ipAndPort=$1
	querySet=$2
	name=$3

	tsbs_run_queries_victoriametrics --file=$DATA_PATH/queries${querySet}.txt \
		--urls="http://$ipAndPort" \
		--latencies-file=results/latenciesQueries${querySet}${name}.csv  \
		--print-interval="500" \
		--workers=10 | tee results/logQueries${querySet}${name}.log
}

########################################################
### SETUP ##########################################
########################################################

SUT_IP=$1
SET=$2



oldSutIpAndPort=$SUT_IP':8428'
newSutIpAndPort=$SUT_IP':8429'

########################################################
### Run Benchmark ######################################
########################################################
echo "Run query set $SET..."

runQueries $oldSutIpAndPort $SET "Old" &
runQueries $newSutIpAndPort $SET "New" &

wait
echo "Done."
