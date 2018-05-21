#!/bin/bash

echo "**************************************************************************"
echo "**************************************************************************"
echo ""
echo "  Jenkins admin password"
echo ""
kubectl exec -it `kubectl get pods --namespace jenkins --selector=app=jenkins  --output=jsonpath={.items..metadata.name}` --namespace jenkins  \
    cat /root/.jenkins/secrets/initialAdminPassword
echo ""
echo "**************************************************************************"
echo "**************************************************************************"
