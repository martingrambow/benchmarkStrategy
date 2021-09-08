#!/bin/bash

#gcloud config set project microbenchmarkevaluation


echo "installing software..."
#install git, docker, etc.
sudo apt-get update
sudo apt-get install -y git make
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update; sudo apt-get install -y docker-ce docker-ce-cli containerd.io

#Start docker
sudo service docker start

echo "checking out repository..."
repository_name='VictoriaMetrics'
commit=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/commit -H "Metadata-Flavor: Google")
#Clone and reset influxdb
git clone https://github.com/VictoriaMetrics/VictoriaMetrics.git
git -C ./$repository_name reset --hard $commit

#Insert "runtime/pprof" import line
importLine="$(grep -nr -m 1 ")" VictoriaMetrics/app/victoria-metrics/main.go)"
importLine=$(echo $importLine | cut -d: -f1)
sed -i ${importLine}'i "runtime/pprof"' VictoriaMetrics/app/victoria-metrics/main.go

#Insert code instrumentation which will generate the pprof profile
main="$(grep -nr "main()" VictoriaMetrics/app/victoria-metrics/main.go)"
line=$(echo $main | cut -d: -f1)
line=$((line+1))
echo $line

sed -i ${line}'i fmt.Println("Main entry point started")' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i f, err := os.Create("shared/cpuRaw.pprof")' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i if err != nil {' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i 	fmt.Fprintf(os.Stderr, "Could not open trace file: %v\\n", err)' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i 	os.Exit(1)' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i }' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i err = pprof.StartCPUProfile(f)' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i if err != nil {' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i 	fmt.Fprintf(os.Stderr, "Could not start tracing: %v\\n", err)' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i 	os.Exit(1)' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i }' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

sed -i ${line}'i defer pprof.StopCPUProfile()' VictoriaMetrics/app/victoria-metrics/main.go
echo $cmd
line=$((line+1))

#Print instrumented file
echo "################################################"
echo "new main.go file:"
cat VictoriaMetrics/app/victoria-metrics/main.go
echo "################################################"


#build docker image for current commit
sudo PKG_TAG=benchmark make -C $repository_name package-victoria-metrics
sudo docker images
touch /etc/startup_script_finished
echo "1/4 init VictoriaMetrics done."
exit 0
