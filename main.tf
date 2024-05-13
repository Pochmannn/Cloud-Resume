terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}
#creating dynamoDB VisitorsCount-tf table
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "VisitorsCount-tf"
  billing_mode = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "visitorCount"
    type = "N"
  }

  global_secondary_index {
    name            = "visitorCount"
    hash_key        = "visitorCount"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
}
#adding item to the table
resource "aws_dynamodb_table_item" "basic-dynamodb-table" {
  table_name = aws_dynamodb_table.basic-dynamodb-table.name
  hash_key   = aws_dynamodb_table.basic-dynamodb-table.hash_key
  range_key  = aws_dynamodb_table.basic-dynamodb-table.range_key

  item = <<ITEM
{
  "id": {
    "S": "A1"
  },
  "visitorCount": {
    "N": "1"
  }
}
ITEM
}

#making an S3 bucket
resource "aws_s3_bucket" "cloudresume-bucket-tf" {
  bucket  = "cloudresume-bucket-tf"
}

resource "aws_s3_bucket_public_access_block" "cloudresume-bucket-tf" {
  bucket = aws_s3_bucket.cloudresume-bucket-tf.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.cloudresume-bucket-tf.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.cloudresume-bucket-tf.arn,
      "${aws_s3_bucket.cloudresume-bucket-tf.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_website_configuration" "static-s3-website" {
  bucket = aws_s3_bucket.cloudresume-bucket-tf.id

  index_document {
    suffix = "index.html"
  }

}
#uploading files to S3 bucket
resource "aws_s3_object" "cloudresume-s3-upload-index" {
  bucket = "cloudresume-bucket-tf"
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"

  etag = filemd5("index.html")
}

resource "aws_s3_object" "cloudresume-s3-upload-style" {
  bucket = "cloudresume-bucket-tf"
  key    = "style.css"
  source = "style.css"

  etag = filemd5("style.css")
}


locals {
  s3_origin_id = "cloudresume-bucket-tf"
}

#cloudfront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.cloudresume-bucket-tf.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["RU", "CN" , "IL"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#Lambda role and policies
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda-apigateway-role-tf" {
  statement {
    effect    = "Allow"
    actions   = [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.lambda-apigateway-role-tf.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy.arn
}

#Lambda
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "LambdaFunctionOverHttps.py"
  output_path = "LambdaFunctionOverHttps.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "LambdaFunctionOverHttps.zip"
  function_name = "LambdaFunctionOverHttps-tf"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "LambdaFunctionOverHttps.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      databaseName = "VisitorsCount-tf"
    }
  }
}

#API Gateway
resource "aws_apigatewayv2_api" "VisitorsCount-Api-tf" {
  name          = "VisitorsCount-Api-tf"
  protocol_type = "HTTP"

  cors_configuration {
      allow_credentials = false
      allow_headers     = []
      allow_methods     = [
          "GET",
          "OPTIONS",
          "POST",
      ]
      allow_origins     = [
          "*",
      ]
      expose_headers    = []
      max_age           = 0
  }
}
#Lambda integration
resource "aws_apigatewayv2_integration" "test_lambda" {
  api_id           = aws_apigatewayv2_api.VisitorsCount-Api-tf.id
  integration_uri = aws_lambda_function.test_lambda.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"

}
#stage
resource "aws_apigatewayv2_stage" "example" {
  api_id = aws_apigatewayv2_api.VisitorsCount-Api-tf.id
  name   = "example-stage"
  auto_deploy = true
}

#lambda permission
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_lambda.arn}"
  principal     = "apigateway.amazonaws.com"


  source_arn    = "${aws_apigatewayv2_api.VisitorsCount-Api-tf.execution_arn}/*/*/*"
}

#route
resource "aws_apigatewayv2_route" "route-tf" {
  api_id    = aws_apigatewayv2_api.VisitorsCount-Api-tf.id
  route_key = "ANY /example"

  target = "integrations/${aws_apigatewayv2_integration.test_lambda.id}"
}