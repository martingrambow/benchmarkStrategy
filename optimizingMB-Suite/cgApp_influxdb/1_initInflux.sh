#gcloud config set project microbenchmarkevaluation

commit=$1
echo "Init Influx start (commit is "$commit")"

#create and get Influx1 instance
#gcloud compute instances create influx1 --async --source-instance-template="microbench-small-2" --zone="europe-west3-c"
gcloud compute instances create influx1 --source-instance-template="microbench-standard-2" --zone="europe-west3-c"
sleep 40s

#Get and Save IP
IP="$(gcloud compute instances describe influx1 --zone='europe-west3-c' --format='get(networkInterfaces[0].accessConfigs[0].natIP)')"
echo "SUT IP is " $IP


#install git, docker, etc.
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt upgrade -y'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt-get install -y language-pack-de'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt-get install -y git'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt install -y apt-transport-https ca-certificates curl software-properties-common'
gcloud compute ssh influx1 --zone europe-west3-c -- 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt update'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt upgrade -y'
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo apt install -y docker-ce'

#Start docker
gcloud compute ssh influx1 --zone europe-west3-c -- 'sudo service docker start'

#Clone and reset influxdb
gcloud compute ssh influx1 --zone europe-west3-c -- 'git clone https://github.com/influxdata/influxdb.git'
gcloud compute ssh influx1 --zone europe-west3-c -- 'mkdir shared'
gcloud compute ssh influx1 --zone europe-west3-c -- 'cd influxdb; git checkout 2.0'
cmd="cd influxdb; git reset --hard $commit"
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd

#Insert "runtime/pprof" import line
brackets="$(gcloud compute ssh influx1 --zone europe-west3-c -- 'grep -nr ")" influxdb/cmd/influxd/main.go')"
for bracket in $brackets
do
  if [[ $bracket == *":)"* ]]; then
    # Found first one -> end of import
	ImportLine=$bracket
	break     
  fi
done

ImportLine=$(echo $ImportLine | cut -d: -f1)
cmd='sed -i '\'${ImportLine}'i "runtime/pprof"'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd

#Insert code instrumentation which will generate the pprof profile
main="$(gcloud compute ssh influx1 --zone europe-west3-c -- 'grep -nr "main()" influxdb/cmd/influxd/main.go')"
line=$(echo $main | cut -d: -f1)
line=$((line+1))
echo $line

cmd='sed -i '\'${line}'i fmt.Println("Main entry point started")'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i f, err := os.Create("shared/cpuRaw.pprof")'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i if err != nil {'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i 	fmt.Fprintf(os.Stderr, "Could not open trace file: %v\\n", err)'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i 	os.Exit(1)'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i }'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i err = pprof.StartCPUProfile(f)'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i if err != nil {'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i 	fmt.Fprintf(os.Stderr, "Could not start tracing: %v\\n", err)'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i 	os.Exit(1)'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i }'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

cmd='sed -i '\'${line}'i defer pprof.StopCPUProfile()'\'' influxdb/cmd/influxd/main.go'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd
line=$((line+1))

#Print instrumented file
echo "################################################"
echo "new main.go file:"
gcloud compute ssh influx1 --zone europe-west3-c -- 'cat influxdb/cmd/influxd/main.go'
echo "################################################"

#increase yarn network-timeout 
makeline="$(gcloud compute ssh influx1 --zone europe-west3-c -- 'grep -nr "RUN make" influxdb/Dockerfile')"
makeline=$(echo $makeline | cut -d: -f1)
echo $makeline

cmd='sed -i '\'${makeline}'i RUN yarn config set network-timeout 300000'\'' influxdb/Dockerfile'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd

#Increase Javascript heap memory
makeline=$((makeline+1))
#cmd='sed -i '\'${makeline}'i RUN export NODE_OPTIONS=--max_old_space_size=4096'\'' influxdb/Dockerfile'
cmd='sed -i '\'${makeline}'i ENV NODE_OPTIONS=--max_old_space_size=4096'\'' influxdb/Dockerfile'
echo $cmd
gcloud compute ssh influx1 --zone europe-west3-c -- $cmd

echo "################################################"
#Print new dockerfile
echo "new Dockerfile:"
gcloud compute ssh influx1 --zone europe-west3-c -- 'cat influxdb/Dockerfile'
echo "################################################"

#Build Dockerfile (target in Dockerfile is influx)
gcloud compute ssh influx1 --zone europe-west3-c -- 'cd influxdb; sudo docker build -f Dockerfile --target influx -t influxdb-builder /home/pi/influxdb/'

echo "1/4 init influx done."
exit 0