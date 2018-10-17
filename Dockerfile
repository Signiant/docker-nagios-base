FROM centos:centos7
MAINTAINER devops@signiant.com

# Install wget which we need later
# && install EPEL
RUN yum install -y wget \
    && rpm -ivh https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/$(wget -q -O - https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/ | grep -o 'epel-release-[0-9]*\-[0-9]*\.noarch.rpm'| head -1)

# Install a base set of packages from the default repo
COPY yum-packages.list /tmp/yum-packages.list
RUN chmod +r /tmp/yum-packages.list \
    && yum install -y -q `cat /tmp/yum-packages.list` \
    && yum update -y \
    && yum clean all

# Install PIP - useful everywhere
RUN /usr/bin/curl -O https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

# Now we can do our Nagios and Apache work

ENV NAGIOS_VERSION 4.4.1
ENV NAGIOS_PLUGINS_VERSION 2.1.2
ENV NAGIOS_HOME /usr/local/nagios
ENV NAGIOS_USER nagios
ENV NAGIOS_UID 1000
ENV NAGIOS_GID 1000
ENV NAGIOS_GROUP nagios
ENV NAGIOS_CMDUSER nagios
ENV NAGIOS_CMDGROUP nagios
ENV NAGIOSADMIN_USER nagiosadmin
ENV NAGIOSADMIN_PASS nagios
ENV APACHE_RUN_USER nagios
ENV APACHE_RUN_GROUP nagios
ENV NAGIOS_TIMEZONE UTC

RUN ( egrep -i  "^${NAGIOS_GROUP}" /etc/group || groupadd -g $NAGIOS_GID $NAGIOS_GROUP ) && ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd -g $NAGIOS_GID $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER || useradd --system $NAGIOS_USER -u $NAGIOS_UID -g $NAGIOS_GROUP -d $NAGIOS_HOME ) && ( id -u $NAGIOS_CMDUSER || useradd --system -u $NAGIOS_UID -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )
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
	&& cp sample-config/httpd.conf /etc/httpd/conf.d/nagios.conf \
  && make clean \
  && cd /tmp \
  && rm -rf nagios-$NAGIOS_VERSION

RUN cd /tmp && tar -zxvf nagios-plugins.tar.gz \
    && cd nagios-plugins-$NAGIOS_PLUGINS_VERSION \
	&& ./configure --prefix=${NAGIOS_HOME} --with-openssl=/usr/bin/openssl \
	&& make \
	&& make install \
	&& chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/libexec \
  && make clean \
  && cd /tmp \
  && rm -rf nagios-plugins-$NAGIOS_PLUGINS_VERSION

# Update the NCPA check script
RUN wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz -O /tmp/check_ncpa.tar.gz
RUN cd /tmp && tar xvzf check_ncpa.tar.gz \
    && chown ${NAGIOS_USER}:${NAGIOS_GROUP} check_ncpa.py \
    && cp check_ncpa.py $NAGIOS_HOME/libexec

RUN echo "use_timezone=$NAGIOS_TIMEZONE" >> ${NAGIOS_HOME}/etc/nagios.cfg && echo "SetEnv TZ \"${NAGIOS_TIMEZONE}\"" >> /etc/httpd/conf.d/nagios.conf

# Enable https for apache (mount the key and cert as a data volume)
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

# Add a redirect for the root URI
COPY index.html /var/www/html/index.html

EXPOSE 443

ADD start.sh /usr/local/bin/start_nagios
