#!/bin/bash

if [ ! -f ${NAGIOS_HOME}/etc/htpasswd.users ] ; then
  htpasswd -c -b -s ${NAGIOS_HOME}/etc/htpasswd.users ${NAGIOSADMIN_USER} ${NAGIOSADMIN_PASS}
  chown -R nagios.nagios ${NAGIOS_HOME}/etc/htpasswd.users
fi

# Fire up apache
echo "Starting HTTPD"
/usr/sbin/httpd -DFOREGROUND &
/usr/sbin/php-fpm

# Fire up nagios (blocking to keep the container up)
echo "Starting Nagios"
exec ${NAGIOS_HOME}/bin/nagios ${NAGIOS_HOME}/etc/nagios.cfg
