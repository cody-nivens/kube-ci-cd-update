# Updates to the Kubernetes-CI-CD

After a year, things can move so swaftly.  This repo implements jenkins in minikube allowing for deployment of applications into kubernetes.

I started reading [Linux.com:Set Up a CI/CD Pipeline with Kubernetes Part 1: Overview](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/5/set-cicd-pipeline-kubernetes-part-1-overview) to learn more about Kubernetes and Jenkins 2.  In deployment, Jenkins bombed because as is often the case, things got out of date.

I recreated the Dockerfile for (docker.io/chadmoon/jenkins-docker-kubectl) using [dockerfile-from-image](https://stackoverflow.com/questions/19104847/how-to-generate-a-dockerfile-from-an-image?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).  I modified the script to include adding plugins to the container image before running it in a pod.  Additionally, I added a groovy script that in conjunction with the start up script for the container create an admin user and enable security.

Now, running the start_kube.sh script cleans out the current minikube cluster and replaces it with a kubernetes with addons to minikube for ingress and monitoring and a registry and jenkins which are built and deployed into the cluster.
Additionally to support application servers and developers, two helm charts are started in the db-apps namespace:  mariadb and phpmyadmin.

Ideally, to properly run minikube needs 8GB of ram and 2 cpus.  The host machine should be 16GB ram.  Docker and VirtualBox are required.  Docker must be running.

The start_kube.sh uses 4GB and 2 CPUs which brings up a cluster capible of handling itself, Jenkins, the registry and an application.  More than that requires more memory.

---
After Jenkins in up and running, doing the first extercise on [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2) is possible.  

* [https://github.com/cody-nivens/kubernetes-ci-cd.git](https://github.com/cody-nivens/kubernetes-ci-cd.git) -- A clone of [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2) slightly modified :).

* [https://github.com/cody-nivens/rothstock.git](https://github.com/cody-nivens/rothstock.git) -- An example of a Rails application is what I created to illustrate how a Rails environment is handled with jobs to perform rake commands on the database.

To setup for a Rails application, a setup script needs to be run.  This script starts helm on the cluster and uses helm to install MariaDB and PHPMyAdmin as well as environment variables for running the application, a job to initialize the database and a job to run tests. 
```
./railsapp/start_railsapp.sh
```
Use the following to access the application in minikube.
```bash
minikube service railsapp-service
```

---
To aid with database operation, Phpmyadmin is deployed to the cluster.  The following commands allow for using your browser to access Phpmyadmn from localhost.  The sofware only works on 127.0.0.1.
```bash
export POD_NAME=$(kubectl get pods --namespace db-apps -l "app=phpmyadmin,release=phpmyadmin" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace db-apps $POD_NAME 8080:80
```
Use  http://127.0.0.1:8080 in your browser to access the database engine.  The root password is found in .kdr_env in the directory where start_kube.sh is run.
The password can also be gotten from Kubernetes secrets vault.
```bash
kubectl get secret db-root-pass -o jsonpath='{.data.password}'|base64 --decode
```
