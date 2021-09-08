#!/bin/bash

commit="767b431647"
resultPath="resultsMicro/cg"
mkdir -p $resultPath

./1_initSUT.sh $commit > $resultPath/initSUT.log 2>&1

#Init custom GoABS Tool
./2_initTool.sh > $resultPath/initTool.log 2>&1

#Run Microbenchmark suite
./3_runBenchmark.sh > $resultPath/runBenchmark.log 2>&1

#Download results 
./4_getResults.sh $resultPath > $resultPath/getResults.log 2>&1

echo "Experiment done."