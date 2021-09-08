
runInserts() {
	ipAndPort=$1
	set=$2

	tsbs_load_victoriametrics --urls="http://$ipAndPort/write" \
	--workers=4 --batch-size=400 --file="$DATA_PATH/inserts${set}.txt"
}

runQueries() {
	ipAndPort=$1
	querySet=$2

	tsbs_run_queries_victoriametrics --file=$DATA_PATH/queries${querySet}.txt \
		--urls="http://$ipAndPort" \
		--print-interval="500" \
		--workers=10 | tee results/logQueries${querySet}.log
}


########################################################
### SETUP SUT ##########################################
########################################################

SUT_IP=$1


echo "Initialization done."

sleep 10s


mkdir -p ~/shared
sutIpAndPort=$SUT_IP':8428'

########################################################
### Run Benchmark ######################################
########################################################
echo "run inserts..."
runInserts $sutIpAndPort "1"

runInserts $sutIpAndPort "2"
echo "Done."


echo "run queries..."
runQueries $sutIpAndPort "1"

runQueries $sutIpAndPort "2"
echo "Done."



echo "3/4 Benchmark done."
exit 0
