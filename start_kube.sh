#!/bin/bash -e

KUBE_VERSION="v1.10.4"
KUBE_MEMORY=4000
KUBE_CPUS=2

RAILS_KEY="50dae16d7d1403e175ceb2461605b527cf87a5b18479740508395cb3f1947b12b63bad049d7d1545af4dcafa17a329be4d29c18bd63b421515e37b43ea43df64"
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
        --environment)
            ENVIRONMENT=$VALUE
            ;;
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

randomstring () {
  COUNT=${1:-10}
  random_string=`date +%s | sha256sum | base64 | head -c $COUNT`
}

randomstring 10
root_pass=$random_string

echo ""
echo "Please enter or accept the following passwords for using the Rails App application"
echo ""
read -e -p "MySQL root password? [<random 10 chars>] " password
if [ ! -z "$password" ] ; then
  root_pass=$password
fi

db_user='user'
read -e -p "MySQL database user name? [${db_user}] " answer
if [ ! -z "$answer" ] ; then
  db_user=$answer
fi

randomstring 10
db_user_pass=$random_string
read -e -p "MySQL db_user password? [<random 10 chars>] " password
if [ ! -z "$password" ] ; then
  db_user_pass=$password
fi

db_name='user_database'
read -e -p "MySQL user database name? [${db_name}] " answer
if [ ! -z "$answer" ] ; then
  db_name=$answer
fi

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

# Keep the keys to the kingdom
rm -f .kdr_env
echo "root_pass=\"${root_pass}\"" >> .kdr_env
echo "db_user=\"${db_user}\"" >> .kdr_env
echo "db_user_pass=\"${db_user_pass}\"" >> .kdr_env
echo "db_name=\"${db_name}\"" >> .kdr_env

minikube stop
minikube delete
sudo rm -rf ~/.minikube
sudo rm -rf ~/.kube
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
minikube service kubernetes-dashboard --namespace kube-system
sleep 5
minikube service monitoring-grafana --namespace kube-system
sleep 5
minikube service registry-ui
fi
sleep 5
minikube service jenkins --namespace jenkins

cd ..

# Add test namespace
kubectl apply --namespace app-test -f app-test-namespace.yaml

# Helm
#
helm init

kubectl rollout status deployments/tiller-deploy --namespace kube-system

helm install --name mariadb --namespace db-apps \
  --set rootUser.password=${root_pass},db.user=${db_user},db.name=${db_name},db.password=${db_user_pass} \
    stable/mariadb

# phpmyadmin for creating databases and users
#
db_host="mariadb-mariadb.db-apps.svc.cluster.local"
helm install --name phpmyadmin --namespace db-apps --set db.host=${db_host},db.port=3306,probesEnabled=false stable/phpmyadmin


# Secrets must be in each environment to be useful
#
set +e
kubectl create secret generic db-root-pass --namespace db-apps --from-literal=password=${root_pass}
kubectl create secret generic db-user-pass --namespace db-apps --from-literal=password=${db_user_pass}
kubectl create secret generic db-user --namespace db-apps --from-literal=username=${db_user}
kubectl create secret generic db-name --namespace db-apps --from-literal=name=${db_name}

kubectl create secret generic db-root-pass --namespace default --from-literal=password=${root_pass}
kubectl create secret generic db-user-pass --namespace default --from-literal=password=${db_user_pass}
kubectl create secret generic db-user --namespace default --from-literal=username=${db_user}
kubectl create secret generic db-name --namespace default --from-literal=name=${db_name}

kubectl create secret generic db-root-pass --namespace app-test --from-literal=password=${root_pass}
kubectl create secret generic db-user-pass --namespace app-test --from-literal=password=${db_user_pass}
kubectl create secret generic db-user --namespace app-test --from-literal=username=${db_user}
kubectl create secret generic db-name --namespace app-test --from-literal=name=${db_name}_test

kubectl create secret generic railsapp-secrets --namespace default --from-literal=secret-key-base=${RAILS_KEY}
kubectl create secret generic railsapp-secrets --namespace app-test --from-literal=secret-key-base=${RAILS_KEY}
set -e

echo "Follow the project the linux.com article noted in the README.md file,"
echo "build and deploy a hello-kenzan application."
echo ""
echo "To access it via a web browser, type the following command:"
echo ""
echo "minikube service hello-kenzan --namespace jenkins"
echo ""
echo "For a Rails application, use: https://github.com/cody-nivens/rothstock.git"
echo ""
echo "To access it via a web browser, type the following command:"
echo ""
echo "minikube service railsapp-service"
echo ""
echo "To access phpmyadmin, you will need to do the following:"
echo ""
echo 'export POD_NAME=$(kubectl get pods --namespace db-apps -l "app=phpmyadmin,release=phpmyadmin" -o jsonpath="{.items[0].metadata.name}")'
echo 'kubectl port-forward --namespace db-apps $POD_NAME 8080:80'
echo ""
echo "phpmyadmin will only work from http://127.0.0.1"
echo "To use:  http://127.0.0.1:8080"
