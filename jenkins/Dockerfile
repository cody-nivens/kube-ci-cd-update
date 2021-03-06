FROM scratch
ADD rootfs.tar.xz /
CMD ["/bin/bash"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl wget \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y --no-install-recommends bzr git mercurial openssh-client subversion procps \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y --no-install-recommends bzip2 unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list
ENV LANG=C.UTF-8
RUN { echo '#!/bin/sh'; echo 'set -e'; echo; echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_VERSION=8u171
ENV JAVA_DEBIAN_VERSION=8u171-b11-1~bpo8+1
ENV CA_CERTIFICATES_JAVA_VERSION=20161107~bpo8+1
RUN set -x \
    && apt-get update \
    && apt-get install -y openjdk-8-jdk \
                          openjdk-8-jre \
                          openjdk-8-jdk-headless \
                          openjdk-8-jre-headless \
                          ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
    && rm -rf /var/lib/apt/lists/* \
    && [ "$JAVA_HOME" = "$(docker-java-home)" ]
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Get docker
RUN echo 'test2' > test && rm test 

RUN wget -qO- https://get.docker.com/ | sh

# Get kubctl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Get jenkins
RUN wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war

# Add user, security and number of executors
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d/
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/

# Add script which works for initial setup
COPY run_jenkins.sh /usr/local/bin/

# Preload plugin support files
COPY jenkins-support /usr/local/bin/
COPY install-plugins.sh /usr/local/bin/

# Cache guard - update number to foil cache from  this step to the end of the file
RUN echo 'plugins_2' > test && rm test 

COPY plugins.txt /var/lib/jenkins/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /var/lib/jenkins/plugins.txt

CMD ["/usr/local/bin/run_jenkins.sh" ]
