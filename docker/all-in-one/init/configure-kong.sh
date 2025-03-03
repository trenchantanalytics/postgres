#!/bin/bash
set -eou pipefail

KONG_CONF=/etc/kong/kong.yml
touch /var/log/services/kong.log

if [ -f "${INIT_PAYLOAD_PATH:-}" ]; then
  echo "init kong payload"
  # Setup ssl termination
  tar -xzvf "$INIT_PAYLOAD_PATH" -C / ./etc/kong/
  chown -R adminapi:adminapi ./etc/kong/kong.yml
  chown -R adminapi:adminapi ./etc/kong/*pem
  echo "ssl_cipher_suite = intermediate" >> /etc/kong/kong.conf
  echo "ssl_cert = /etc/kong/fullChain.pem" >> /etc/kong/kong.conf
  echo "ssl_cert_key = /etc/kong/privKey.pem" >> /etc/kong/kong.conf
else
  # Default gateway config
  export KONG_DNS_ORDER=LAST,A,CNAME
  export KONG_PROXY_ERROR_LOG=syslog:server=unix:/dev/log
  export KONG_ADMIN_ERROR_LOG=syslog:server=unix:/dev/log
fi

# Inject project specific configuration
sed -i -e "s|anon_key|$ANON_KEY|g" \
  -e "s|service_key|$SERVICE_ROLE_KEY|g" \
  -e "s|supabase_admin_key|$ADMIN_API_KEY|g" \
  $KONG_CONF

# Update kong ports
sed -i "s|:80 |:$KONG_HTTP_PORT |g" /etc/kong/kong.conf
sed -i "s|:443 |:$KONG_HTTPS_PORT |g" /etc/kong/kong.conf
