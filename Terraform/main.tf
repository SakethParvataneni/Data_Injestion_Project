
resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name        = "movielens-scheduled-rule"
  description = "Scheduled rule to trigger moviele ns Lambda function"

  schedule_expression = "cron(0 12 * * ? *)"

  tags = {
    Environment = "Production"
  }
}


resource "aws_lambda_invocation" "lambda_invoke" {
  function_name = "ingest-source-raw-data"
  input         = <<JSON
    {
      "data_set": "saketh_movielens",
       "key": "source_file"
    }
  JSON
}

resource "aws_sns_topic" "movielens_topic" {
  name = "saketh-movielens-topic"
}

resource "aws_sns_topic_subscription" "movielens_subscription" {
  topic_arn = aws_sns_topic.movielens_topic.arn
  protocol  = "email-json"
  endpoint  = var.email_id

}

