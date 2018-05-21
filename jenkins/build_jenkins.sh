#!/bin/bash -x

docker build -t 127.0.0.1:30400/jenkins:latest -f Dockerfile ../jenkins && docker push 127.0.0.1:30400/jenkins:latest
