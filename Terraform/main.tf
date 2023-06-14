
resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name        = "movielens-scheduled-rule"
  description = "Scheduled rule to trigger moviele ns Lambda function"

  schedule_expression = "cron(0 12 * * ? *)" 

  tags = {
    Environment = "Production"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  arn       = aws_sfn_state_machine.sfn_state_machine.arn
  role_arn  = aws_iam_role.my_state_machine_role.arn
  target_id = aws_sfn_state_machine.my_state_machine.name
}

resource "aws_lambda_invocation" "lambda_invoke" {
  function_name = "Movielens-data-Ingestion_tf"
  input         = <<JSON
    {
      "data_set": "saketh_movielens"
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

