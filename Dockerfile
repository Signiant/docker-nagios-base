FROM centos:7

# Install EPEL
RUN yum install -y epel-release \
 && yum upgrade -y

# Install other packages
COPY packages.list /tmp/packages.list
RUN chmod +r /tmp/packages.list \
 && yum install -y -q $(cat /tmp/packages.list) \
 && yum upgrade -y \
 && yum autoremove -y \
 && yum clean all

# Now we can do our Nagios and Apache work
ENV NAGIOS_VERSION 4.4.10
ENV NAGIOS_PLUGINS_VERSION 2.4.3
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

# Download, build, and install Nagios Core
RUN wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-$NAGIOS_VERSION/nagios-$NAGIOS_VERSION.tar.gz -O /tmp/nagios.tar.gz
RUN cd /tmp && tar -zxvf nagios.tar.gz \
 && cd nagios-$NAGIOS_VERSION \
 && ./configure \
    --enable-event-broker \
    --exec-prefix=${NAGIOS_HOME} \
    --prefix=${NAGIOS_HOME} \
    --with-command-group=${NAGIOS_CMDGROUP} \
    --with-command-user=${NAGIOS_CMDUSER} \
    --with-nagios-group=${NAGIOS_GROUP} \
    --with-nagios-user=${NAGIOS_USER} \
 && make all \
 && make install-groups-users \
 && usermod -G $NAGIOS_GROUP apache \
 && make install \
 && make install-config \
 && make install-commandmode \
 && make install-webconf \
 && make clean \
 && cd /tmp \
 && rm -rf nagios-$NAGIOS_VERSION \
 && rm -f nagios.tar.gz

# Download, build, and install Nagios Plugins
RUN wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-$NAGIOS_PLUGINS_VERSION/nagios-plugins-$NAGIOS_PLUGINS_VERSION.tar.gz -O /tmp/nagios-plugins.tar.gz
RUN cd /tmp && tar -zxvf nagios-plugins.tar.gz \
 && cd nagios-plugins-$NAGIOS_PLUGINS_VERSION \
 && ./configure \
    --prefix=${NAGIOS_HOME} \
    --with-nagios-group=${NAGIOS_GROUP} \
    --with-nagios-user=${NAGIOS_USER} \
    --with-openssl \
 && make \
 && make install \
 && chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/libexec \
 && make clean \
 && cd /tmp \
 && rm -rf nagios-plugins-$NAGIOS_PLUGINS_VERSION \
 && rm -f nagios-plugins.tar.gz

# Install the NCPA check script
RUN wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz -O /tmp/check_ncpa.tar.gz
RUN cd /tmp && tar xvzf check_ncpa.tar.gz \
 && chown ${NAGIOS_USER}:${NAGIOS_GROUP} check_ncpa.py \
 && cp check_ncpa.py $NAGIOS_HOME/libexec

# Set timezone
RUN echo "use_timezone=$NAGIOS_TIMEZONE" >> ${NAGIOS_HOME}/etc/nagios.cfg && echo "SetEnv TZ \"${NAGIOS_TIMEZONE}\"" >> /etc/httpd/conf.d/nagios.conf

# Enable https for Apache
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

# Add a redirect for the root URI
COPY index.html /var/www/html/index.html

EXPOSE 443

ADD start.sh /usr/local/bin/start_nagios
