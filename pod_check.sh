#!/bin/bash

number=1
while [[ $number -le 12 ]]
do
  echo "${number}0 sec checking..."
  sleep 1
  cmd=$(kubectl --kubeconfig $1 -n jenkins get pods -l app=jenkins -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
  echo "kubectl pod status output: $cmd"
  if [[ $cmd = "True2" ]]; then echo "Pod is ready"; break; fi
  if [[ $number -eq 4 ]]; then echo "Pod awaiting timeout"; exit 1; fi
  let number++
done

