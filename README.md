# Kubernetes-CI-CD and Ruby on Rails

This project creates a minikube Kubernetes installation for the running of Rails applications.  It was created to learn more of
Kubernetes as well as the problems of running applications involving multiple services in the cluster.

This project is associated with [https://github.com/cody-nivens/rails-ci-k8s.git](https://github.com/cody-nivens/rails-ci-k8s.git).
That project installs a generator to create the files necessary to run under this project.  Running the install script, saving to
the repo server and running using Jenkins to build, test and deliver the project as a kubernetes deployment.
The install creates a Jenkinsfile, two database and Dockerfiles for testing and production.  The Kubernetes setup yaml files are stored in the k8s directory at the application top.

## Getting Started

```sh
git clone https://github.com/cody-nivens/kube-ci-cd-update.git
cd kube-ci-cd-update
```

For the purpose of demonstrating technology, the test application to build via these instructions is https://github.com/cody-nivens/holocene.git.

### Prerequisites

This project requires at least 8GB ram and two CPU cores.  These values are used by several scripts in starting, restarting
and creating the minikube setup.

Ideally, the directory on the host machine that minikube uses to store all information would be a mounted partition using *xls* formatting.
During the build processes if two containers are being built at once, the *ext4* file format will suffer from a lack of I-Nodes causing pods to be ejected.  *Xls* disk format has a dynamic number of I-Nodes and handles the builds without a problem.

### Installing

Assuming a blank minikube setup, *the following script removes and creates a new cluster*.
  *  *create\_kube* - cleans out the current minikube cluster and replaces it with a kubernetes cluster with memory and cpus specified in the script.
Additionally, an addon for ingress is added. 
The main effort is a script to start helm, add a registry, rebuild Jenkins and add to the registry.
Additionally it sets up the root passwords for MariaDB and Redis servers as starting them in the cluster.

  *  *restart\_kube* - shuts down minikube and restarts it with version, memory and cpus specified in the scripts.

  *  *setup\_databases* - used to create the databases, user account and password for the application and
 stores the user name and database password in the Kubernetes config storage by namespace. 

```sh
./create_kube
```

### Deployment of applications

#### Set user name and password to databases created for the application:

```sh
./setup_databases holocene
```

This will setup a test and production database for the application holocene. 
Additionally, the user account name(holocene\_db\_user), database name (holocene, holocene\_test) and password will be stored in Kubernetes' config storage.

For some projects such as holocene, we need external storage for the ActiveStorage data.  The default-sources-volume files setup an NFS folder for the
Holocene depolyment to use for the ActiveStorage.

```sh
kubectl apply -f default-sources-volume.yaml
kubectl apply -f default-sources-volume-claim.yaml
```

#### Install configuration files for building a regular and test container and run those containers under Kubernetes.

Add this line to your application's Gemfile:

```ruby
gem 'rails-ci-k8s', :git => 'https://github.com/cody-nivens/rails-ci-k8s.git'
```
```sh
bundle install
rails g ci_k8s:install --help
rails g ci_k8s:install
git add .
git commit -m "Add k8s files"
git push origin master
```

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

The Jenkinsfile of the application will do the following:
1.  Build a test image and production image pushing them to the registry.
2.  The test image is then called from a test job executing the standard tests of a Rails application.
3.  If the test job succeeds, a setup job run which generates the databases, runs the migrations and loads seed data.
4.  With the succeed of the setup job, the application is setup to run in the cluster using a deployment.

With each run of the Jenkins job, a numbered image is pushed to the Registry for production.  For tests, only one
image is created called 'latest' because the testing is done by a job which is deleted before the new test job is run.
The build number is used to force Kubernetes to rollover the pods where the application is running.

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

For viewing and searching the logs, I use a setup of Elasticsearch and Kibana from https://github.com/giantswarm/kubernetes-elastic-stack

## Acknowledgements

This work was originally done for doing the first exercise on [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2).

I started reading [Linux.com:Set Up a CI/CD Pipeline with Kubernetes Part 1: Overview](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/5/set-cicd-pipeline-kubernetes-part-1-overview) to learn more about Kubernetes and Jenkins 2.  In deployment, Jenkins bombed because as is often the case, things got out of date.
I recreated the Dockerfile for (docker.io/chadmoon/jenkins-docker-kubectl) using [dockerfile-from-image](https://stackoverflow.com/questions/19104847/how-to-generate-a-dockerfile-from-an-image?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).  I modified the script to include adding plugins to the container image before running it in a pod.  Additionally, I added a groovy script that in conjunction with the start up script for the container create an admin user and enable security.

