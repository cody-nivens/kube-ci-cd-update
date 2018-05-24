#!/bin/bash

read -p "Press [Enter] key to stop and delete minikube and install jenkins minikube..."
minikube stop
minikube delete
sudo rm -rf ~/.minikube
sudo rm -rf ~/.kube
minikube start --memory 4000 --cpus 2 --kubernetes-version v1.10.3
minikube addons enable heapster
minikube addons enable ingress

sleep 30
minikube service kubernetes-dashboard --namespace kube-system

# Setup registry
kubectl apply -f registry/registry.yml
kubectl rollout status deployments/registry

# Wait for registry to finish initializing
sleep 30

# Setup proxy to registry
./registry/setup_reg_proxy
minikube service registry-ui

# These are necessary for jenkins to deploy the hello-kenzan app.
kubectl create sa jenkins
kubectl create clusterrolebinding jenkins --clusterrole cluster-admin --serviceaccount=jenkins:default

# Build jenkins and push to registry
cd jenkins
./build_jenkins.sh

# Wait for registry to finish with jenkins
sleep 30

# Add newly built jenkins to cluster

kubectl apply -f jenkins.yml
kubectl rollout status deployments/jenkins --namespace jenkins

# Wait for jenkins to initialize
sleep 30
minikube service jenkins --namespace jenkins

# Get initial password
./get_jenkins_passwd.sh

cd ..


echo "Follow the project the linux.com article noted in the README.md file,"
echo "build and deploy a hello-kenzan application."
echo ""
echo "To access it via a web browser, type the following command:"
echo ""
echo "minikube service hello-kenzan --namespace jenkins"
echo ""
