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

def lambda_handler(event, context):

    logger.info(event['Records'])
    logger.info(event['Records'][0]['Sns']['Message'])

