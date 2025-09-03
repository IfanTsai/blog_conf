#!/bin/bash
#crontab: 0 2 */10 * * certbot renew --manual --preferred-challenges=dns --manual-auth-hook '/usr/local/openresty/nginx/conf/shell/certbot_hook.sh' --manual-cleanup-hook '/usr/local/openresty/nginx/conf/shell/certbot_hook.sh clean' >/dev/null 2>&1

RECORD_FILE="/tmp/_acme-challenge.${CERTBOT_DOMAIN}_${CERTBOT_VALIDATION}"

if ! command -v aliyun >/dev/null 2>&1; then
    echo "Error: aliyun command not found. Please install the Aliyun CLI."
    exit 1
fi

if [ "$1" = "clean" ]; then
    # delete DNS TXT record
    RECORD_ID=$(cat ${RECORD_FILE})
    if [ -n "${RECORD_ID}" ]; then
        aliyun alidns DeleteDomainRecord --RecordId ${RECORD_ID} >/dev/null
    fi
    rm -f ${RECORD_FILE}
else
    # create DNS TXT record
    RECORD_ID=$(
        aliyun alidns AddDomainRecord \
            --DomainName ${CERTBOT_DOMAIN} \
            --RR _acme-challenge \
            --Type TXT \
            --Value ${CERTBOT_VALIDATION} \
            --TTL 600 \
        | grep "RecordId" | grep -Eo "[0-9]+"
    )
    echo ${RECORD_ID} > ${RECORD_FILE}
    sleep 60 # wait for DNS propagation
fi
