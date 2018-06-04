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
RUN apt-get update
RUN apt-get install -y wget git curl
RUN wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war
RUN wget -qO- https://get.docker.com/ | sh
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

RUN mkdir -p /var/lib/jenkins/init.groovy.d
COPY basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy

## In case you are running as root
#RUN chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

COPY jenkins-support /usr/local/bin/
COPY plugins.txt /var/lib/jenkins/plugins.txt
COPY install-plugins.sh /usr/local/bin/

#RUN /usr/local/bin/install-plugins.sh < /var/lib/jenkins/plugins.txt

CMD ["/usr/bin/java", "-jar", "jenkins.war"]
