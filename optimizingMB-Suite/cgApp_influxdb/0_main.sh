commit="767b431"

./1_initInflux.sh $commit 

./2_initTsbs.sh

./3_runBenchmark.sh

./4_extractAppBenchmarkGraph.sh $commit