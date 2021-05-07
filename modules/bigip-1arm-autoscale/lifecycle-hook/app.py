import boto3
import os
import json
import logging
import time
import requests

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')

# Getting username and password locations in parameter store
USER_PARAM = os.environ['USER_PARAM_LOCATION']
PASS_PARAM = os.environ['PASS_PARAM_LOCATION']


def send_lifecycle_action(lifecycle_event, result):
    # Update lifecycle event with continue or abort
    try:
        response = autoscaling.complete_lifecycle_action(
            LifecycleHookName=lifecycle_event['detail']['LifecycleHookName'],
            AutoScalingGroupName=lifecycle_event['detail']['AutoScalingGroupName'],
            LifecycleActionToken=lifecycle_event['detail']['LifecycleActionToken'],
            LifecycleActionResult=result,
            InstanceId=lifecycle_event['detail']['EC2InstanceId']
        )

        logger.info(response)
    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)

    return


def is_as3_alive(f5_ip, username, password, max_retries):
    # Check if AS3 is responsive and available
    logger.info('Checking if AS3 is online...')
    retries = 0

    # Try connecting to AS3 until max retries
    while retries < max_retries:
        retries = retries + 1
        try:
            time.sleep(10)
            logger.info(
                'Checking if AS3 is available attempt #: {}'.format(retries))
            response = requests.get(
                'https://' + f5_ip + '/mgmt/shared/appsvcs/declare',
                auth=(username, password),
                verify=False,
                timeout=5
            )
            # Return True if status code for AS3 is 200
            if response.status_code == 200:
                return True
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


def instance_launching(lifecycle_event):
    # Instance launching event cycle
    logger.info('EC2_INSTANCE_LAUNCHING event')
    try:
        # Grab EC2 Instance info
        ec2_instance_id = lifecycle_event['EC2InstanceId']
        ec2_instance_info = ec2.describe_instances(
            InstanceIds=[ec2_instance_id])

        logger.info('EC2 Instance info: {}'.format(ec2_instance_info))

    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)


def instance_terminating(lifecycle_event):
    logger.info('EC2_INSTANCE_TERMINATING event')


def lambda_handler(event, context):
    logger.info('Trigger Record: {}'.format(event['Records']))
    lifecycle_event = json.loads(event['Records'][0]['Sns']['Message'])

    # Verify Lifecycle Transition is present
    if 'LifecycleTransition' not in lifecycle_event:
        logger.info(
            'LifecycleTransition missing from SNS message. Likely a test notification.')
        return

    # Identifying Lifecycle hook type
    logger.info('Lifecycle Event: {}'.format(lifecycle_event))
    if lifecycle_event['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_LAUNCHING':
        instance_launching(lifecycle_event)
    elif lifecycle_event['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING':
        instance_terminating(lifecycle_event)
    else:
        logger.info('Unknown LifecycleTransition state. Exiting...')
        return
