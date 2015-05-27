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

# Now we can do our Nagios and Apache work

ENV NAGIOS_VERSION 4.0.8
ENV NAGIOS_PLUGINS_VERSION 2.0.3
ENV NAGIOS_HOME /usr/local/nagios
ENV NAGIOS_USER nagios
ENV NAGIOS_GROUP nagios
ENV NAGIOS_CMDUSER nagios
ENV NAGIOS_CMDGROUP nagios
ENV NAGIOSADMIN_USER nagiosadmin
ENV NAGIOSADMIN_PASS nagios
ENV APACHE_RUN_USER nagios
ENV APACHE_RUN_GROUP nagios
ENV NAGIOS_TIMEZONE UTC

RUN ( egrep -i  "^${NAGIOS_GROUP}" /etc/group || groupadd $NAGIOS_GROUP ) && ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER || useradd --system $NAGIOS_USER -g $NAGIOS_GROUP -d $NAGIOS_HOME ) && ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )
RUN usermod -G $NAGIOS_CMDGROUP apache

# Download Nagios and the plugins
RUN wget http://downloads.sourceforge.net/project/nagios/nagios-4.x/nagios-$NAGIOS_VERSION/nagios-$NAGIOS_VERSION.tar.gz -O /tmp/nagios.tar.gz
RUN wget http://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINS_VERSION.tar.gz -O /tmp/nagios-plugins.tar.gz

RUN cd /tmp && tar -zxvf nagios.tar.gz \
    && cd nagios-$NAGIOS_VERSION \
    && ./configure --prefix=${NAGIOS_HOME} --exec-prefix=${NAGIOS_HOME} --enable-event-broker --with-nagios-command-user=${NAGIOS_CMDUSER} --with-command-group=${NAGIOS_CMDGROUP} --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_GROUP} \
    && make all \
	&& make install \
	&& make install-config \
	&& make install-commandmode \
	&& cp sample-config/httpd.conf /etc/httpd/conf.d/nagios.conf

RUN cd /tmp && tar -zxvf nagios-plugins.tar.gz \
    && cd nagios-plugins-$NAGIOS_PLUGINS_VERSION \
	&& ./configure --prefix=${NAGIOS_HOME} --with-openssl=/usr/bin/openssl \
	&& make \
	&& make install \
	&& chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/libexec
	
RUN echo "use_timezone=$NAGIOS_TIMEZONE" >> ${NAGIOS_HOME}/etc/nagios.cfg && echo "SetEnv TZ \"${NAGIOS_TIMEZONE}\"" >> /etc/httpd/conf.d/nagios.conf	

# Enable https for apache (mount the key and cert as a data volume)	
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

EXPOSE 443

ADD start.sh /usr/local/bin/start_nagios

