import json
import boto3
import os
import logging
from datetime import datetime

current_date = datetime.now()
year = current_date.year
month = current_date.month
day = current_date.day
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
dynamodb_client = boto3.client('dynamodb')

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
log = logging.getLogger("Saketh-Ingest-Raw")
log.setLevel(logging.INFO)
def send_notification(message, subject):
    sns_topic_arn = 'arn:aws:sns:us-east-2:746694705576:data-pipeline-sns'

    response = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=message,
        Subject=subject
    )

def check_table_exists(table_name):
    try:
        response = dynamodb_client.describe_table(TableName=table_name)
        log.info(f"Table {table_name} exists")
    except dynamodb_client.exceptions.ResourceNotFoundException:
        send_notification("DynamoDB table not found", "DynamoDB table does not exist")
        raise
    except Exception as e:
        log.exception(f"Error occurred while checking table existence: {str(e)}")
        send_notification(f"Error occurred while checking table existence: {str(e)}", "Error in checking DynamoDB table")
        raise

def item_exists(table_name, pk, sk):
    try:
        response = dynamodb_client.get_item(
            TableName=table_name,
            Key={
                'PK': {'S': pk},
                'SK': {'S': sk}
            }
        )

        return 'Item' in response
    except Exception as e:
        log.exception(f"Error occurred while checking item existence: {str(e)}")
        send_notification(f"Error occurred while checking item existence: {str(e)}", "Error in checking DynamoDB item")
        raise

def process_step(step, dataset, source_bucket, source_folder, target_bucket):
    data_asset = step.get("data_asset")
    raw_config = step.get("raw")
    staging_config = step.get("staging")
    publish_config = step.get("publish")

    partition = raw_config.get("partition")
    file_pattern = raw_config.get("file_pattern").strip("/")

    response = s3_client.list_objects_v2(
        Bucket=source_bucket,
        Prefix=source_folder.rstrip("/")
    )
    file_list = [
        obj['Key']
        for obj in response.get('Contents', [])
        if obj['Key'].startswith(source_folder) and obj['Key'] != f"{source_folder}/"
    ]

    filtered_file_list = [file for file in file_list if file_pattern in file.split("/")[-1]]

    log.info(f"Files in source bucket: {filtered_file_list}")

    num_items_created = 0  # Track the number of items created

    for file in filtered_file_list:
        file_name = file.split('/')[-1]
        file_parts = file_name.split('.')
        
        if len(file_parts) != 2:
            log.warning(f"Invalid file name format: {file_name}. Skipping.")
            continue

        file_part, file_extension = file_parts

        otherkey = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{file_extension}"
        copy_source = {
            'Bucket': source_bucket,
            'Key': file
        }
        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=target_bucket,
            Key=otherkey
        )

        dynamodb_item = {
            'PK': {'S': dataset},
            'SK': {'S': f"{partition}_{file_part}"},
            'FileExtension': {'S': file_extension},
            'FilePath': {'S': otherkey},
            'Timestamp': {'S': str(current_date)}
        }

        if not item_exists('data-ingestion-audit-tf', dataset, f"{partition}_{file_part}"):
            dynamodb_client.put_item(
                TableName='data-ingestion-audit-tf',
                Item=dynamodb_item
            )
            log.info(f"File '{file}' successfully copied and DynamoDB item created")
            num_items_created += 1
        else:
            log.info(f"DynamoDB item for file '{file}' already exists, skipping creation")

    log.info(f"Number of items created: {num_items_created}")


    send_notification(f"Files for data asset '{data_asset}' are successfully processed", "Movielens_data_Ingestion_tf succeeded")

def lambda_handler(event, context):
    try:
        key = os.environ.get('dynamic_key')
        if not key:
            raise ValueError("Invalid or missing 'key' in the event.")

        bucket = os.environ.get('dynamic_bucket')
        if not bucket:
            raise ValueError("Missing 'dynamic_bucket' environment variable.")

        response = s3_client.get_object(Bucket=bucket, Key=key)
        config_data = response.get('Body').read().decode('utf-8')
        config_json = json.loads(config_data)
        source_bucket = config_json.get('source_bucket')
        source_folder = config_json.get('source_folder')
        target_bucket = config_json.get('target_bucket')
        log.info(f"Source bucket: {source_bucket}")
        log.info(f"Source folder: {source_folder}")
        log.info(f"Target bucket: {target_bucket}")
        dataset = event.get("data_set")
        if not dataset:
            raise ValueError("Invalid or missing 'data_set' in the event.")

        log.info(f"Dataset: {dataset}")

        pipeline = config_json.get("pipeline")
        for step in pipeline:
            process_step(step, dataset, source_bucket, source_folder, target_bucket)

        send_notification("Bucket and config file are executed successfully", "Movielens_data_Ingestion_tf succeeded")

        return {
            'statusCode': 200,
            'body': json.dumps({"message": "Data ingestion completed"})
        }
    except Exception as e:
        log.exception(f"Error occurred: {str(e)}")
        send_notification(f"Error '{str(e)}' occurred in the Lambda function", "Movielens_data_Ingestion_tf failed")
        return {
            'statusCode': 500,
            'body': json.dumps({"message": "Data ingestion failed"})
        }
