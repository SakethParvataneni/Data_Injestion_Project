
resource "aws_s3_bucket" "saketh-indv-movielens-source-dataset-tf-test" {
  bucket = "saketh-indv-movielens-source-dataset-tf-test"
  acl    = "private"
}

resource "aws_s3_bucket" "saketh-indv-movielens-raw-dataset-tf-test" {
  bucket = "saketh-indv-movielens-raw-dataset-tf-test"
  acl    = "private"
}
