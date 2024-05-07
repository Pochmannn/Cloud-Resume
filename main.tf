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
#adding item to the tablegit 
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

