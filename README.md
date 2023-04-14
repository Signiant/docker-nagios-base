# docker-nagios-base 
Base image for Nagios and Apache HTTPD (with SSL).
https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html

Run using a docker run command like:

````
docker run -d -p 443:443 \
    -v /local/path/to/ssl/cert:/etc/pki/tls/certs/localhost.crt \
    -v /local/path/to/ssl/key:/etc/pki/tls/private/localhost.key \
    -v /local/path/to/ssl/chain:/etc/pki/tls/certs/server-chain.crt \
    -v /local/path/to/nagios.cfg:/usr/local/nagios/nagios.cfg \
    -v /local/path/to/nagios/configs:/usr/local/nagios/etc/objects \
    -v /local/path/to/htpasswd:/usr/local/nagios/etc/htpasswd.users \
        signiant/docker-nagios-base

````

In the example above:
- All overidable volumes/files should exist on the local host and then be mounted into the container
- The public/private keys are the SSL cert for the apache web server.
- The nagios.cfg file allows you to override the default nagios config
- the path to /etc/objects allows you to have your nagios configs on the local host and mounted into the container
- the htpasswd file allows you to override the value for the user/password who can login to nagios
- default is nagiosadmin/nagios
- this must be a valid formatted htpasswd file (there are many generators out there)

