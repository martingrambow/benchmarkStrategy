run=$1
number=$2
resultPath=$3
SUTinstanceName="influx-r"$run"n"$number
TSBSinstanceName="tsbs-r"$run"n"$number

SUT_IP="$(gcloud compute instances describe $SUTinstanceName --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $SUT_IP

#Copy logs to result folder
#latenciesInsertsOld.csv   
#latenciesQueries1Old.csv  
#latenciesQueries2Old.csv  
#logInsertsOld.log   
#logQueries1Old.log  
#logQueries2Old.log  
#latenciesInsertsNew.csv  
#latenciesQueries1New.csv  
#latenciesQueries2New.csv  
#logInsertsNew.log         
#logQueries1New.log  
#logQueries2New.log 


gcloud compute scp $TSBSinstanceName:~/latenciesInsertsOld.csv $resultPath/latenciesInsertsOld.csv --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/latenciesQueries1Old.csv $resultPath/latenciesQueries1Old.csv --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/latenciesQueries2Old.csv $resultPath/latenciesQueries2Old.csv --zone europe-west3-c 

gcloud compute scp $TSBSinstanceName:~/logInsertsOld.log $resultPath/logInsertsOld.log --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/logQueries1Old.log $resultPath/logQueries1Old.log --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/logQueries2Old.log $resultPath/logQueries2Old.log --zone europe-west3-c 

gcloud compute scp $TSBSinstanceName:~/latenciesInsertsNew.csv $resultPath/latenciesInsertsNew.csv --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/latenciesQueries1New.csv $resultPath/latenciesQueries1New.csv --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/latenciesQueries2New.csv $resultPath/latenciesQueries2New.csv --zone europe-west3-c 

gcloud compute scp $TSBSinstanceName:~/logInsertsNew.log $resultPath/logInsertsNew.log --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/logQueries1New.log $resultPath/logQueries1New.log --zone europe-west3-c 
gcloud compute scp $TSBSinstanceName:~/logQueries2New.log $resultPath/logQueries2New.log --zone europe-west3-c 

echo "4/4 getResults done."

echo "Shut down instances..."

gcloud compute instances delete $TSBSinstanceName --zone="europe-west3-c" --delete-disks="all" --quiet
gcloud compute instances delete $SUTinstanceName --zone="europe-west3-c" --delete-disks="all" --quiet

echo "experiment done."
exit 0