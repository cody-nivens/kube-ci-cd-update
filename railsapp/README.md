# Add a Rails application to a Kubernetes cluster

To setup for a Rails application, a setup script needs to be run.  This script starts helm on the cluster and uses helm to install MariaDB and PHPMyAdmin as well as environment variables for running the application, a job to initialize the database and a job to run tests. 
```sh
cd ./railsapp
./start_railsapp
```
Use the following to access the application in minikube.
```bash
minikube service railsapp-service
```

To add a database or database user to MariaDB, the rails\_recreate\_test script is used to start a client mysql pod and have it execute commands agains the MariaDB master.  This script is called after start\_railsapp is finished setting up MariaDB.

[https://github.com/cody-nivens/rothstock.git](https://github.com/cody-nivens/rothstock.git) -- An example of a Rails application is what I created to illustrate how a Rails environment is handled with jobs to perform rake commands on the database.
