import pytest
import boto3
from LambdaFunctionOverHttps import lambda_handler

def test_lambda_handler():
    # Event and Context are not used in this example
    event = {}
    context = {}

    # Invoke the Lambda function
    response = lambda_handler(event, context)

    # Check if the S3 object was created successfully
    assert response["isBase64Encoded"] == "false"
    assert response["statusCode"] == 200
    assert response["headers"]["Access-Control-Allow-Origin"] == "*"
    assert response["body"]["id"] == "A1"

    #to run test use: pytest -v -s LambdaFunctionOverHttpsTest.py
