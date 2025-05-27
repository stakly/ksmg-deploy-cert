#!/usr/bin/env bash

# https://github.com/stakly/ksmg-desploy-cert
# v1.0 for KSMG 2.0
# v1.1 for KSMG 2.1

#set -x
# require curl, openssl
[ ! -x "`which openssl`" ] && echo "KSMG > openssl not found" && exit 1
[ ! -x "`which curl`" ] && echo "KSMG > curl not found" && exit 1

# vars
SERVER_ADDR='mxf.domain.ru'
USER='Administrator'
PASSWORD='password!'
CERT_PASSWORD='123123'
DOMAIN='domain.ru'
LE_DIR='/etc/letsencrypt'

# sysvars
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}"ksmg-cert.XXXXXXXXXX)
AUTHINFO_URL="https://$SERVER_ADDR/web/api/get-auth-info"
AUTH_URL="https://$SERVER_ADDR/web/api/user-login"
CERT_URL="https://$SERVER_ADDR/web/api/create-mta-cert-imported"
ACTIVATECERT_URL="https://$SERVER_ADDR/web/api/set-mta-cert-active-server"
CERT_FILE="$TMP_DIR/$DOMAIN.pfx"
COOKIE="$TMP_DIR/cookie.txt"

trap 'rm -rf "$TMP_DIR"' EXIT
trap 'exit 126' HUP INT TERM

echo "KSMG > generating certificate container \"$CERT_FILE\""
openssl pkcs12 -export -out $CERT_FILE -inkey $LE_DIR/live/$DOMAIN/privkey.pem -in $LE_DIR/live/$DOMAIN/cert.pem -certfile $LE_DIR/live/$DOMAIN/chain.pem -password pass:$CERT_PASSWORD

echo "KSMG > obtaining XSRF token from \"$COOKIE\""
curl -sS -k -c $COOKIE $AUTHINFO_URL >/dev/null

XSRF_TOKEN=`awk '/XSRF-TOKEN/ { printf $7 }' $COOKIE`

echo "KSMG > trying to auth and save cookie into \"$COOKIE\""
AUTH_RESULT=`curl -sS -k -H "KSMG-XSRF-TOKEN: $XSRF_TOKEN" -H 'Content-Type: application/json' -b $COOKIE -c $COOKIE -X POST \
	-d "{\"username\":\"$USER\",\"password\":\"$PASSWORD\",\"newPassword\":\"\",\"confirmPassword\":\"\",\"useDomainCreds\":false}" \
	$AUTH_URL`
if [[ "$AUTH_RESULT" =~ error ]] ; then
	echo "KSMG > ERROR in result: $AUTH_RESULT"
else
	echo "KSMG > uploading certificate \"$CERT_FILE\""
	curl -sS -k -H "KSMG-XSRF-TOKEN: $XSRF_TOKEN" -b $COOKIE -X POST \
		-F "file=@$CERT_FILE;type=application/x-pkcs12" "$CERT_URL?password=$CERT_PASSWORD" >$TMP_DIR/ksmganswer.json

	ID=`cd $TMP_DIR ; python3 -c "import json,os; print(json.load(open('ksmganswer.json', 'r'))['data']['id'])"`
	[ "$ID" == "" ] && ID=0
	if [ $ID -gt 0 ] ; then
		echo "KSMG > activating certificate with id $ID"
		RESULT=`curl -sS -k -H "KSMG-XSRF-TOKEN: $XSRF_TOKEN" -H 'Content-Type: application/json' -b $COOKIE -X POST \
			-d "{\"id\":$ID}" $ACTIVATECERT_URL`
		[[ "$RESULT" =~ success ]] && echo "KSMG > success" || echo "KSMG > something wrong, check result: $RESULT"
	else
		echo "KSMG > ERROR obtaining certificate ID: $ID"
		echo "KSMG > check $TMP_DIR/ksmganswer.json"
		cat $TMP_DIR/ksmganswer.json
	fi
fi

