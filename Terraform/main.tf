
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
  input = jsonencode({
    "data_set" : "saketh_movielens",
    "type" : "file_ingestion",
    "schedule" : "cron(0 20 * * ? *)",
    "source_bucket" : "saketh-indv-movielens-source-dataset",
    "source_folder" : "movielens",
    "target_bucket" : "saketh-indv-movielens-raw-dataset",
    "pipeline" : [
      {
        "data_asset" : "genome_scores",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "DAY",
          "file_pattern" : "genome_scores",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      },
      {
        "data_asset" : "genome_tags",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "YEAR",
          "file_pattern" : "genome_tags",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      },
      {
        "data_asset" : "movie_links",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "DAY",
          "file_pattern" : "links",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      },
      {
        "data_asset" : "movies",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "MONTH",
          "file_pattern" : "movie",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      },
      {
        "data_asset" : "movie_rating",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "MONTH",
          "file_pattern" : "rating",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      },
      {
        "data_asset" : "movie_tags",
        "raw" : {
          "source_bucket" : "saketh-indv-movielens-source-dataset",
          "source_folder" : "movielens",
          "target_bucket" : "saketh-indv-movielens-raw-dataset",
          "partition" : "MONTH",
          "file_pattern" : "tags",
          "file_type" : "csv"
        },
        "staging" : {},
        "publish" : {}
      }
    ]
  })
}


resource "aws_sns_topic" "movielens_topic" {
  name = "saketh-movielens-topic"
}

resource "aws_sns_topic_subscription" "movielens_subscription" {
  topic_arn = aws_sns_topic.movielens_topic.arn
  protocol  = "email-json"
  endpoint  = var.email_id

}

