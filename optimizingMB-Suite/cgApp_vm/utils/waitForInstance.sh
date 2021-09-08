#!/bin/bash

instanceName=$1
zone=$2

startup_script_finished='false'

while [[ $startup_script_finished != *"true"* ]]; do
  echo "waiting for $instanceName..."
  sleep 20s
  IP=$(gcloud compute instances list | awk '/'$instanceName'/ {print $5}')
  up=$(nmap --host-timeout 1s $IP -p 22)
  if [[ $up == *"open"* ]]; then
    startup_script_finished=$(gcloud compute ssh $instanceName $zone -- \
      'if [ -f /etc/startup_script_finished ];  then echo "true"; else echo "false"; fi')
    echo $startup_script_finished
  else
    continue
  fi

done
