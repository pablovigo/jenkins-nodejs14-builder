#!/bin/bash

CERTS_PATH="/usr/local/share/ca-certificates/XXXX"

for file in $(ls ${CERTS_PATH} | sed 's/\ /*/g'); do
   file=$(echo $file | sed 's/*/\ /g')
   keytool -import -trustcacerts -keystore /opt/sonar-scanner-4.4.0.2170-linux/jre/lib/security/cacerts -storepass changeit -noprompt -alias "$file" -file "${CERTS_PATH}/$file"
done
