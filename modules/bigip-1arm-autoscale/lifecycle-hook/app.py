import boto3
from botocore.exceptions import ClientError
import os
import json
import logging
import time
import urllib3
from f5utils.f5as3 import send_as3_declarations, is_as3_alive
from f5utils.f5license import revoke_bigip_license

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)
urllib3.disable_warnings()

autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')
sm = boto3.client('secretsmanager')
s3 = boto3.resource('s3')

# Getting username, password, and AS3 bucket name environment variables
BIGIP_USER_SECRET = os.environ['USER_SECRET_LOCATION']
BIGIP_PASS_SECRET = os.environ['PASS_SECRET_LOCATION']
AS3_BUCKET_NAME = os.environ['AS3_BUCKET_NAME']
LICENSE_TYPE = os.environ['LICENSE_TYPE']
BIGIQ_LICENSE_POOL_NAME = os.environ['BIGIQ_LICENSE_POOL_NAME']
BIGIQ_SERVER = os.environ['BIGIQ_SERVER']
BIGIQ_USER_SECRET_LOCATION = os.environ['BIGIQ_USER_SECRET_LOCATION']
BIGIQ_PASS_SECRET_LOCATION = os.environ['BIGIQ_PASS_SECRET_LOCATION']


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

        # Grab BIG-IP username and password from secrets manager
        bigip_username = sm.get_secret_value(
            SecretId=BIGIP_USER_SECRET)['SecretString']
        bigip_password = sm.get_secret_value(
            SecretId=BIGIP_PASS_SECRET)['SecretString']

        # Waiting for AS3 to become available to see if appliance is responsive.
        if is_as3_alive(instance_public_ip, bigip_username, bigip_password, 60):
            logger.info('AS3 successfully requested.')
            # Sleeping for two minutes to wait for the license process to finish. DO is slooooooow.
            if LICENSE_TYPE == 'BYOL' and lifecycle_event['Origin'] == 'AutoScalingGroup':
                time.sleep(180)
            # Send AS3 declaration(s) to BIG-IP
            send_as3_declarations(instance_public_ip,
                                  bigip_username, bigip_password, AS3_BUCKET_NAME)
            # AS3 Declaration was successful. Tell autoscaling group to continue on lifecycle hook.
            send_lifecycle_action(lifecycle_event, 'CONTINUE')
        else:
            # AS3 is unreachable. Fail
            send_lifecycle_action(lifecycle_event, 'ABANDON')
            message = 'AS3 appears to be unreachable...'
            logger.error(message)
            raise Exception(message)

    except ClientError as e:
        message = 'Error completing lifecycle action: {}'.format(e)
        logger.error(message)
        raise Exception(message)


def instance_terminating(lifecycle_event):
    # Instance terminating event cycle
    logger.info('EC2_INSTANCE_TERMINATING event')
    if LICENSE_TYPE == 'BYOL':
        try:
            # Grab EC2 Instance info
            ec2_instance_id = lifecycle_event['EC2InstanceId']
            instance_info = ec2.describe_instances(
                InstanceIds=[ec2_instance_id])
            logger.info('EC2 Instance info: {}'.format(instance_info))

            # Grab BIG-IP and BIG-IQ username and password from secrets manager
            bigiq_username = sm.get_secret_value(
                SecretId=BIGIQ_USER_SECRET_LOCATION)['SecretString']
            bigiq_password = sm.get_secret_value(
                SecretId=BIGIQ_PASS_SECRET_LOCATION)['SecretString']

            revoke_bigip_license(BIGIQ_SERVER, bigiq_username, bigiq_password,
                                 BIGIQ_LICENSE_POOL_NAME, ec2_instance_id)
        except ClientError as e:
            message = 'Error completing lifecycle action: {}'.format(e)
            logger.error(message)
            raise Exception(message)

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
