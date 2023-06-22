resource "aws_dynamodb_table" "Data_Ingestion_audit_tf" {
  name         = "data-ingestion-audit-tf"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"
  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
}

