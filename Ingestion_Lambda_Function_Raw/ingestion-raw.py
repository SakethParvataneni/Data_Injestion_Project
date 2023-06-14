import json
import boto3
import os 
import logging 
from datetime import datetime


current_date = datetime.now() 
year = current_date.year
month = current_date.month
day = current_date.day
s3 = boto3.resource('s3')
s3_client = boto3.client('s3')

logging.basicConfig(
    level=logging.INFO,
    format=f"%(asctime)s  %(lineno)d    %(levelname)s   %(message)s",
)

log = logging.getLogger("Saketh-Ingest-Raw")

log.info("")
def send_notification(message,subject):
    sns_topic_arn = 'arn:aws:sns:us-east-2:746694705576:data-ingestion-sns-tf:b24ff35d-3990-4556-b074-4e2d8dd3225c' 
    response = sns_client.publish(
        TopicArn = sns_topic_arn,
        Message = message,
        Subject = subject
    )

def lambda_handler(event, context):  
    dynamic_key = event.get('key')
    bucket = os.environ['dynamic_bucket']
    response = s3_client.get_object(Bucket=bucket, Key=f'{dynamic_key}/config.json')
    config_data = response.get('Body').read().decode('utf-8')
    config_json = json.loads(config_data)
    source_bucket = config_json.get('source_bucket')
    source_folder = config_json.get('source_folder')
    target_bucket = config_json.get('target_bucket')
    log.info(source_bucket)
    try:
        dataset=event.get("data_set") 
        response = s3_client.get_object(Bucket=code_bucket, Key=f"{dataset}/source-config/config.json")
        log.info(response)
        send_notification("Bucket and config file are executed succefully","Movielens_data_Ingestion_tf succeded" )
    except Exception as e:
        log.exception(f"Error occurred in response {e}")
        send_notification(f"Error '{e}' ocuured in evironment varaiable or the source file","Movielens_data_Ingestion_tf failed")
    
    response = s3_client.list_objects_v2(Bucket=source_bucket, Prefix=source_folder)
    log.info(response)
    try:
        config_data = response.get('Body').read().decode('utf-8')
        config_json = json.loads(config_data)
        source_bucket = config_json.get('source_bucket')
        source_folder = config_json.get('source_folder')
        target_bucket = config_json.get('target_bucket')
        log.info(source_bucket)
        send_notification("Buckets are read successfully","Movielens_data_Ingestion_tf succeed")
    except Exception as e:
        log.exception(f"Error occurred in loading buckets {e}")
        send_notification(f"Error '{e}' occurred while loading buckets","Movielens_data_Ingestion_tf failed")
        
    try:   
        response = s3_client.list_objects_v2(Bucket=source_bucket)
        log.info(response)
        send_notification("Reading objects in source bucket","Movielens_data_Ingestion_tf succeeded")
    except Exception as e:
        log.exception(f"Error occrred in response {e}")
        send_notification(f"Error '{e}' occurred in response","Movielens_data_Ingestion_tf failed")
    file_list = []
 
    for obj in response['Contents']:
        file_name = obj['Key']
        file_name = file_name.replace(source_folder + '/', '')
        file_list.append(file_name)
    log.info(file_list[1:])
    try:
            file_name = obj['Key']
            file_name = file_name.replace(source_folder + '/', '')
            file_list.append(file_name)
            log.info(file_list)
            send_notification("files in list are executed successfully","Movielens_data_Ingestion_tf succeeded")
    except Exception as e:
            log.exception(f"Error ocurred in file list {e}","Movielens_data_Ingestion_tf succeeded")
            send_notification(f"Error '{e}' ocurred in reading file list","Movielens-data-Ingestion_tf failed")

    for i in file_list[1:]:
        try:
            file_part = file.split('.')[0]
            file_extension = file.split('.')[-1]
            log.info(file_part)
            otherkey = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{file_extension}"
            log.info(otherkey)
            copy_source = {
            'Bucket': source_bucket,
            'Key': f"{source_folder}/{file}"
                 
    }
            bucket = s3.Bucket(target_bucket)
            log.info(bucket)
            bucket.copy(copy_source,otherkey)
            send_notification("files are successfully copied","Movielens_data_Ingestion_tf succeeded")
        except Exception as e:
            log.exception(f"Error ocurred while copying files {e}",)
            send_notification(f"Error '{e}' ocurred in copying files","Movielens_data_Ingestion_tf failed")
    return {
        'statusCode': 200,
        'body': json.dumps(output)
    }
