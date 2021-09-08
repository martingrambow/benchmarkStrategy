commit=$1
instanceName="victoriametrics1"
zone=--zone="europe-west3-c"

echo "Will run microbenchmarks..."

test_files_tmp=$(gcloud compute ssh $instanceName $zone -- 'tmp=$(find ./VictoriaMetrics/lib -type f -name *timing_test*); echo $tmp')
IFS=' ' read -ra test_files <<< "$test_files_tmp"
echo $test_files

# tests_tmp=$(gcloud compute ssh $instanceName $zone -- 'tmp=$(GO111MODULE=on go test -mod=vendor -bench=. ./VictoriaMetrics/lib/... -list=Benchmark | grep  "Benchmark*"); echo $tmp')
gcloud compute ssh $instanceName $zone -- 'wget -c https://dl.google.com/go/go1.16.3.linux-amd64.tar.gz  -O - | sudo tar -xz -C /usr/local'
gcloud compute ssh $instanceName $zone -- 'sudo apt install -y gcc'
gcloud compute ssh $instanceName $zone -- 'echo "export PATH=$PATH:/usr/local/go/bin" | sudo tee -a /etc/environment'
gcloud compute ssh $instanceName $zone -- 'echo "export GOPATH=$HOME/go" | sudo tee -a /etc/environment'
gcloud compute ssh $instanceName $zone -- 'echo "export GOROOT=/usr/local/go" | sudo tee -a /etc/environment'

tests_tmp=$(gcloud compute ssh $instanceName $zone -- 'tmp=$(cd VictoriaMetrics; GO111MODULE=on go test -mod=vendor -bench=. ./lib/... -list=Benchmark | grep  "Benchmark*"); echo $tmp')

IFS=' ' read -ra tests<<< "$tests_tmp"


echo "Found ${#tests[@]} tests in ${#test_files[@]} files"
echo "Done."
exit 0
