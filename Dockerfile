FROM rockylinux:9

# Install OS packages
COPY packages.list /tmp/
RUN dnf install -y dnf-plugins-core \
 && dnf config-manager --set-enabled crb \
 && dnf install -y epel-release \
 && dnf upgrade -y \
 && dnf install -y $(cat /tmp/packages.list) \
 && dnf autoremove -y \
 && dnf clean all

# Now we can do our Nagios and Apache work
ENV NAGIOS_VERSION 4.4.11
ENV NAGIOS_PLUGINS_VERSION 2.4.4
ENV NAGIOS_HOME /usr/local/nagios
ENV NAGIOS_USER nagios
ENV NAGIOS_GROUP nagios
ENV NAGIOS_CMDUSER nagios
ENV NAGIOS_CMDGROUP nagios
ENV NAGIOSADMIN_USER nagiosadmin
ENV NAGIOSADMIN_PASS nagios

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
 && make \
 && make install \
 && chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/libexec \
 && make clean \
 && cd /tmp \
 && rm -rf nagios-plugins-$NAGIOS_PLUGINS_VERSION \
 && rm -f nagios-plugins.tar.gz

# Enable https for Apache
ADD ssl.conf /etc/httpd/conf.d/ssl.conf

# Add a redirect for the root URI
COPY index.html /var/www/html/index.html

# This is needed for PHP
RUN mkdir -p /run/php-fpm/

EXPOSE 443

ADD start.sh /usr/local/bin/start_nagios
