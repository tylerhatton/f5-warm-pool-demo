import requests
import boto3
from botocore.exceptions import ClientError
import logging
import urllib3
import json
import time

urllib3.disable_warnings()
logger = logging.getLogger()

def send_as3_declarations(f5_ip, username, password, s3_declaration_location):
    s3 = boto3.resource('s3')

    try:
        # Executing AS3 declarations from S3 bucket in as3-declarations/
        logger.info(
            'Grabbing AS3 declarations from: {}'.format(s3_declaration_location))
        # Looping through declarations in S3 Bucket
        bucket = s3.Bucket(s3_declaration_location)
        for obj in bucket.objects.filter(Prefix='as3-declarations/'):
            as3_dec = json.loads(obj.get()['Body'].read())
            # Send AS3 declaration
            try:
                response = requests.post(
                    'https://' + f5_ip + ':8443/mgmt/shared/appsvcs/declare',
                    auth=(username, password),
                    json=as3_dec,
                    verify=False,
                    timeout=5
                )
                response.raise_for_status()
            except requests.exceptions.HTTPError as e:
                message = 'Error executing AS3 declaration: {}'.format(e)
                logger.error(message)
                raise Exception(message)

    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)


def is_as3_alive(f5_ip, username, password, max_retries):
    # Check if AS3 is responsive and available
    logger.info('Checking if AS3 is online...')
    retries = 0

    # Try connecting to AS3 until max retries
    while retries < max_retries:
        retries = retries + 1
        try:
            logger.info(
                'Checking if AS3 is available attempt #: {}'.format(retries))
            response = requests.get(
                'https://' + f5_ip + ':8443/mgmt/shared/appsvcs/info',
                auth=(username, password),
                verify=False,
                timeout=5
            )
            # Return True if status code for AS3 is 200
            if response.status_code == 200:
                return True
            else:
                time.sleep(10)
        except requests.exceptions.Timeout:
            logger.info('Connection Timeout')
            continue
        except requests.exceptions.ConnectionError as errc:
            logger.info(errc)
            continue
        except requests.exceptions.HTTPError as errh:
            logger.info(errh)
            continue
        except requests.exceptions.RequestException as err:
            logger.info(err)
            continue
    # Could not reach AS3
    return False