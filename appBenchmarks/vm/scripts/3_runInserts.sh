
runInserts() {
	ipAndPort=$1
	name=$2
	set=$3

	tsbs_load_victoriametrics --urls="http://$ipAndPort/write" \
	--workers=4 --batch-size=400 --file="$DATA_PATH/inserts${set}.txt" \
	--latencies-file=results/latenciesInserts${set}${name}.csv 2>&1 | tee results/logInserts${set}${name}.log
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
echo "run inserts..."

runInserts $oldSutIpAndPort "Old" $SET &
runInserts $newSutIpAndPort "New" $SET &

wait

curl -g "$oldSutIpAndPort/internal/resetRollupResultCache"
curl -g "$newSutIpAndPort/internal/resetRollupResultCache"

echo "Done."
