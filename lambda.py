import json
from pprint import pprint
import boto3
import random
import os

my_table = os.environ.get('MY_TABLE')

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(my_table)
    response = table.scan()
    return {
        'statusCode': 200,
        'body': json.dumps(random.choice(response['Items']))
    }
    