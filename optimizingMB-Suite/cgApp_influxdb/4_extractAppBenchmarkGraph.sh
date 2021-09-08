echo "Will extract graph..."
commit="$1.pprof"

#Get pprof profile file
gcloud compute scp influx1:~/shared/cpuRaw.pprof $PWD/$commit --zone europe-west3-c 

go tool pprof -nodecount=3000 --nodefraction=0.002 --edgefraction=0.0 -svg $commit
go tool pprof -nodecount=3000 --nodefraction=0.0 --edgefraction=0.0 -dot $commit > $1.dot

echo "4/4 extract profile done."
exit 0