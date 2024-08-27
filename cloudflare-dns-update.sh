#!/bin/bash

LOG_FILE="/var/log/dnsUpdate/cloudflare-dns-update.log"
IP_ADDRESS_FILE="/tmp/current-ipaddress.txt"
CONFIG="./cloudflare-dns-update.cfg"

#Read key/value config data
while IFS="=" read -r key value; do
  # Skip lines that don't match the key=value format
  if [[ -z "$key" || -z "$value" ]]; then
    continue
  fi

  # Create a variable with the name of the key and assign it the value
  eval "$key=\"$value\""
done < `echo $CONFIG`

#echo $(TZ=":US/Eastern" date) "Started ipaddress update script" >> "$LOG_FILE"

CURRENT_IP=`curl -s -S -X GET api.ipify.org`

if [[ -n "$CURRENT_IP" ]]; then

  LAST_IP=$(tail -n 1 "$IP_ADDRESS_FILE")

  if [[ "$LAST_IP" != "$CURRENT_IP" ]]; then

    echo $(TZ=":US/Eastern" date) "Current IP Address: $CURRENT_IP Last IP Address: $LAST_IP change" >> "$LOG_FILE"

    DATA_TO_UPDATE="{\"type\":\"A\",\"name\":\"$A_record\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":false}"

    RESPONSE=`curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/"$ZONE_ID"/dns_records/"$A_record_id -H "Authorization:
 Bearer ${CF_BEARER}" -H "Content-Type:application/json" --data $DATA_TO_UPDATE`

    echo $(TZ=":US/Eastern" date)  "$RESPONSE" >> ${LOG_FILE}

    if [[ "$RESPONSE" =~ "\"success\":true" ]]; then
      echo $(TZ=":US/Eastern" date)  "Success updating dns record" >> ${LOG_FILE}
      echo "$CURRENT_IP" > "$IP_ADDRESS_FILE"
    else
      echo $(TZ=":US/Eastern" date) "Failed updating dns record" >> ${LOG_FILE}
    fi

  else
    echo $(TZ=":US/Eastern" date) "Current IP Address: $CURRENT_IP Last IP Address: $LAST_IP no change" >> "$LOG_FILE"
  fi


else
  echo $(TZ=":US/Eastern" date) "ERROR Unable to get Current IP Address: $CURRENT_IP" >> "$LOG_FILE"
fi

#echo $(TZ=":US/Eastern" date) "Completed ipaddress update script" >> "$LOG_FILE"
