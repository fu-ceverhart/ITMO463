import json
import boto3
import os
from botocore.exceptions import ClientError
from botocore.config import Config
import logging
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
   
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
