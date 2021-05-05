#!/usr/bin/env bash

sleep 3m

# Configure randomized password
echo -e '${bigip_password}\n${bigip_password}' | tmsh modify auth user ${bigip_username} prompt-for-password
tmsh save sys config

# Network connectivity test
count=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $count -le 6 ]; then
    echo "Status code: $STATUS network is not available yet."
    count=$[$count+1]
  else
    echo "Network Failure"
    break
  fi
  sleep 10
done

# Install Declarative Onboarding
do_pkg_url="https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.8.0/f5-declarative-onboarding-1.8.0-2.noarch.rpm"
do_pkg_path="/var/config/rest/downloads/declarative_onboarding.rpm"
do_json_pl="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$do_pkg_path\"}"
curl -L -o $do_pkg_path $do_pkg_url
curl -k -u ${bigip_username}:${bigip_password} -X POST -d $do_json_pl "https://localhost/mgmt/shared/iapp/package-management-tasks"

sleep 20

# Send Declarative Onboarding Payload

cat << 'EOF' > /tmp/do_payload.json
{
    "schemaVersion": "1.5.0",
    "class": "Device",
    "async": true,
    "Common": {
        "class": "Tenant",
        "hostname": "${hostname}",
        "myProvisioning": {
            "class": "Provision",
            ${provisioned_modules}
        }
    }
}
EOF

curl -k -u ${bigip_username}:${bigip_password} -X POST -d @/tmp/do_payload.json "https://localhost/mgmt/shared/declarative-onboarding"

sleep 60

# Install AS3
as_pkg_url="https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.19.1/f5-appsvcs-3.19.1-1.noarch.rpm"
as_pkg_path="/var/config/rest/downloads/f5-appsvcs-3.19.1-1.noarch.rpm"
as_json_pl="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$as_pkg_path\"}"
curl -L -o $as_pkg_path $as_pkg_url
curl -k -u ${bigip_username}:${bigip_password} -X POST -d $as_json_pl "https://localhost/mgmt/shared/iapp/package-management-tasks"

sleep 5

# Install Telemetry Streaming
ts_pkg_url="https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.16.0/f5-telemetry-1.16.0-4.noarch.rpm"
ts_pkg_path="/var/config/rest/downloads/f5-telemetry-1.16.0-4.noarch.rpm"
ts_json_pl="{\"operation\":\"INSTALL\",\"packageFilePath\":\"$ts_pkg_path\"}"
curl -L -o $ts_pkg_path $ts_pkg_url
curl -k -u ${bigip_username}:${bigip_password} -X POST -d $ts_json_pl "https://localhost/mgmt/shared/iapp/package-management-tasks"

# Cleanup
# rm -f /tmp/do_payload.json