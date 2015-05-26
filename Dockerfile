FROM centos:centos7
MAINTAINER devops@signiant.com

# make sure we're running latest of everything
RUN yum update -y

# Install wget which we need later
RUN yum install -y wget

# Install EPEL
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

# Install the repoforge repo (needed for updated git)
RUN wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm -O /tmp/repoforge.rpm
RUN yum install -y /tmp/repoforge.rpm
RUN rm -f /tmp/repoforge.rpm

# Install a base set of packages from the default repo
COPY yum-packages.list /tmp/yum-packages.list
RUN chmod +r /tmp/yum-packages.list
RUN yum install -y -q `cat /tmp/yum-packages.list`

# Install packages from the repoforge repo
COPY repoforge-packages.list /tmp/repoforge-packages.list
RUN chmod +r /tmp/repoforge-packages.list
RUN yum install -y -q --enablerepo=rpmforge-extras `cat /tmp/repoforge-packages.list`

# Install PIP - useful everywhere
RUN /usr/bin/curl -O https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py


