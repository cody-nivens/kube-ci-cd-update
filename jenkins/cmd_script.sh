#!/bin/bash
set -e

if [ ! -e /root/.jenkins/init.groovy.d ] ; then
  echo "Coping init.groovy.d"
  cp -a /usr/share/jenkins/ref/init.groovy.d /root/.jenkins
  echo "Coping plugins"
  rm -rf /root/.jenkins/plugins
  cp -a /usr/share/jenkins/ref/plugins /root/.jenkins
  cmd='/usr/bin/java -Djenkins.install.runSetupWizard=false -jar jenkins.war'
else
   #rm -f /root/.jenkins/init.groovy.d/*
   cmd='/usr/bin/java -jar jenkins.war'
fi
  cmd='/usr/bin/java -Djenkins.install.runSetupWizard=false -jar jenkins.war'
exec $cmd
