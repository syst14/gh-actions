#!/bin/bash

number=1
while [[ $number -le 12 ]]
do
  echo $number
  sleep 10
  cmd=$(kubectl --kubeconfig $1 -n jenkins-stage get pods -l app=jenkins-stage -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
  echo $cmd
  if [[ $cmd = "True" ]]; then echo "Pod is ready"; break; fi
  if [[ $number -eq 12 ]]; then echo "Pod awaiting timeout"; exit 1; fi
  let number++
done

