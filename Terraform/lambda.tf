data "archive_file" "lambda" {
  type        = "zip"
  source_file = "C:/Projects/Data_Ingestion_Project/Ingestion_Lambda_Function_Raw/ingestion-raw.py"
  output_path = "C:/Projects/Data_Ingestion_Project/Ingestion_Lambda_Function_Raw/ingestion-raw.zip"
}

resource "aws_lambda_function" "lambda-src-raw" {
  filename      = data.archive_file.lambda.output_path
  function_name = "ingest-source-raw-data-tf"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "ingestion-raw.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.10"
  timeout = 900
  ephemeral_storage {
    size = 512 
  }
  environment {
    variables = {
      dynamic_bucket = "saketh-movielens-data-ingestion-code"
    }
  }
}

resource "aws_lambda_permission" "bucket1_lambda_permission" {
  statement_id  = "AllowExecutionFromsaketh-indv-movielens-source-dataset-tf-test"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-src-raw.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.saketh-indv-movielens-source-dataset-tf-test.arn
}

resource "aws_lambda_permission" "bucket2_lambda_permission" {
  statement_id  = "AllowExecutionFromsaketh-indv-movielens-raw-dataset-tf"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-src-raw.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.saketh-indv-movielens-raw-dataset-tf-test.arn
}
