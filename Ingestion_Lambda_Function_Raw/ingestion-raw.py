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
    format="%(asctime)s  %(lineno)d    %(levelname)s   %(message)s",
)

log = logging.getLogger("Saketh-Ingest-Raw")
log.info("")

def send_notification(message, subject):
    sns_topic_arn = 'arn:aws:sns:us-east-2:746694705576:data-pipeline-sns'

    response = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=message,
        Subject=subject
    )

def lambda_handler(event, context):
    try:
        Key = os.environ.get('dynamic_key')
        if not Key:
            raise ValueError("Invalid or missing 'key' in the event.")

        bucket = os.environ.get('dynamic_bucket')
        if not bucket:
            raise ValueError("Missing 'dynamic_bucket' environment variable.")

        response = s3_client.get_object(Bucket=bucket, Key=Key)
        config_data = response.get('Body').read().decode('utf-8')
        config_json = json.loads(config_data)
        source_bucket = config_json.get('source_bucket')
        source_folder = config_json.get('source_folder')
        target_bucket = config_json.get('target_bucket')
        log.info(source_bucket)

        dataset = event.get("data_set")
        if not dataset:
            raise ValueError("Invalid or missing 'data_set' in the event.")

        response = s3_client.get_object(Bucket=bucket, Key=Key)
        log.info(response)
        send_notification("Bucket and config file are executed successfully", "Movielens_data_Ingestion_tf succeeded")

        response = s3_client.list_objects_v2(Bucket=source_bucket, Prefix=source_folder)
        log.info(response)
        send_notification("Buckets are read successfully", "Movielens_data_Ingestion_tf succeeded")

        file_list = []
        for obj in response.get('Contents', []):
            file_name = obj['Key']
            file_name = file_name.replace(source_folder + '/', '')
            file_list.append(file_name)

        log.info(file_list[1:])

        for file in file_list[1:]:
            file_part = file.split('.')[0]
            file_extension = file.split('.')[-1]
            log.info(file_part)
            otherkey = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{file_extension}"
            log.info(otherkey)
            copy_source = {
                'Bucket': source_bucket,
                'Key': f"{source_folder}/{file}"
            }
            s3_client.copy_object(
                CopySource=copy_source,
                Bucket=target_bucket,
                Key=otherkey
            )
            send_notification("Files are successfully copied", "Movielens_data_Ingestion_tf succeeded")

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
