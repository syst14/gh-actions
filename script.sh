#!/bin/bash

echo "hi from script"
/usr/local/bin/kubectl version --client
/usr/local/bin/kubectl config get-contexts
/usr/local/bin/kubectl --kubeconfig jenkins_kubeconfig -n jenkins get pods