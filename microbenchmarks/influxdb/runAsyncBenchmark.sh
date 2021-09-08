echo "Start"

source .profile; ./go/bin/goabs -c abs_config.json -d -o microbenchResults.csv > abs.log

echo "Done" > done.txt