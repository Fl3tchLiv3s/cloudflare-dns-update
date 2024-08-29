# cloudflare-dns-update
Script to update the public ipaddress in cloudflare dns records

### Cloudflare record details

The script requires the following values set in the cfg  file

ZONE_ID=<zone-id> \
A_record=<a-record> \
A_record_id=<a-record-id> \
CF_BEARER=<token>


To find the cloudflare record details, go to the dashboard: https://dash.cloudflare.com then navigate to websites and your domain management page.

ZONE_ID - On the bottom right is the Zone ID. 

A_record - your domain (e.g. yourdomain.com) 

CF_BEARER - You can set up a token by going to the top right dropdown and selecting 'My Profile' then 'API tokens'. Create a token with the following PErmissions: Zone.Zone Settings, Zone.Zone, Zone.DNS and Resources: All Zones

A_record_id - can be found using the curl command:

`curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
-H "Authorization: Bearer <token>" \
-H "Content-Type:application/json"`

This will output a list of your records and the A record id is the 'id' value for your domain record 

### Deployment

Place the cloudflare-dns-update.sh script on your server with the cloudflare-dns-update.cfg in the same location. You may want/need to modify the path of the cfg and logfiles in the script to match your needs

### Systemd setup to run the script

Place the cloudflare-dns-update.service and cloudflare-dns-update.timer in the systemd directory you use

e.g. `/etc/systemd/system`

Commands to enable and start the scheduled task

`sudo systemctl enable cloudflare-dns-update.timer`\
`sudo systemctl start cloudflare-dns-update.timer`\
`sudo systemctl daemon-reload`\
`sudo systemctl list-timers --all`
