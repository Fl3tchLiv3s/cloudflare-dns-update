#!/bin/bash

LOG_FILE="/var/log/dnsUpdate/cloudflare-dns-update.log"

#echo $(TZ=":US/Eastern" date) "Started ipaddress update script" >> "$LOG_FILE"

CONFIG="/home/andy/scripts/cloudflare-dns-update.cfg"

#Read key/value config data
while IFS="=" read -r key value; do
  # Skip lines that don't match the key=value format
  if [[ -z "$key" || -z "$value" ]]; then
    continue
  fi
  # Create a variable with the name of the key and assign it the value
  eval "$key=\"$value\""
done < `echo $CONFIG`

if [[ -z "$ZONE_ID" || -z "$A_record" || -z "$A_record_id" || -z "$CF_BEARER" ]]; then
  echo $(TZ=":US/Eastern" date) "ERROR - Missing config data verify ZONE_ID, A_record, A_record_id, CF_BEARER present in file $CONFIG and readable by script" >> "$LOG_FILE"
  exit 1;
fi

GET_RESPONSE=`curl -X GET "https://api.cloudflare.com/client/v4/zones/"$ZONE_ID"/dns_records/"$A_record_id \
              -H "Authorization: Bearer ${CF_BEARER}" \
              -H "Content-Type:application/json"`

#echo $(TZ=":US/Eastern" date) "INFO - Get response from cloudflare: $GET_RESPONSE" >> "$LOG_FILE"

if [[ "$GET_RESPONSE" =~ "\"success\":true" ]]; then
  LAST_IP=`echo "$GET_RESPONSE" | grep -Po '"'"content"'"\s*:\s*"\K([^"]*)'`
  #echo $(TZ=":US/Eastern" date) "INFO - Retrieved IP Address from cloudflare: $LAST_IP" >> "$LOG_FILE"
else
  echo $(TZ=":US/Eastern" date) "ERROR - Unable to get LAST IP Address: $LAST_IP" >> "$LOG_FILE"
  exit 1;
fi

CURRENT_IP=`curl -s -S -X GET api.ipify.org`

if [[ -z "$CURRENT_IP" ]]; then
  echo $(TZ=":US/Eastern" date) "ERROR - Unable to get Current IP Address: $CURRENT_IP" >> "$LOG_FILE"
  exit 1;
fi

if [[ "$LAST_IP" != "$CURRENT_IP" ]]; then

  echo $(TZ=":US/Eastern" date) "INFO - Current IP Address: $CURRENT_IP Last IP Address: $LAST_IP CHANGED" >> "$LOG_FILE"

  DATA_TO_UPDATE="{\"type\":\"A\",\"name\":\"$A_record\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":false}"

  RESPONSE=`curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/"$ZONE_ID"/dns_records/"$A_record_id \
                    -H "Authorization: Bearer ${CF_BEARER}" \
                    -H "Content-Type:application/json" --data $DATA_TO_UPDATE`

  #echo $(TZ=":US/Eastern" date)  "INFO $RESPONSE" >> ${LOG_FILE}

  if [[ "$RESPONSE" =~ "\"success\":true" ]]; then
    echo $(TZ=":US/Eastern" date) "INFO - Success updating dns record" >> ${LOG_FILE}
  else
    echo $(TZ=":US/Eastern" date) "ERROR - Failed updating dns record" >> ${LOG_FILE}
    exit 1;
  fi

else
  echo $(TZ=":US/Eastern" date) "INFO - Current IP Address: $CURRENT_IP Last IP Address: $LAST_IP no change" >> "$LOG_FILE"
fi

#echo $(TZ=":US/Eastern" date) "Completed ipaddress update script" >> "$LOG_FILE"
exit 0;