# Kubernetes-CI-CD and Ruby on Rails

This project is a minikube Kubernetes installation for the running of Rails applications.  It was created to learn more of 
Kubernetes as well as the problems of running applications involving multiple services in the cluster.

## Getting Started

```sh
git clone https://github.com/cody-nivens/kube-ci-cd-update.git
cd kube-ci-cd-update
```

### Prerequisites

This project requires at least 8GB ram and two CPU cores.  These values are used by several scripts in starting, restarting
and creating the minikube setup.

### Installing

Assuming a blank minikube setup, the following script provide for the setup of the cluster.
  1.  *restart\_kube* - shuts down minikube and restarts it with version, memory and cpus specified in the scripts.
  2.  *recreate\_kube* - cleans out the current minikube cluster and replaces it with a kubernetes cluster with memory and cpus specified in the script.  Additionally, an addon for ingress is added.

The main effort is a script to start helm, add a registry, rebuild Jenkins and add to the registry.  A second script sets up the root password for MariaDB and Redis servers and start them in the cluster..
  1.  *start\_kube* - add a registry and jenkins into an already running cluster. 
      1.  *start\_registry* - adds a registry to the cluster.  This script is called by start\_kube along with start\_jenkins
      2.  *start\_jenkins* - adds a Jenkins image to the registry and then starts Jenkins as a pod.

  2. *start\_railsapp* - starts MariaDB, PHPMyAdmin and Redis.  The root password for the database as well as the Redis passwords are stored in the Kubernetes config store.

### Deployment of applications

#### Set user name and password to databases created for the application

The  script *setup\_databases* is used to create the databases, user account and password for the application and
 stores the user name and database password in the Kubernetes config storage by namespace.  
A namespace for testing is created and the default space is used for running the application..

```sh
./setup_databases holocene
```

This will setup a test and production database for the application holocene.  
Additionally, the user account name(holocene\_db\_user), database name (holocene, holocene\_test) and password will be stored in Kubernetes' config storage.

#### Add the application to Jenkins.

1. Login to Jenkins - admin, admin are the defaults
1. Create a pipeline job selecting Pipeline as the type.
1. Click 'OK'
1. Select Pipeline tab
1. Select 'Pipeline script from SCM'
1. Selete Git from SCM
1. Add one of the repo URLs below
1. Click Save
1. Run the job.

#### Sample Applications

* [https://github.com/cody-nivens/rothstock.git](https://github.com/cody-nivens/rothstock.git) -- An example of a Rails application which illustrates how a Rails environment is handled with jobs to perform rake commands on the database as well as run tests.
* [https://github.com/cody-nivens/holocene](https://github.com/cody-nivens/holocene) -- A more inclusive application to create a book using Events on a timeline.  The app was created to help revise a book written in xml and dblatex. This application generates a PDF's of its contents using the wkhtmltopdf binary in a container.
* [https://github.com/cody-nivens/kubernetes-ci-cd.git](https://github.com/cody-nivens/kubernetes-ci-cd.git) -- A clone of [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2) slightly modified :).

Both Rothstocks and Holocene use a Jenkinsfile to do the following:
1.  Build a test image and production image pushing them to the registry.
2.  The test image is then called from a test job executing the standard tests of a Rails application.
3.  If the test job succeeds, a setup job run which generates the databases, runs the migrations and loads seed data.
4.  With the succeed of the setup job, the application is setup to run in the cluster using a deployment.

The building of the images uses two Dockerfiles for testing and production.  
The Kubernetes setup yaml files are stored in the k8s directory at the application top. 

With each run of the Jenkins job, a numbered image is pushed to the Registry for production.  For tests, only one 
image is created called 'latest' because the testing is done by a job which is deleted before the new test job is run.
THe build number is used to force Kubernetes to rollover the pods where the application is running.

##### Managing Applications

Use the following to access the application service as built by the Jenkins job.
```sh
minikube service holocene-service --url
```
PhpMyAdmin can be accessed using
```sh
helm status phpmyadmin
```
The root password can be gotten from Kubernetes secrets vault.
```sh
kubectl get secret db-root-pass -o jsonpath='{.data.password}'|base64 --decode
```
The user password for an application can be gotten from Kubernetes secrets vault.  The following gets the password for the Holocene application database user.
```sh
kubectl get secret holocene-db-user-pass -o jsonpath='{.data.password}'|base64 --decode
```

## Acknowledgements

This work was originally done for doing the first extercise on [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2).

I started reading [Linux.com:Set Up a CI/CD Pipeline with Kubernetes Part 1: Overview](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/5/set-cicd-pipeline-kubernetes-part-1-overview) to learn more about Kubernetes and Jenkins 2.  In deployment, Jenkins bombed because as is often the case, things got out of date.
I recreated the Dockerfile for (docker.io/chadmoon/jenkins-docker-kubectl) using [dockerfile-from-image](https://stackoverflow.com/questions/19104847/how-to-generate-a-dockerfile-from-an-image?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).  I modified the script to include adding plugins to the container image before running it in a pod.  Additionally, I added a groovy script that in conjunction with the start up script for the container create an admin user and enable security.

