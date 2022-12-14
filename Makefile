ifeq ($(NO_CACHE), true)
DOCKER_ARGS="--no-cache"
endif

all: help

clean: ## Clean up any built resources
	docker rmi $$(docker images -q -f "reference=$(IMAGE)") || true

kubectl: ## Pin the version for kubectl
	curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

deploy_stage: SHELL:=/bin/bash
deploy_stage: kubectl ## Deploy canary staging Jenkins pod to the separate K8s cluster namespace
	@echo "deploy_stage is $$0"
	/usr/local/bin/kubectl version --client
	number=1 ; while [[ $$number -le 12 ]] ; do \
		echo $$number ; \
		sleep 2 ; \
		cmd=$(shell echo True) ; \
		if [[ $$cmd = "True" ]]; then echo "Pod is ready"; break; fi ; \
		if [[ $$number -eq 4 ]]; then echo "Pod awaiting timeout" ; \
			/usr/local/bin/kubectl version --client; exit 1; fi ; \
		let number++ ; \
	done ; \
	echo "post action"
	/usr/local/bin/kubectl version --client

test: SHELL:=/bin/bash
test: kubectl
	$(shell /usr/local/bin/aws eks --region us-east-2 update-kubeconfig --name $(K8S_CLUSTER_NAME) --kubeconfig jenkins_kubeconfig) ; \
	/usr/local/bin/kubectl --kubeconfig jenkins_kubeconfig get namespaces
	/usr/local/bin/kubectl --kubeconfig jenkins_kubeconfig -n jenkins get po
	number=1 ; while [ $$number -le 2 ] ; do \
		sleep 1 ; \
		whereis aws ; \
		cmd=$(shell /usr/local/bin/kubectl --kubeconfig jenkins_kubeconfig -n jenkins get pods -l app=jenkins -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') ; \
		echo $$cmd ; \
		let number++ ; \
	done ; \
	echo "post action"
	/usr/local/bin/kubectl --kubeconfig jenkins_kubeconfig -n jenkins get svc

last: kubectl
	/usr/local/bin/aws eks --region us-east-2 update-kubeconfig --name $(K8S_CLUSTER_NAME) --kubeconfig jenkins_kubeconfig
	bash -c "./pod_check.sh jenkins_kubeconfig jenkins"

script:
	bash -c "./pod_check.sh jenkins_kubeconfig jenkins"


local:
	bash -c "./pod_check.sh ~/jenkins_tmp jenkins"

deploy_script: kubectl
	echo "start"
	$(shell ./script.sh)

# Cute hack thanks to:
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Display this help text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all deploy_stage clean help
