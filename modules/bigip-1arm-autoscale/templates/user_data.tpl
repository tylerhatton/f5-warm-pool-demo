#!/usr/bin/env bash

# Create required directo
mkdir -p  /var/log/cloud /config/cloud /var/lib/cloud/icontrollx_installs /var/config/rest/downloads

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: HOST_NAME
    type: metadata
    metadataProvider:
      environment: aws
      type: compute
      field: hostname
  - name: REGION
    type: url
    value: http://169.254.169.254/latest/dynamic/instance-identity/document
    query: region
  - name: ADMIN_PASS
    type: secret
    secretProvider:
      environment: aws
      type: SecretsManager
      version: AWSCURRENT
      secretId: ${admin_password_secret}
extension_packages: 
  install_operations:
    - extensionType: do
      extensionVersion: 1.19.0
      extensionUrl: https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.19.0/f5-declarative-onboarding-1.19.0-2.noarch.rpm
    - extensionType: as3
      extensionVersion: 3.26.0
      extensionUrl: https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.26.1/f5-appsvcs-3.26.1-1.noarch.rpm
    - extensionType: ts
      extensionVersion: 1.18.0
      extensionUrl: https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.18.0/f5-telemetry-1.18.0-2.noarch.rpm
extension_services: 
  service_operations:
    - extensionType: do
      type: inline
      value:
        schemaVersion: 1.0.0
        class: Device
        async: true
        label: 1NIC autoscale with PAYG licensing
        Common:
          class: Tenant
          dbVars:
            class: DbVariables
            restjavad.useextramb: true
            provision.extramb: 500
            config.allow.rfc3927: enable
            ui.advisory.enabled: true
            ui.advisory.color: blue
            ui.advisory.text: "BIG-IP Autoscale"
          myNtp:
            class: NTP
            servers:
              - 0.pool.ntp.org
            timezone: UTC
          myDns:
            class: DNS
            nameServers:
              - 10.0.0.2
              - 8.8.8.8
          myProvisioning:
            class: Provision
            ltm: nominal
            asm: nominal
          mySystem:
            autoPhonehome: true
            class: System
            hostname: '{{{HOST_NAME}}}'
          admin:
            class: User
            userType: regular
            password: '{{{ ADMIN_PASS }}}'
            shell: bash
post_onboard_enabled:
  - name: save configs
    type: inline
    commands:
      - tmsh save sys config
EOF

for i in {1..30}; do
   curl -fv --retry 1 --connect-timeout 5 -L https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.2.0/f5-bigip-runtime-init-1.2.0-1.gz.run -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- '--cloud aws'
/usr/local/bin/f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml