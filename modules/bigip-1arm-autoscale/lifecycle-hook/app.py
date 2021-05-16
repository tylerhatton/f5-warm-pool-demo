import boto3
import os
import json
import logging
import time
import requests
import urllib3
from f5utils.f5as3 import send_as3_declarations, is_as3_alive

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)
urllib3.disable_warnings()

autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')
sm = boto3.client('secretsmanager')
s3 = boto3.resource('s3')

# Getting username, password, and AS3 bucket name environment variables
USER_SECRET = os.environ['USER_SECRET_LOCATION']
PASS_SECRET = os.environ['PASS_SECRET_LOCATION']
AS3_BUCKET_NAME = os.environ['AS3_BUCKET_NAME']


def send_lifecycle_action(lifecycle_event, result):
    # Update lifecycle event with continue or abort
    try:
        response = autoscaling.complete_lifecycle_action(
            LifecycleHookName=lifecycle_event['LifecycleHookName'],
            AutoScalingGroupName=lifecycle_event['AutoScalingGroupName'],
            LifecycleActionToken=lifecycle_event['LifecycleActionToken'],
            LifecycleActionResult=result,
            InstanceId=lifecycle_event['EC2InstanceId']
        )

        logger.info(response)
    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)

    return

def instance_launching(lifecycle_event):
    # Instance launching event cycle
    logger.info('EC2_INSTANCE_LAUNCHING event')
    try:
        # Grab EC2 Instance info
        ec2_instance_id = lifecycle_event['EC2InstanceId']
        instance_info = ec2.describe_instances(
            InstanceIds=[ec2_instance_id])
        instance_public_ip = instance_info['Reservations'][0]['Instances'][0]['PublicIpAddress']
        logger.info('EC2 Instance info: {}'.format(instance_info))

        # Grab username and password from secrets manager
        username = sm.get_secret_value(
            SecretId=USER_SECRET)['SecretString']
        password = sm.get_secret_value(
            SecretId=PASS_SECRET)['SecretString']

        # Is AS3 Available?
        if is_as3_alive(instance_public_ip, username, password, 60):
            logger.info('AS3 successfully requested.')
            # Send AS3 declaration(s) to BIG-IP
            send_as3_declarations(instance_public_ip,
                                  username, password, AS3_BUCKET_NAME)
            # AS3 Declaration was successful. Tell autoscaling group to continue on lifecycle hook.
            send_lifecycle_action(lifecycle_event, 'CONTINUE')
        else:
            # AS3 is unreachable. Fail
            message = 'AS3 appears to be unreachable...'
            logger.error(message)
            raise Exception(message)

    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)


def instance_terminating(lifecycle_event):
    logger.info('EC2_INSTANCE_TERMINATING event')
    send_lifecycle_action(lifecycle_event, 'CONTINUE')


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
