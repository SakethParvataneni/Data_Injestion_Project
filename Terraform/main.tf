


resource "aws_cloudwatch_event_rule" "saketh-event-bridge-tf" {
  name        = "saketh-event-bridge-tf"
  description = "Trigger Lambda function"
  event_pattern = <<EOF
{
  "source": [
    "aws.lambda"
  ],
  "detail-type": [
    "Lambda function State-change Notification"
  ]
}
EOF
}

# Create the EventBridge target to invoke the Lambda function
resource "aws_cloudwatch_event_target" "my_event_target" {
  rule      = aws_cloudwatch_event_rule.saketh-event-bridge-tf.name
  target_id = "my-event-target"
  arn       = aws_lambda_function.lambda-src-raw.arn

}

resource "aws_cloudwatch_event_rule" "event-bridge-tf" {
  name        = "event-bridge-tf"
  # description = "Example Event Rule"

  schedule_expression = "cron(0 12 * * ? *)"
}
