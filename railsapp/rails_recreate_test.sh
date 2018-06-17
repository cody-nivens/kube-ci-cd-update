#!/bin/bash

. ./.kdr_env

MARIADB_IMAGE="docker.io/bitnami/mariadb:10.1.33"
db_host="mariadb-mariadb.db-apps.svc.cluster.local"

# Drop old database if it exists; Create test database; grant rights to use it"
QUERY="drop database if exists ${db_name}_test; create database ${db_name}_test; GRANT ALL ON ${db_name}_test.* TO '${db_user}'@'%';"

kubectl run mariadb-mariadb-client --image  ${MARIADB_IMAGE} --namespace db-apps --command -- mysql -h ${db_host} -uroot -p${root_pass} mysql -e "${QUERY}"

