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

data "aws_iam_policy_document" "cloud_watch_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:us-east-2:746694705576:*",
      "arn:aws:logs:us-east-2:746694705576:log-group:/aws/lambda/ingest-source-raw-data:*",
    ]
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
      "s3-object-lambda:*",
    ]

    resources = ["*"]
  }
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "cloud_watch_policy" {
  name   = "cloud_watch_policy"
  policy = data.aws_iam_policy_document.cloud_watch_policy.json
}

resource "aws_iam_policy" "s3_policy" {
  name   = "s3_policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy_attachment" "cloud_watch_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.cloud_watch_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_sns_topic" "data_ingestion_sns_tf" {
  name = "data-ingestion-sns-tf"
}

resource "aws_sns_topic_subscription" "email_tf_subscription" {
  topic_arn = aws_sns_topic.data_ingestion_sns_tf.arn
  protocol  = "email-json"
  endpoint  = "sakethparvataneni@gmail.com"
}

resource "aws_iam_role" "state_machine_role_tf" {
  name = "my_state_machine_role_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "state_machine_role_policy_attachment" {
  role       = aws_iam_role.state_machine_role_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_role" "lambda_role" {
  name = "my_lambda_role_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "my_event_rule"
  description         = "EventBridge scheduler rule"
  schedule_expression = "rate(1 day)"
}

resource "aws_sfn_state_machine" "state_machine" {
  name       = "my_state_machine"
  role_arn   = aws_iam_role.state_machine_role_tf.arn
  definition = <<EOF
{
  "Comment": "An example of invoking an AWS Lambda function using the Amazon States Language",
  "StartAt": "InvokeLambda",
  "States": {
    "InvokeLambda": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-2:746694705576:function:${aws_lambda_invocation.lambda_invoke.function_name}",
      "Parameters": {
        "Payload.$": "$.input"
      },
      "End": true
    }
  }
}
EOF
}


resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  arn       = aws_sfn_state_machine.state_machine.arn
  target_id = "invoke_state_machine"
  role_arn  = aws_iam_role.state_machine_role_tf.arn

  depends_on = [aws_sfn_state_machine.state_machine, aws_lambda_function.lambda-src-raw]
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda-dynamodb-policy"
  description = "Allow DynamoDB access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "arn:aws:dynamodb:us-east-2:746694705576:table/${aws_dynamodb_table.Data_Ingestion_audit_tf.name}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_dynamodb_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}


