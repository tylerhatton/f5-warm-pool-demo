import boto3
from botocore.exceptions import ClientError
import logging
import requests
import time
import urllib3

urllib3.disable_warnings()
logger = logging.getLogger()

def revoke_bigip_license(bigiq_server, bigiq_username, bigiq_password, bigiq_license_pool_name, bigip_username, bigip_password, bigip_instance_id):
    ec2 = boto3.client('ec2')
    logger.info('Attempting to license BYOL BIG-IP instance with BIG-IQ')
    # Grabbing EC2 instance info
    try:
        instance_info = ec2.describe_instances(
            InstanceIds=[bigip_instance_id])
        bigip_private_ip = instance_info['Reservations'][0]['Instances'][0]['PrivateIpAddress']
        bigip_mac_address = instance_info['Reservations'][0]['Instances'][0] ['NetworkInterfaces'][0]['MacAddress'].upper()
    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)

    # Revoking BIG-IP license in BIG-IQ
    try:
      logger.info('Revoking BIG-IP license')
      response = requests.post(
          'https://' + bigiq_server + '/mgmt/cm/device/tasks/licensing/pool/member-management',
          auth=(bigiq_username, bigiq_password),
          json={
              "licensePoolName": bigiq_license_pool_name,
              "command": "revoke",
              "address": bigip_private_ip,
              "assignmentType": "UNREACHABLE",
              "macAddress": bigip_mac_address,
              "hypervisor": "aws",
              "skuKeyword1": "BT",
              "skuKeyword2": "1G",
              "unitOfMeasure": "yearly"
          },
          verify=False,
          timeout=20
      )
      response.raise_for_status()
      logger.info(response.json())
    except requests.exceptions.HTTPError as e:
        message = 'Error licensing BIG-IP: {}'.format(e)
        logger.error(message)
        raise Exception(message)    

def license_bigip(bigiq_server, bigiq_username, bigiq_password, bigiq_license_pool_name, bigip_username, bigip_password, bigip_instance_id):
    ec2 = boto3.client('ec2')
    logger.info('Attempting to license BYOL BIG-IP instance with BIG-IQ')
    # Grabbing EC2 instance info
    try:
        instance_info = ec2.describe_instances(
            InstanceIds=[bigip_instance_id])
        bigip_private_ip = instance_info['Reservations'][0]['Instances'][0]['PrivateIpAddress']
        bigip_public_ip = instance_info['Reservations'][0]['Instances'][0]['PublicIpAddress']
        bigip_mac_address = instance_info['Reservations'][0]['Instances'][0] ['NetworkInterfaces'][0]['MacAddress']
    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)

    # Attempting to pull new license from BIG-IQ and apply to BIG-IP
    try:
        # Sending Request for license file to BIGIQ
        logger.info('Requesting license file from BIG-IQ')
        license_response = requests.post(
            'https://' + bigiq_server + '/mgmt/cm/device/tasks/licensing/pool/member-management',
            auth=(bigiq_username, bigiq_password),
            json={
                "licensePoolName": bigiq_license_pool_name,
                "command": "assign",
                "address": bigip_private_ip,
                "assignmentType": "UNREACHABLE",
                "macAddress": bigip_mac_address,
                "hypervisor": "aws",
                "skuKeyword1": "BT",
                "skuKeyword2": "1G",
                "unitOfMeasure": "yearly"
            },
            verify=False,
            timeout=20
        )
        license_response.raise_for_status()
        license_id = license_response.json()['id']

        # Waiting for license file to be generated.
        retries = 0
        max_retries = 12
        while retries < max_retries:
            retries = retries + 1
            logger.info(
                'Checking if BIG-IQ license has been created #: {}'.format(retries))
            license_file_response = requests.get(
                'https://' + bigiq_server + '/mgmt/cm/device/tasks/licensing/pool/member-management/' + license_id,
                auth=(bigiq_username, bigiq_password),
                verify=False,
                timeout=20
            )
            license_file_response.raise_for_status()
            if 'licenseText' in license_file_response.json():
                license_file = license_file_response.json()['licenseText']
                break
            elif license_file_response.json()['status'] == 'FAILED':
                error = license_file_response.json()['errorMessage']
                message = 'BIG-IQ returned a status FAILED on licensing: {}'.format(error)
                logger.error(message)
                raise Exception(message)
            elif retries == max_retries:
                message = 'Max retries exceeded when getting BIG-IP license from BIG-IQ'
                logger.error(message)
                raise Exception(message)
            else:
                time.sleep(5)
        
        # Applying license file to target BIG-IP
        logger.info('Applying BIG-IP license')
        bigip_response = requests.put(
            'https://' + bigip_public_ip + ':8443/mgmt/tm/shared/licensing/registration',
            auth=(bigip_username, bigip_password),
            json={"licenseText": license_file},
            verify=False,
            timeout=20
        )
        bigip_response.raise_for_status()

    except requests.exceptions.HTTPError as e:
        message = 'Error licensing BIG-IP: {}'.format(e)
        logger.error(message)
        raise Exception(message)