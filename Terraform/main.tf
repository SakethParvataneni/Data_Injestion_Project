
resource "aws_s3_bucket" "saketh-indv-movielens-source-dataset-tf-test" {
  bucket = "saketh-indv-movielens-source-dataset-tf-test"
  acl    = "private"
}

resource "aws_s3_bucket" "saketh-indv-movielens-raw-dataset-tf-test" {
  bucket = "saketh-indv-movielens-raw-dataset-tf-test"
  acl    = "private"
}

resource "aws_cloudwatch_event_rule" "my_event_rule" {
  name        = "my-event-rule"
  description = "Trigger Lambda function on specific events"
  event_pattern = <<EOF
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ]
}
EOF
}

# Create the EventBridge target to invoke the Lambda function
resource "aws_cloudwatch_event_target" "my_event_target" {
  rule      = aws_cloudwatch_event_rule.my_event_rule.name
  target_id = "my-event-target"
  arn       = aws_lambda_function.lambda-src-raw.arn
}