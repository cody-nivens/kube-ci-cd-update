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

db_name='user_database'
read -e -p "MySQL user database name? [${db_name}] " answer
if [ ! -z "$answer" ] ; then
  db_name=$answer
fi

randomstring 10
db_user_pass=$random_string
read -e -p "MySQL db_user password? [<random 10 chars>] " password
if [ ! -z "$password" ] ; then
  db_user_pass=$password
fi

#randomstring 10
#redis_user_pass=$random_string
#read -e -p "MySQL redis_user password? [<random 10 chars>] " password
#if [ ! -z "$password" ] ; then
#  redis_user_pass=$password
#fi

echo ""
while true; do
    read -e -p "Do you wish to install helm and install mariadb and phpmyadmin? [yN] " yn
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
echo "root_pass=\"${root_pass}\""       > .kdr_env
echo "db_user=\"${db_user}\""           >> .kdr_env
echo "db_user_pass=\"${db_user_pass}\"" >> .kdr_env
echo "db_name=\"${db_name}\""           >> .kdr_env
#echo "redis_user_pass=\"${redis_user_pass}\"" >> .kdr_env

# Add namespaces
kubectl apply --namespace app-test -f db-apps-namespace.yaml
kubectl apply --namespace app-test -f app-test-namespace.yaml

# Helm
#
helm init

kubectl rollout status deployments/tiller-deploy --namespace kube-system

# MariaDB for database for Rails apps
helm install --name mariadb --namespace db-apps \
  --set rootUser.password=${root_pass},db.user=${db_user},db.name=${db_name},db.password=${db_user_pass} \
    stable/mariadb

# phpmyadmin for creating databases and users
#
db_host="mariadb-mariadb.db-apps.svc.cluster.local"
helm install --name phpmyadmin --namespace db-apps --set db.host=${db_host},db.port=3306,probesEnabled=false stable/phpmyadmin

# Start redis - used by sidekiq
#
#helm install --name redis \
#  --set password=${redis_user_pass} \
#  --set persistence.enabled=false \
#    stable/redis

# Secrets must be in each environment to be useful
#
set +e
for namespace in default db-apps app-test ; do
    kubectl create secret generic db-root-pass --namespace ${namespace} --from-literal=password=${root_pass}
    kubectl create secret generic db-user-pass --namespace ${namespace} --from-literal=password=${db_user_pass}
    kubectl create secret generic db-user --namespace ${namespace} --from-literal=username=${db_user}
    if [ "${namespace}" == "app-test" ] ; then
        kubectl create secret generic db-name --namespace ${namespace} --from-literal=name=${db_name}_test
    else
        kubectl create secret generic db-name --namespace ${namespace} --from-literal=name=${db_name}
    fi
done

kubectl create secret generic railsapp-secrets --namespace default --from-literal=secret-key-base=${RAILS_KEY}
kubectl create secret generic railsapp-secrets --namespace app-test --from-literal=secret-key-base=${RAILS_KEY_TEST}

kubectl rollout status statefulset/mariadb-mariadb-master --namespace db-apps

sleep 60

# Drop old database if it exists; Create test database; grant rights to use it"
QUERY="drop database if exists ${db_name}_test; create database ${db_name}_test; GRANT ALL ON ${db_name}_test.* TO '${db_user}'@'%';"

kubectl run mariadb-mariadb-client --image  ${MARIADB_IMAGE} --namespace db-apps --command -- mysql -h ${db_host} -uroot -p${root_pass} mysql -e "${QUERY}"

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