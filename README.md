# docker-nagios-base 
Base image for Nagios + Aapache2 (with SSL).
https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html

Base docker image for Nagios 4 + Apache2 with SSL enabled.  Mount the SSL cert into the docker container using a uservolume.

Run using a docker run command like:

````
docker run -d -p 443:443 \
	      -v /local/path/to/ssl/cert:/etc/pki/tls/certs/server.crt \
	      -v /local/path/to/ssl/key:/etc/pki/tls/private/server.key \
	      -v /local/path/to/nagios.cfg:/usr/local/nagios/nagios.cfg \
	      -v /local/path/to/nagios/configs:/usr/local/nagios/etc/objects \
	      -v /local/path/to/htpasswd:/usr/local/nagios/etc/htpasswd.users \
              signiant/docker-nagios-base \
	      /usr/local/bin/start_nagios

````

In the example above:
- All overidable volumes/files should exist on the local host and then be mounted into the container
- The public/private keys are the SSL cert for the apache web server.
- The nagios.cfg file allows you to override the default nagios config
- the path to /etc/objects allows you to have your nagios configs on the local host and mounted into the container
- the htpasswd file allows you to override the value for the user/password who can login to nagios
- default is nagiosadmin/nagios
- this must be a valid formatted htpasswd file (there are many generators out there)

