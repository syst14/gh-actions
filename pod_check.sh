#!/bin/bash

number=1
while [[ $number -le 4 ]]
do
  echo $number
  sleep 2
  cmd=$(kubectl --kubeconfig $1 -n jenkins get pods -l app=jenkins -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
  if [[ $cmd = "True" ]]; then echo "Pod is ready"; break; fi
  if [[ $number -eq 2 ]]; then echo "Pod awaiting timeout"; \
    kubectl --kubeconfig $1 -n jenkins get svc; exit 1; fi
  let number++
done

