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
ec2 = boto3.client('ssm')


def send_lifecycle_action(lifecycle_event, result):
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


def instance_launching(lifecycle_event):
    logger.info('EC2_INSTANCE_LAUNCHING event')
    ec2_instance_id = lifecycle_event['EC2InstanceId']
    logger.info(ec2.describe_instances(InstanceIds=[{ec2_instance_id}]))


def instance_terminating(lifecycle_event):
    logger.info('EC2_INSTANCE_TERMINATING event')


def lambda_handler(event, context):
    logger.info('Trigger Record: {}'.format(event['Records']))
    lifecycle_event = event['Records'][0]['Sns']['Message']

    # Verify Lifecycle Transition is present
    if 'LifecycleTransition' not in lifecycle_event:
        logger.info(
            'LifecycleTransition missing from SNS message. Likely a test notification.')
        return

    # Identifying Lifecycle hook type
    if lifecycle_event['LifecycleTransition'] == "autoscaling:EC2_INSTANCE_LAUNCHING":
        instance_launching(lifecycle_event)
    elif lifecycle_event['LifecycleTransition'] == "autoscaling:EC2_INSTANCE_TERMINATING":
        instance_terminating(lifecycle_event)
    else:
        logger.info('Unknown LifecycleTransition state. Exiting...')
        return
