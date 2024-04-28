import boto3
import json

# define the DynamoDB table that Lambda will connect to
tableName = "VisitorsCount"

# create the DynamoDB resource
dynamo = boto3.resource('dynamodb').Table(tableName)

print('Loading function')

def lambda_handler(event, context):
    dynamo.update_item(
        Key={
            'id' : 'A1'
        },
        UpdateExpression='SET visitorCount = visitorCount + :val1',
        ExpressionAttributeValues={
            ':val1': 1
        },
    )
    response = dynamo.get_item(
        Key={
            'id' : 'A1'
        }
    )
    item = response['Item']
    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': item
    }