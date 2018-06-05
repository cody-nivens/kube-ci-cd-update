#!/bin/bash -e

randomstring () {
  COUNT=${1:-10}
  random_string=`date +%s | sha256sum | base64 | head -c $COUNT`
}

randomstring 10
root_pass=$random_string

echo ""
echo "Please enter or accept the following passwords for using the Rails App application"
echo ""
read -e -p "MySQL root password? [${root_pass}] " password
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
read -e -p "MySQL db_user password? [${db_user_pass}] " password
if [ ! -z "$password" ] ; then
  db_user_pass=$password
fi

db_name='user_database'
read -e -p "MySQL user database name? [${db_name}] " answer
if [ ! -z "$answer" ] ; then
  db_name=$answer
fi

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

rm -f .kdr_env
echo "root_pass=\"${root_pass}\"" >> .kdr_env
echo "db_user=\"${db_user}\"" >> .kdr_env
echo "db_user_pass=\"${db_user_pass}\"" >> .kdr_env
echo "db_name=\"${db_name}\"" >> .kdr_env

#if [ 1 == 0 ] ; then
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

helm init

kubectl rollout status deployments/tiller-deploy --namespace kube-system

#fi
helm install --name mariadb \
  --set rootUser.password=${root_pass},db.user=${db_user},db.name=${db_name},db.password=${db_user_pass} \
    stable/mariadb

db_url=`echo "mysql2://${db_user}:${db_user_pass}@mariadb-mariadb:3306/${db_name}"|base64`

set +e
kubectl create secret generic db-root-pass --from-literal=password=${root_pass}
kubectl create secret generic db-user-pass --from-literal=password=${db_user_pass}
kubectl create secret generic db-user --from-literal=username=${db_user}
kubectl create secret generic db-name --from-literal=name=${db_name}

kubectl create secret generic railsapp-secrets --from-literal=secret-key-base=50dae16d7d1403e175ceb2461605b527cf87a5b18479740508395cb3f1947b12b63bad049d7d1545af4dcafa17a329be4d29c18bd63b421515e37b43ea43df64

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


