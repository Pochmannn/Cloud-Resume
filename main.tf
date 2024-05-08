terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
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
  hash_key       = "Id"
  range_key      = "visitorCount"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "visitorCount"
    type = "N"
  }

}
#adding item to the table
resource "aws_dynamodb_table_item" "basic-dynamodb-table" {
  table_name = aws_dynamodb_table.basic-dynamodb-table.name
  hash_key   = aws_dynamodb_table.basic-dynamodb-table.hash_key
  range_key  = aws_dynamodb_table.basic-dynamodb-table.range_key

  item = <<ITEM
{
  "Id": {
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

  # routing_rule {
  #   condition {
  #     key_prefix_equals = "docs/"
  #   }
  #   redirect {
  #     replace_key_prefix_with = "documents/"
  #   }
  # }
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


