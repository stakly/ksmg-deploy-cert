# ksmg-deploy-cert
Tool for deploying TLS certificate over WEB interface to KSMG 2.0
## usage
1. Define variables inside **ksmg-deploy-cert.sh** script:
```bash
SERVER_ADDR='mxf.domain.ru'
USER='Administrator'
PASSWORD='password!'
# temporary password for PFX container
CERT_PASSWORD='123123'
DOMAIN='domain.ru'
# certbot working directory contains 'live' directory
LE_DIR='/etc/letsencrypt'
# temporary directory
TMP_DIR='/tmp'
```
2. Run script to check it works:
```
root@host:[~/bin]#./ksmg-deploy-cert.sh
KSMG > generating certificate container "/tmp/domain.ru.pfx"
KSMG > obtaing XSRF token from "/tmp/cookie.txt"
KSMG > trying to auth and save cookie into "/tmp/cookie.txt"
KSMG > uploading certificate "/tmp/domain.ru.pfx"
KSMG > activating certificate with id 4
KSMG > success
```
3. Add periodically startup to cron or run after successfully receiving new certificate.
