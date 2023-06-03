import json
import boto3
import os 
from datetime import datetime


current_date = datetime.now() 
year = current_date.year
month = current_date.month
day = current_date.day
s3 = boto3.resource('s3')
s3_client = boto3.client('s3')

def lambda_handler(event, context):  
    dynamic_key = event.get('key')
    bucket = os.environ['dynamic_bucket']
    response = s3_client.get_object(Bucket=bucket, Key=f'{dynamic_key}/config.json')
    config_data = response.get('Body').read().decode('utf-8')
    config_json = json.loads(config_data)
    source_bucket = config_json.get('source_bucket')
    source_folder = config_json.get('source_folder')
    target_bucket = config_json.get('target_bucket')
    print(source_bucket)
 
    response = s3_client.list_objects_v2(Bucket=source_bucket, Prefix=source_folder)
    print(response)
 
    file_list = []
 
    for obj in response['Contents']:
        file_name = obj['Key']
        file_name = file_name.replace(source_folder + '/', '')
        file_list.append(file_name)
    print(file_list[1:])

    for i in file_list[1:]:
        file_part = i.split('.')[0]
        dynamic_file_extension = i.split('.')[1]
        print(file_part)
        output = f"{source_folder}/{file_part}/year={year}/month={month}/day={day}/{file_part}_{current_date}.{dynamic_file_extension}"

        print(output)
        desired_output = {
            'Bucket': source_bucket,
            'Key': f"{source_folder}/{i}",
        }
        print(desired_output)
        bucket = s3.Bucket(target_bucket)
        bucket.copy(desired_output, output)
    return {
        'statusCode': 200,
        'body': json.dumps('output')
    }
