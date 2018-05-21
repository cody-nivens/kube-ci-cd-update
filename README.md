# Updates to the Kubernetes-CI-CD

After a year, things can move so swaftly.  This repo implements jenkins in minikube allowing for deployment of applications into kubernetes.

Based on [Linux.com:Set Up a CI/CD Pipeline with Kubernetes Part 1: Overview](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/5/set-cicd-pipeline-kubernetes-part-1-overview)

The Dockerfile is a reconstruction from the container (docker.io/chadmoon/jenkins-docker-kubectl) using [dockerfile-from-image](https://stackoverflow.com/questions/19104847/how-to-generate-a-dockerfile-from-an-image?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa).

The script start_kube.sh will delete the minikube cluster and the following directories: ~/.minikube and  ~/.kube in root's home directory.

Docker and VirtualBox are required.  Docker must be running.


After Jenkins in up and running do the first extercise on [Linux.com - Set Up a CI/CD Pipeline with a Jenkins Pod in Kubernetes (Part 2)](https://www.linux.com/blog/learn/chapter/Intro-to-Kubernetes/2017/6/set-cicd-pipeline-jenkins-pod-kubernetes-part-2).

