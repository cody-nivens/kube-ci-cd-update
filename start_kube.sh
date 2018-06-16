#!/bin/bash -e

KUBE_VERSION="v1.10.4"
KUBE_MEMORY=4000
KUBE_CPUS=2

RAILS_KEY=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 128 | head -n 1`
RAILS_KEY_TEST=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 128 | head -n 1`

MARIADB_IMAGE="docker.io/bitnami/mariadb:10.1.33"

function usage()
{
    echo "if this was a real script you would see something useful here"
    echo ""
    echo "./simple_args_parsing.sh"
    echo "\t-h --help"
    echo "\t--openall"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
#        --environment)
#            ENVIRONMENT=$VALUE
#            ;;
        --openall)
            OPEN_ALL=1
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

echo ""
while true; do
    read -e -p "Do you wish to to stop and delete minikube and install jenkins minikube? [yN] " yn
    case ${yn:0:1} in
        y|Y )
            break
        ;;
        * )
            exit
        ;;
    esac
done

minikube stop
minikube delete
sudo rm -rf ~/.minikube
sudo rm -rf ~/.kube

# Start Kubernetes using minikube and add useful items
minikube start --memory ${KUBE_MEMORY} --cpus ${KUBE_CPUS} --kubernetes-version ${KUBE_VERSION}
minikube addons enable heapster
minikube addons enable ingress

# Setup registry
kubectl apply -f registry/registry.yml
kubectl rollout status deployments/registry

# Wait for registry to finish initializing
sleep 30
# Setup proxy to registry
./registry/setup_reg_proxy

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
if [ "$OPEN_ALL" != "" ] ; then
sleep 5
minikube service monitoring-grafana --namespace kube-system
sleep 5
minikube service registry-ui
fi
sleep 5
minikube service kubernetes-dashboard --namespace kube-system
sleep 5
minikube service jenkins --namespace jenkins

