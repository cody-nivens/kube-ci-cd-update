#!/bin/bash

docker build -t 127.0.0.1:30400/jenkins:latest -f Dockerfile ./ && docker push 127.0.0.1:30400/jenkins:latest
